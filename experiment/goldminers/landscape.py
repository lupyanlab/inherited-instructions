from collections import namedtuple
from psychopy import visual
from itertools import product
from numpy import linspace, random
from pandas import DataFrame

from goldminers.score_funcs import simple_hill


Gabor = namedtuple('Gabor', 'ori sf')
Gem = namedtuple('Gem', 'x y ori sf score')


class Landscape(object):
    """
    A landscape is a grid of Gems.
    """
    min_ori, max_ori = 180, 0
    min_sf, max_sf = 0.05, 0.2

    def __init__(self, n_rows, n_cols, score_func, seed=None):
        self.dims = (n_rows, n_cols)

        self.min_x, self.min_y = 0, 0
        self.max_x, self.max_y = self.dims

        self.get_score = score_func

        self.orientations = linspace(self.min_ori, self.max_ori,
                                     num=n_cols, endpoint=False)
        self.spatial_frequencies = linspace(self.min_sf, self.max_sf, num=n_rows)

        self._gems = {}

        self.prng = random.RandomState(seed)

    def get(self, grid_pos):
        """Get the Gem at this position, creating it if necessary."""
        return self._gems.setdefault(grid_pos, self.create(grid_pos))

    def create(self, grid_pos):
        gabor = self.get_gabor(grid_pos)
        score = self.get_score(grid_pos)
        return Gem(grid_pos[0], grid_pos[1], gabor.ori, gabor.sf, score)

    def get_gabor(self, grid_pos):
        """Get the features for the stimuli at grid position."""
        ori_ix, sf_ix = map(int, grid_pos)
        return Gabor(self.orientations[ori_ix], self.spatial_frequencies[sf_ix])

    def to_tidy_data(self):
        coords = [self.get((x, y)) for x, y in create_grid(*self.dims)]
        return DataFrame.from_records(coords, columns=Gem._fields)

    def export(self, filename):
        tidy_data = self.to_tidy_data()
        tidy_data.to_csv(filename, index=False)

    def get_neighborhood(self, grid_pos, radius):
        """Return a list of positions adjacent to the given position."""
        # TODO: Refactor create_grid to take optional parameter "center"
        # neighborhood = create_grid(radius, radius, center=grid_pos)
        grid_x, grid_y = grid_pos
        x_positions = range(grid_x-radius, grid_x+radius+1)
        y_positions = range(grid_y-radius, grid_y+radius+1)

        positions = []
        for pos in product(x_positions, y_positions):
            if self.is_position_on_grid(pos):
                positions.append(pos)

        return positions

    def sample_neighborhood(self, grid_pos, radius, n_sampled=None):
        """Sample positions from the neighborhood."""
        positions = self.get_neighborhood(grid_pos, radius)
        self.prng.shuffle(positions)
        n_sampled = n_sampled or len(positions)
        return positions[:n_sampled]

    def get_grating_stims(self, grid_positions):
        """Returns a list of visual.GratingStim objects at these positions."""
        gabors = {}
        for grid_pos in grid_positions:
            gabors[grid_pos] = self.get_grating_stim(grid_pos)
        return gabors

    def get_grating_stim(self, grid_pos):
        gabor = self.get_gabor(grid_pos)
        return visual.GratingStim(ori=gabor.ori, sf=gabor.sf, mask='circle', **self.grating_stim_kwargs)

    def sample_gabors(self, n_sampled, grid_pos, radius):
        """Returns a sample of the number of gabors in the neighborhood."""
        grid_positions = self.sample_neighborhood(n_sampled, grid_pos, radius)
        return self.get_gabors(grid_positions)

    def is_position_on_grid(self, grid_pos):
        x, y = grid_pos
        return (x >= self.min_x and x < self.max_x and
                y >= self.min_y and y < self.max_y)

class SimpleHill(Landscape):
    def __init__(self):
        return super(SimpleHill, self).__init__(n_rows=100, n_cols=100, score_func=simple_hill)
