library(tidyverse)
library(lattice)
library(gems)

data("SimpleHill")
data("OrientationBias")
data("SpatialFrequencyBias")

# Compare SimpleHill and training landscapes
wireframe(score ~ x * y, data = SimpleHill, xlab = "orientation", ylab = "spatial frequency ")
wireframe(score ~ x * y, data = OrientationBias, xlab = "orientation", ylab = "spatial frequency ")
wireframe(score ~ x * y, data = SpatialFrequencyBias, xlab = "orientation", ylab = "spatial frequency ")
