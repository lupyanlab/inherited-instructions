from psychopy import visual
from itertools import product
from numpy import linspace


def create_grid(n_rows, n_cols):
    return product(range(n_rows), range(n_cols))


Coords = namedtuple('x', 'y', 'score')

class Landscape:
    min_ori, max_ori = 180, 0
    min_sf, max_sf = 0.01, 0.05

    def __init__(self, n_rows, n_cols, eval_func):
        self.grid = create_grid(n_rows, n_cols)
        self.orientations = linspace(self.min_ori, self.max_ori,
                                     num=n_cols, endpoint=False)
        self.spatial_frequencies = linspace(self.min_sf, self.max_sf, num=n_rows)

        self.score_cache = {}
        self.eval_func = eval_func

    def score(self, grid_pos):
        return self.score_cache.setdefault(grid_pos, self.eval_func(grid_pos))

    def export(self, filename):
        coords = [Coords(x, y, self.score(x, y)) for x, y in self.grid]
        tidy_data = pandas.DataFrame.from_records(coords)
        tidy_data.to_csv(filename)


def create_stim_positions(self, n_rows, n_cols, win_size, stim_size=0):
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
