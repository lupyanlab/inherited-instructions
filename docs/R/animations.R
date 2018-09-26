library(tidyverse)
library(gganimate)  # remotes::install_github("thomasp85/gganimate", ref="v0.1.1")
library(geomnet)

library(gems)
data("Gems")

Gems101 <- Gems %>%
  filter(subj_id == "GEMS101", block_ix == 1) %>%
  melt_trial_stims() %>%
  mutate(
    is_selected = (selected == gem_pos)
  ) %>%
  arrange(trial)

trials_plot <- ggplot(Gems101) +
  aes(gem_x, gem_y, frame = trial) +
  geom_segment(aes(current_x, current_y, xend = selected_x, yend = selected_y, group = 1, cumulative = TRUE)) +
  geom_circle(aes(x = current_x, y = current_y), radius = 0.15) +
  geom_point(aes(color = factor(is_selected), frame = trial)) +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70)) +
  annotate("point", x = 50, y = 50, shape = "X", size = 4) +
  theme(legend.position = "none")

gganimate(trials_plot)
