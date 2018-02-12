from os import path

import yaml
from psychopy import visual, core, event

from .config import PKG_ROOT
from .landscape import SimpleHill
from .display import create_stim_positions


class Experiment(object):
    response_keys = ['space']
    response_text = 'Press SPACEBAR to continue'
    text_kwargs = dict(font='Consolas', color='black')

    # Duration of scoring feedback given on test trials.
    feedback_duration = 1.5

    _win = None
    win_size = None
    win_color = (.6, .6, .6)
    gabor_size = 60
    n_search_items = 9

    search_radius = 8
    starting_pos = (10, 10)

    _mouse = None

    def __init__(self, **condition_vars):
        self.condition_vars = condition_vars
        self.pos = condition_vars.get('starting_pos', self.starting_pos)
        self.texts = yaml.load(open(path.join(PKG_ROOT, 'texts.yaml')))

        n_rows, n_cols = 3, 3
        assert n_rows * n_cols == self.n_search_items
        self.stim_positions = create_stim_positions(n_rows=3, n_cols=3,
            win_size=(self.win.size[1], self.win.size[1]), stim_size=(self.gabor_size * 4))

        self.landscape = SimpleHill()
        self.landscape.grating_stim_kwargs = dict(
            win=self.win,
            size=self.gabor_size
        )

        self.score = 0

        self.trial_header = self.make_text_stim('',
            pos=(0, self.win.size[1]/2 - 10),
            alignVert='top',
            height=30,
            bold=True
        )

        self.score_text = self.make_text_stim('',
            pos=(-self.win.size[0]/2 + 10, self.win.size[1]/2 - 10),
            alignVert='top',
            alignHoriz='left',
            height=30,
            bold=True
        )

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
            if self.win_size is None:
                fullscr = True
                self.win_size = (1, 1)
            else:
                fullscr = False
            self._win = visual.Window(self.win_size, fullscr=fullscr, units='pix',
                                      color=self.win_color)

            self.text_kwargs['wrapWidth'] = self._win.size[0] * 0.7
        return self._win

    @property
    def mouse(self):
        if self._mouse is None:
            self.win  # ensure window has been created
            self._mouse = event.Mouse()
        return self._mouse

    def show_welcome_page(self):
        welcome = self.make_text_stim(self.texts['welcome'], pos=(0, 200),
                                      bold=True, height=30)

        instructions_text = self.texts['instructions'].format(
            response_text=self.response_text
        )
        instructions = self.make_text_stim(instructions_text)

        explorer_png = path.join(PKG_ROOT, 'img', 'explorer.png')
        explorer = visual.ImageStim(self.win, explorer_png, pos=(0, -200), size=200)

        left_gabor = self.landscape.get_grating_stim((10, 10))
        left_gabor.pos = (-100, -200)
        left_gabor.draw()

        right_gabor = self.landscape.get_grating_stim((20, 20))
        right_gabor.pos = (100, -200)
        right_gabor.draw()

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
        instructions_text = self.texts['training'].format(
            training_instructions=training_instructions,
        )
        instructions = self.make_text_stim(instructions_text)

        left_gabor = self.landscape.get_grating_stim((10, 10))
        left_gabor.pos = (-100, -200)
        left_gabor.draw()

        right_gabor = self.landscape.get_grating_stim((20, 20))
        right_gabor.pos = (100, -200)
        right_gabor.draw()

        title.draw()
        instructions.draw()
        self.win.flip()

        while True:
            (left, _, _) = self.mouse.getPressed()
            if left:
                pos = self.mouse.getPos()
                if right_gabor.contains(pos):
                    break

            core.wait(0.05)

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

    def run_trial(self, training=False):
        self.draw_score()

        self.trial_header.text = 'Click on the gem you think is most valuable.'
        self.trial_header.draw()

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
        self.pos = grid_pos      # update current pos
        prev_score = self.score
        self.score += score      # update current score

        trial_data['selected'] = pos_to_str(grid_pos)
        trial_data['rt'] = time * 1000
        trial_data['delta'] = score
        trial_data['score'] = self.score

        for gabor in gabors.values():
            gabor.draw()

        selected_label = self.label_gabor_score(score, gabor_pos, color='green', bold=True)
        selected_label.draw()

        self.draw_score(prev_score, score)

        if training:
            # Draw gabors again, this time with scores overlayed
            self.trial_header.text = 'Compare the score for the gem you selected to the scores of other gems. Click anywhere to continue.'

            for other_grid_pos, gabor in gabors.items():
                if grid_pos == other_grid_pos:
                    continue
                other_score = self.landscape.get_score(other_grid_pos)
                other_label = self.label_gabor_score(other_score, gabor.pos)
                if other_score > score:
                    other_label.color = 'red'
                other_label.draw()

            self.win.flip()

            while True:
                (left, _, _) = self.mouse.getPressed()
                if left:
                    break

        else:
            self.win.flip()
            core.wait(self.feedback_duration)

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
        feedback = self.make_text_stim('+'+str(score), pos=feedback_pos, height=24, alignVert='bottom', **kwargs)
        return feedback

    def draw_score(self, prev_score=None, delta=None):
        if prev_score is not None and delta:
            self.score_text.text = 'Your score:\n%s\n+%s\n----------\n%s' % (prev_score, delta, self.score)
        else:
            self.score_text.text = 'Your score:\n%s' % (self.score)
        self.score_text.draw()

class ExperimentQuitException(Exception):
    pass


def pos_to_str(pos):
    x, y = pos
    return '{x},{y}'.format(x=x, y=y)

def pos_list_to_str(pos_list):
    return ';'.join([pos_to_str(pos) for pos in pos_list])
