from os import path

import yaml
from psychopy import visual, core, event

from .config import PKG_ROOT
from .landscape import create_stim_positions, SimpleHill


class Experiment(object):
    response_keys = ['space']
    response_text = 'Press SPACEBAR to continue'
    text_kwargs = dict(font='Consolas')

    # Duration of scoring feedback given on test trials.
    feedback_duration = 1.0

    gabor_size = 60
    n_search_items = 9

    search_radius = 8
    starting_pos = (10, 10)

    _win = None
    _mouse = None

    def __init__(self, **condition_vars):
        self.condition_vars = condition_vars
        self.pos = condition_vars.get('starting_pos', self.starting_pos)
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
        self.show_welcome_page()
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

    def show_welcome_page(self):
        welcome = self.make_text_stim(self.texts['welcome'], pos=(0, 225),
                                      bold=True, height=30)
        instructions = self.make_text_stim(self.texts['instructions'].format(
            response_text=self.response_text
        ))

        explorer_png = path.join(PKG_ROOT, 'img', 'explorer.png')
        explorer = visual.ImageStim(self.win, explorer_png, pos=(0, -300), size=200)

        welcome.draw()
        instructions.draw()
        explorer.draw()
        self.win.flip()

        event.waitKeys(keyList=['space'])

    def show_training_instructions(self):
        title = self.make_text_stim(self.texts['training_title'], pos=(0, 250),
                                    bold=True, height=30)

        instructions_condition = self.condition_vars['instructions_condition']
        training_instructions = self.texts['training_instructions'][instructions_condition]

        instructions_text_stim = self.make_text_stim(training_instructions)

        title.draw()
        instructions_text_stim.draw()
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
        kwargs = self.text_kwargs.copy()
        kwargs.update(custom_kwargs)
        return visual.TextStim(self.win, text=text, **kwargs)

    def run_trial(self, feedback=False):
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
        grid_pos, gabor_pos, time = self.get_mouse_click(gabors)
        score = self.landscape.get_score(grid_pos)
        self.score += score

        trial_data['selected'] = pos_to_str(grid_pos)
        trial_data['rt'] = time * 1000
        trial_data['delta'] = score
        trial_data['score'] = self.score

        # Draw gabors again, this time with scores overlayed
        for gabor in gabors.values():
            gabor.draw()

        selected_label = self.label_gabor_score(score, gabor_pos, color='green', bold=True)
        selected_label.draw()

        if feedback:
            for other_grid_pos, gabor in gabors.items():
                if grid_pos == other_grid_pos:
                    continue
                self.label_gabor_score(self.landscape.get_score(grid_pos), gabor.pos).draw()

            self.win.flip()

            while True:
                (left, _, _) = self.mouse.getPressed()
                if left:
                    break

        else:
            self.win.flip()
            core.wait(self.ITI)

        return trial_data

    def get_mouse_click(self, gabors):
        self.mouse.clickReset()
        while True:
            (left, _, _), (time, _, _) = self.mouse.getPressed(getTime=True)
            if left:
                pos = self.mouse.getPos()
                for grid_pos, gabor in gabors.items():
                    if gabor.contains(pos):
                        return grid_pos, gabor.pos, time

            keys = event.getKeys(keyList=['q'])
            if len(keys) > 0:
                key = keys[0]
                core.quit()

            core.wait(0.05)

    def label_gabor_score(self, score, gabor_pos, **kwargs):
        feedback_pos = (gabor_pos[0], gabor_pos[1]+(self.gabor_size/2))
        feedback = visual.TextStim(self.win, text='+'+str(score), pos=feedback_pos, height=24, font='Consolas', alignVert='bottom', **kwargs)
        return feedback


class ExperimentQuitException(Exception):
    pass


def pos_to_str(pos):
    x, y = pos
    return '{x},{y}'.format(x=x, y=y)

def pos_list_to_str(pos_list):
    return ';'.join([pos_to_str(pos) for pos in pos_list])
