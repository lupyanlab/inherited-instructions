#!/usr/bin/env python
from psychopy import visual, event, core
from numpy import linspace

from goldminers import create_positions, create_gabors

n_rows, n_cols = 5, 5
gabor_size = 60  # in pix

win = visual.Window(units='pix', color=(0.6, 0.6, 0.6))

# Calculate x, y positions for each row, col
positions = create_positions(n_rows, n_cols, win.size, gabor_size)

# Calculate orientations by cols and spatial frequencies by rows
orientations = linspace(180, 0, num=n_cols, endpoint=False)
spatial_frequencies = linspace(0.01, 0.1, num=n_rows)

# Create gabors for each position
gabors = create_gabors(win, positions, orientations, spatial_frequencies,
                       size=gabor_size)

for gabor in gabors:
    gabor.draw()

win.flip()
win.getMovieFrame()
win.saveMovieFrames('landscape.png')
core.quit()
