library(tidyverse)
library(lattice)
library(gems)

data("SimpleHill")

SimpleHillReduced <- SimpleHill %>%
  filter(x%%5 == 0, y%%5 == 0)

Gabors <- data_frame(
    x = c(2, 5, 7, 3, 8),
    y = c(1, 6, 3, 2, 1)
  ) %>%
  left_join(
    select(SimpleHill, x, y, score)
  )

wireframe(score ~ x * y, SimpleHillReduced,
          pts = Gabors,
          panel.3d.wireframe =
            function(x, y, z,
                     xlim, ylim, zlim,
                     xlim.scaled, ylim.scaled, zlim.scaled,
                     pts,
                     ...) {
              panel.3dwire(x = x, y = y, z = z,
                           xlim = xlim,
                           ylim = ylim,
                           zlim = zlim,
                           xlim.scaled = xlim.scaled,
                           ylim.scaled = ylim.scaled,
                           zlim.scaled = zlim.scaled,
                           ...)
              xx <-
                xlim.scaled[1] + diff(xlim.scaled) *
                (pts$x - xlim[1]) / diff(xlim)
              yy <-
                ylim.scaled[1] + diff(ylim.scaled) *
                (pts$y - ylim[1]) / diff(ylim)
              zz <-
                zlim.scaled[1] + diff(zlim.scaled) *
                (pts$score - zlim[1]) / diff(zlim)
              panel.3dscatter(x = xx,
                              y = yy,
                              z = zz,
                              xlim = xlim,
                              ylim = ylim,
                              zlim = zlim,
                              xlim.scaled = xlim.scaled,
                              ylim.scaled = ylim.scaled,
                              zlim.scaled = zlim.scaled,
                              ...)
            })
