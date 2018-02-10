from os import path

import yaml
from psychopy import visual, core, event

from .config import PKG_ROOT
from .landscape import create_stim_positions, SimpleHill

TEXT_KWARGS = dict(font='Consolas')
STARTING_POS = (10, 10)

class Experiment(object):
    response_keys = ['space']
    response_text = 'Press SPACEBAR to continue'
    search_radius = 8
    n_search_items = 9
    gabor_size = 60
    ITI = 1.0
    _win = None
    _mouse = None

    def __init__(self, **condition_vars):
        self.condition_vars = condition_vars
        self.pos = condition_vars.get('starting_pos', STARTING_POS)
        self.texts = yaml.load(open(path.join(PKG_ROOT, 'texts.yaml')))

        n_rows, n_cols = 3, 3
        assert n_rows * n_cols == self.n_search_items
        self.stim_positions = create_stim_positions(n_rows=3, n_cols=3,
            win_size=self.win.size, stim_size=self.gabor_size)

        self.landscape = SimpleHill()
        self.landscape.grating_stim_kwargs = dict(
            win=self.win,
            size=self.gabor_size
        )

        self.score = 0

    def run(self):
        self.show_training_instructions()
        self.run_training_trials()
        self.show_test_instructions()
        self.run_test_trials()
        self.show_end_of_experiment()
        self.quit()

    @property
    def win(self):
        if self._win is None:
            self._win = visual.Window(units='pix')
        return self._win

    @property
    def mouse(self):
        if self._mouse is None:
            self.win  # ensure window has been created
            self._mouse = event.Mouse()
        return self._mouse

    def show_training_instructions(self):
        welcome = self.make_text_stim('Welcome to the experiment!', pos=(0, 250),
                                      bold=True, height=30)

        trainer_instructions = self.texts[self.condition_vars['instructions_condition']]
        instructions = self.make_text_stim(self.texts['instructions'].format(
            trainer_instructions=trainer_instructions,
            response_text=self.response_text
        ))

        welcome.draw()
        instructions.draw()
        self.win.flip()
        event.waitKeys(keyList=['space'])

    def run_training_trials(self):
        pass

    def show_test_instructions(self):
        pass

    def run_test_trials(self):
        pass

    def show_end_of_experiment(self):
        end = self.make_text_stim('You have completed the experiment!', pos=(0, 250),
                                  bold=True, height=30)
        instructions = self.make_text_stim(self.texts['end'])

        end.draw()
        instructions.draw()
        self.win.flip()
        event.waitKeys(keyList=self.response_keys)

    def quit(self):
        core.quit()

    def make_text_stim(self, text, **custom_kwargs):
        kwargs = TEXT_KWARGS.copy()
        kwargs.update(custom_kwargs)
        return visual.TextStim(self.win, text=text, **kwargs)

    def run_trial(self):
        gabors = self.landscape.sample_gabors(
            self.pos,
            self.search_radius,
            self.n_search_items
        )

        trial_data = dict(
            pos=pos_to_str(self.pos),
            search_radius=self.search_radius,
            n_search_items=self.n_search_items,
            options=pos_list_to_str(gabors.keys()),
            positions=pos_list_to_str(self.stim_positions),
            score=self.score
        )

        for pos, grid_pos in zip(self.stim_positions, gabors.keys()):
            gabor = gabors[grid_pos]
            gabor.pos = pos
            gabor.draw()

        self.win.flip()
        self.mouse.clickReset()

        is_clicked = False
        while not is_clicked:
            (left, _, _), (time, _, _) = self.mouse.getPressed(getTime=True)
            if left:
                pos = self.mouse.getPos()
                for grid_pos, gabor in gabors.items():
                    if gabor.contains(pos):
                        is_clicked = True
                        trial_data['selected'] = pos_to_str(grid_pos)

                        score = self.landscape.get_score(grid_pos)
                        trial_data['delta'] = score
                        self.score += score
                        trial_data['score'] = self.score
                        break

            keys = event.getKeys(keyList=['q'])
            if len(keys) > 0:
                key = keys[0]
                core.quit()

            core.wait(0.05)

        feedback_pos = (gabor.pos[0], gabor.pos[1]+(self.gabor_size/2))
        feedback = visual.TextStim(self.win, text='+'+str(score), pos=feedback_pos, height=24, color='green', bold=True, font='Consolas', alignVert='bottom')

        for gabor in gabors.values():
            gabor.draw()

        feedback.draw()
        self.win.flip()
        core.wait(self.ITI)

        return trial_data



class ExperimentQuitException(Exception):
    pass


def pos_to_str(pos):
    x, y = pos
    return '{x},{y}'.format(x=x, y=y)

def pos_list_to_str(pos_list):
    return ';'.join([pos_to_str(pos) for pos in pos_list])
