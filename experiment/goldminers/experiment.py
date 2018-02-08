from os import path

import yaml
from psychopy import visual, core, event

from .config import PKG_ROOT

TEXT_KWARGS = dict(font='Consolas')

class Experiment:
    response_keys = ['space']
    response_text = 'Press SPACEBAR to continue'
    _window = None

    def __init__(self, **condition_vars):
        self.condition_vars = condition_vars
        self.texts = yaml.load(open(path.join(PKG_ROOT, 'texts.yaml')))

    @property
    def window(self):
        if self._window is None:
            self._window = visual.Window(units='pix')
        return self._window

    def show_training_instructions(self):
        welcome = self.make_text_stim('Welcome to the experiment!', pos=(0, 250),
                                      bold=True, height=30)

        instructions = self.make_text_stim(
            self.texts['instructions'].format(
                trainer_instructions=self.texts[self.condition_vars['instructions_condition']],
                response_text=self.response_text
            )
        )

        welcome.draw()
        instructions.draw()
        self.window.flip()
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
        self.window.flip()
        event.waitKeys(keyList=self.response_keys)

    def quit(self):
        core.quit()

    def make_text_stim(self, text, **custom_kwargs):
        kwargs = TEXT_KWARGS.copy()
        kwargs.update(custom_kwargs)
        return visual.TextStim(self.window, text=text, **kwargs)


class ExperimentQuitException(Exception):
    pass
