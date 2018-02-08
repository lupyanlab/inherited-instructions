from psychopy import visual, gui, core

from .experiment import Experiment

def parse_condition_vars(condition_vars):
    # Search for any missing vars
    for value in condition_vars.values():
        if not value:
            dlg = gui.DlgFromDict(condition_vars, title='Miners Experiment')
            if dlg.OK:
                break
            else:
                core.quit()

    return condition_vars

def run(**condition_vars):
    """Run an experiment given a dict of condition vars."""
    condition_vars = parse_condition_vars(condition_vars)
    experiment = Experiment(**condition_vars)

    experiment.show_training_instructions()
    experiment.run_training_trials()
    experiment.show_test_instructions()
    experiment.run_test_trials()
    experiment.show_end_of_experiment()
    experiment.quit()
