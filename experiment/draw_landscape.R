library(tidyverse)

limits <- seq(0, 100, by = 2)
z <- expand.grid(x = limits, y = limits) %>%
  mutate(
    z = -x^2 - y^2 + 100*x + 100*y,
    z_normalized = z - min(z)
  )
lattice::wireframe(z ~ x * y, data = z)
