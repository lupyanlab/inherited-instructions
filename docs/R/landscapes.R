library(tidyverse)
library(lattice)

# SimpleHill
SimpleHill <- read_csv("experiment/gems/landscapes/SimpleHill.csv")
wireframe(score ~ x * y, data = SimpleHill, xlab = "orientation", ylab = "spatial frequency ")

# Recreate SimpleHill
grid <- expand.grid(
  x = 0:99,
  y = 0:99
)

simple_hill_func <- function(x, y) {
  (-x**2) - (y**2) + (100*x) + (100*y)
}

SimpleHill2 <- grid %>%
  mutate(score = simple_hill_func(x, y))

wireframe(score ~ x * y, data = SimpleHill2, xlab = "orientation", ylab = "spatial frequency ")

# Biased orientation
biased_orientation_func <- function(x, y) {
  (-x**2) + (100*x)
}
BiasedOrientation <- grid %>%
  mutate(score = biased_orientation_func(x, y))
wireframe(score ~ x * y, data = BiasedOrientation, xlab = "orientation", ylab = "spatial frequency ")

# Biased spatial frequency
biased_spatial_frequency_func <- function(x, y) {
  (-y**2) + (100*y)
}
BiasedSpatialFrequency <- grid %>%
  mutate(score = biased_spatial_frequency_func(x, y))
wireframe(score ~ x * y, data = BiasedSpatialFrequency, xlab = "orientation", ylab = "spatial frequency ")
