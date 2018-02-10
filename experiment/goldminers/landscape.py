from psychopy import visual
from itertools import product
from numpy import linspace


def create_grid(n_rows, n_cols):
    return product(range(n_rows), range(n_cols))


def create_positions(n_rows, n_cols, win_size, stim_size=0):
    indices = create_grid(n_rows, n_cols)

    win_width, win_height = win_size
    win_left, win_right = -win_width/2, win_width/2
    win_bottom, win_top = -win_height/2, win_height/2

    # Sample row and column positions with stim sized buffer
    x_positions = linspace(win_left+stim_size, win_right-stim_size, num=n_cols)
    y_positions = linspace(win_bottom+stim_size, win_top-stim_size, num=n_rows)

    return x_positions, y_positions

orientations = linspace(180, 0, num=n_cols, endpoint=False)
spatial_frequencies = linspace(0.01, 0.05, num=n_rows)


def create_gabors(window, coords, x_positions, y_positions, **grating_stim_kwargs):

    gabors = []
    for row, col in coords:
        pos = (x_positions[col], y_positions[row])
        ori = orientations[col]
        sf = spatial_frequencies[row]
        gabor = visual.GratingStim(window, mask='circle',
                                   pos=pos, ori=ori, sf=sf,
                                   **grating_stim_kwargs)
        gabors.append(gabor)

    return gabors
