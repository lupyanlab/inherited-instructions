import subprocess
from itertools import product
from numpy import linspace

from invoke import task

from goldminers import Experiment, Landscape, SimpleHill, create_stim_positions
from goldminers.score_funcs import simple_hill


@task
def show_instructions(ctx, instructions_condition='orientation'):
    """Show the instructions for the experiment."""
    experiment = Experiment(instructions_condition=instructions_condition)
    experiment.show_welcome_page()
    experiment.show_training_instructions()
    experiment.quit()

@task
def run_trial(ctx):
    """Run a single trial."""
    experiment = Experiment()
    trial_data = experiment.run_trial()
    print(trial_data)
    experiment.quit()


@task
def run_training_trial(ctx):
    """Run a training trial."""
    experiment = Experiment()
    experiment.run_trial(feedback=True)
    experiment.quit()


@task
def print_landscape(ctx):
    """Print the landscape to a tidy csv."""
    landscape = Landscape(n_rows=100, n_cols=100, score_func=simple_hill)
    landscape.export('simple_hill.csv')


@task
def draw_gabors(ctx, grid_size=10, win_size=None, output='landscape.png',
                open_after=False):
    """Draw gabors sampled from the landscape.

    Examples:
    $ inv draw-gabors -w 800 -p
    """
    from psychopy import visual

    if win_size is None:
        fullscr = True
        size = (1, 1)  # Ignored when full screen
    else:
        fullscr = False
        size = map(int, win_size.split(','))
        if len(size) == 1:
            size = (size, size)

    win = visual.Window(size=size, units='pix', color=(0.6, 0.6, 0.6),
                        fullscr=fullscr)

    positions = linspace(0, 100, grid_size, endpoint=False, dtype='int')
    grid_positions = list(product(positions, positions))

    gabor_size = 60

    landscape = SimpleHill()
    landscape.grating_stim_kwargs = {'win': win, 'size': gabor_size}

    # Get gabors for each point in the grid
    positions = linspace(0, 100, grid_size, endpoint=False, dtype='int')
    grid_positions = list(product(positions, positions))
    gabors = landscape.get_gabors(grid_positions)

    stim_positions = create_stim_positions(n_rows=grid_size, n_cols=grid_size,
                                           win_size=win.size,
                                           stim_size=gabor_size)

    for (grid_pos, stim_pos) in zip(grid_positions, stim_positions):
        gabor = gabors[grid_pos]
        gabor.pos = stim_pos
        gabor.draw()

        label = visual.TextStim(win, '%s' % (grid_pos, ), pos=(stim_pos[0], stim_pos[1]+gabor_size/2), alignVert='bottom')
        label.draw()

    win.flip()
    win.getMovieFrame()
    win.saveMovieFrames(output)
    win.close()

    if open_after:
        subprocess.call(['open', output])


@task
def draw_landscape(ctx, landscape_data='simple_hill.csv',
                   output='simple_hill.pdf'):
    """Draw the landscape as a 3D plot."""
    R_command = 'Rscript draw_landscape.R {landscape_data} {output}'
    ctx.run(R_command.format(landscape_data=landscape_data, output=output),
            echo=True)
