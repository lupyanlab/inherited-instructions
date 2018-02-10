import subprocess

from invoke import task

from goldminers import Experiment, Landscape
from goldminers.score_funcs import simple_hill


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
    experiment.run_training_trial()
    experiment.quit()


@task
def print_landscape(ctx):
    """Print the landscape to a tidy csv."""
    landscape = Landscape(n_rows=100, n_cols=100, score_func=simple_hill)
    landscape.export('simple_hill.csv')


@task
def draw_gabors(ctx, grid_size=10, win_size=None, output='landscape.png',
                open_after=False):
    """Draw gabors sampled from the landscape."""

    if win_size is None:
        fullscr = True
        size = (1, 1)  # Ignored when full screen
    else:
        fullscr = False
        size = win_size

    win = visual.Window(size=size, units='pix', color=(0.6, 0.6, 0.6),
                        fullscr=fullscr)

    positions = range(0, 100, 100/grid_size)
    grid_positions = product(positions, positions)

    landscape = SimpleHill()
    gabors = landscape.make_gabors(grid_positions, win=win, size=gabor_size)

    stim_positions = create_stim_positions(n_rows=grid_size, n_cols=grid_size,
                                           win_size=win.size,
                                           stim_size=gabor_size)

    for (grid_pos, screen_pos) in zip(gabors.keys(), stim_positions):
        gabor = gabors[grid_pos]
        gabor.pos = screen_pos
        gabor.draw()

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
