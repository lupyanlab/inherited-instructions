from itertools import product
from numpy import linspace


def create_positions(n_rows, n_cols, win_size, stim_size=0):
    indices = product(range(n_rows), range(n_cols))

    win_width, win_height = win_size
    win_left, win_right = -win_width/2, win_width/2
    win_bottom, win_top = -win_height/2, win_height/2

    # Sample row and column positions with stim sized buffer
    y_positions = linspace(win_bottom+stim_size, win_top-stim_size, num=n_rows)
    x_positions = linspace(win_left+stim_size, win_right-stim_size, num=n_cols)

    positions = [(y_positions[row], x_positions[col])
                 for row, col in indices]

    return positions
