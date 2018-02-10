#!/usr/bin/env python
import subprocess
from itertools import product
from psychopy import visual, event, core
from numpy import linspace

from goldminers import SimpleHill, create_stim_positions

def draw_gabors(grid_size, win, gabor_size=60):
    positions = range(0, 100, 100/grid_size)
    grid_positions = product(positions, positions)
    landscape = SimpleHill()
    gabors = landscape.make_gabors(grid_positions, win=win, size=gabor_size)
    stim_positions = create_stim_positions(n_rows=grid_size, n_cols=grid_size, win_size=win.size, stim_size=gabor_size)

    for (gabor, pos) in zip(gabors, stim_positions):
        gabor.pos = pos
        gabor.draw()

    win.flip()

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--grid-size', '-g', default=10)
    parser.add_argument('--win_size', '-w')
    parser.add_argument('--output', '-o', default='landscape.png')
    parser.add_argument('--open-after', '-p', action='store_true')

    args = parser.parse_args()

    fullscr = args.win_size is None
    size = (800, 600) if args.win_size is None else (args.win_size, args.win_size)
    win = visual.Window(size=size, units='pix', color=(0.6, 0.6, 0.6), fullscr=fullscr)
    draw_gabors(args.grid_size, win)
    win.getMovieFrame()
    win.saveMovieFrames(args.output)
    win.close()

    if args.open_after:
        subprocess.call(['open', args.output])
