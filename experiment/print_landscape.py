#!/usr/bin/env python
from psychopy import visual, event, core
from numpy import linspace

from goldminers import Landscape
from goldminers.score_funcs import simple_hill

landscape = Landscape(n_rows=100, n_cols=100, score_func=simple_hill)
landscape.export('simple_hill.csv')
