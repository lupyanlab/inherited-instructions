from collections import namedtuple
from psychopy import visual
from itertools import product
from numpy import linspace
from pandas import DataFrame

from goldminers.score_funcs import simple_hill


Gabor = namedtuple('Gabor', 'ori sf')
Gem = namedtuple('Gem', 'x y ori sf score')


class Landscape(object):
    """
    A landscape is a grid of Gems.
    """
    min_ori, max_ori = 180, 0
    min_sf, max_sf = 0.01, 0.05

    def __init__(self, n_rows, n_cols, score_func):
        self.dims = (n_rows, n_cols)
        self.get_score = score_func

        self.orientations = linspace(self.min_ori, self.max_ori,
                                     num=n_cols, endpoint=False)
        self.spatial_frequencies = linspace(self.min_sf, self.max_sf, num=n_rows)

        self._gems = {}

    def get(self, grid_pos):
        """Get the Gem at this position, creating it if necessary."""
        return self._gems.setdefault(grid_pos, self.create(grid_pos))

    def create(self, grid_pos):
        gabor = self.get_gabor(grid_pos)
        score = self.get_score(grid_pos)
        return Gem(grid_pos[0], grid_pos[1], gabor.ori, gabor.sf, score)

    def get_gabor(self, grid_pos):
        """Get the features for the stimuli at grid position."""
        ori_ix, sf_ix = grid_pos
        return Gabor(self.orientations[ori_ix], self.spatial_frequencies[sf_ix])

    def to_tidy_data(self):
        coords = [self.get((x, y)) for x, y in create_grid(*self.dims)]
        return DataFrame.from_records(coords, columns=Gem._fields)

    def export(self, filename):
        tidy_data = self.to_tidy_data()
        tidy_data.to_csv(filename, index=False)


class SimpleHill(Landscape):
    def __init__(self):
        return super(SimpleHill, self).__init__(n_rows=100, n_cols=100, score_func=simple_hill)


def create_stim_positions(n_rows, n_cols, win_size, stim_size=0):
    indices = create_grid(n_rows, n_cols)

    win_width, win_height = win_size
    win_left, win_right = -win_width/2, win_width/2
    win_bottom, win_top = -win_height/2, win_height/2

    # Sample row and column positions with stim sized buffer
    x_positions = linspace(win_left+stim_size, win_right-stim_size, num=n_cols)
    y_positions = linspace(win_bottom+stim_size, win_top-stim_size, num=n_rows)

    return product(x_positions, y_positions)


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


def create_grid(n_rows, n_cols):
    """Create all row, col grid positions.

    Grid positions are given as positive indices starting at 0.
    Rows range from 0 to (n_rows-1).
    Columns range from 0 to (n_cols-1).
    """
    return product(range(n_rows), range(n_cols))
