library(plotly)
library(tidyverse)
library(gems)

data("Pilot")

PilotSimpleHill <- filter(Pilot, landscape_ix == 1)

custom_linetypes <- c(orientation='dot', spatial_frequency='solid')

plot_ly(PilotSimpleHill, x = ~selected_x, y = ~selected_y, z = ~score, color = ~subj_id, type = 'scatter3d',
        linetype = ~instructions, mode = 'lines+markers', split = "subj_id",
        opacity = 1, line = list(width = 2), marker = list(size=3), linetypes=custom_linetypes) %>%
  layout(
    scene = list(
      xaxis = list(title = "Orientation"),
      yaxis = list(title = "Spatial frequency"),
      zaxis = list(title = "Score"),
      camera = list(eye = list(x = -1, y = -1, z = 1))
    )
  )
