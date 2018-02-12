from psychopy import visual, gui, core

from .experiment import Experiment
from .util import get_subj_info

def check_exists(subj_info):
    subj_path = path.join('data', '%s.txt' % (subj_info['subj_id']))
    return path.exists(subj_path)


def run(**condition_vars):
    """Run an experiment given a dict of condition vars."""
    subj_info = get_subj_info('gui.yaml', check_exists, save_order=True)
    experiment = Experiment(**subj_info)
    experiment.run()
