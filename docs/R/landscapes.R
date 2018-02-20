library(tidyverse)
library(lattice)
library(gems)

data("SimpleHill")
data("OrientationBias")
data("SpatialFrequencyBias")
data("ReverseOrientation")
data("ReverseSpatialFrequency")
data("ReverseBoth")

# Compare SimpleHill and training landscapes
wireframe(score ~ x * y, data = SimpleHill, xlab = "orientation", ylab = "spatial frequency ")
wireframe(score ~ x * y, data = OrientationBias, xlab = "orientation", ylab = "spatial frequency ")
wireframe(score ~ x * y, data = SpatialFrequencyBias, xlab = "orientation", ylab = "spatial frequency ")

# Test landscapes
ori_plot <- ggplot() +
  aes(x, ori) +
  geom_point()

sf_plot <- ggplot() +
  aes(y, sf) +
  geom_point()

ori_plot %+% SimpleHill
ori_plot %+% OrientationBias
ori_plot %+% SpatialFrequencyBias
ori_plot %+% ReverseOrientation
ori_plot %+% ReverseBoth

sf_plot %+% SimpleHill
sf_plot %+% SpatialFrequencyBias
sf_plot %+% OrientationBias
sf_plot %+% ReverseSpatialFrequency
sf_plot %+% ReverseBoth