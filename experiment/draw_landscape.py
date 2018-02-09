from itertools import product
from psychopy import visual, event, core
from numpy import linspace

# Size of gabor patches, in pix
size = 60

# Create coords for every gabor patch
n_cols, n_rows = 5, 5
coords = product(range(n_cols), range(n_rows))
# coords == [(0, 0), (0, 1), (0, 2), ..., (n_cols-1, n_rows-1)]

# Sample orientations from [180, 0)
orientations = linspace(180, 0, num=n_cols, endpoint=False)

# Sample spatial frequencies
spatial_frequencies = linspace(0.01, 0.1, num=n_rows)

# Create the window
win = visual.Window(units='pix', color=(0.6, 0.6, 0.6))

win_width, win_height = win.size
win_left, win_right = -win_width/2, win_width/2
win_bottom, win_top = -win_height/2, win_height/2

x_positions = linspace(win_left+size, win_right-size, num=n_cols)
y_positions = linspace(win_bottom+size, win_top-size, num=n_rows)

labels = []
gabors = []
for xid, yid in coords:
    pos = (x_positions[xid], y_positions[yid])
    ori = orientations[xid]
    sf = spatial_frequencies[yid]

    gabors.append(visual.GratingStim(win, mask='circle', pos=pos, ori=ori, sf=sf, size=size))
    label='%s\nori=%s, sf=%s' % (pos, ori, sf)
    labels.append(visual.TextStim(win, pos=(pos[0], pos[1]+(size*0.75)), text=label, height=12))

for gabor, label in zip(gabors, labels):
    gabor.draw()
    label.draw()

win.flip()
win.getMovieFrame()
win.saveMovieFrames('landscape.png')
core.quit()
