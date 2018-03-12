library(tidyverse)
library(gganimate)
library(geomnet)

data("Gems")

Gems111 <- Gems %>%
  filter(subj_id == "GEMS111", landscape_ix == 1) %>%
  melt_trial_stims() %>%
  mutate(
    is_selected = (selected == gem_pos)
  ) %>%
  arrange(trial)

trials_plot <- ggplot(Gems111) +
  aes(gem_x, gem_y, frame = trial) +
  geom_segment(aes(current_x, current_y, xend = selected_x, yend = selected_y, group = 1, cumulative = TRUE)) +
  geom_circle(aes(x = current_x, y = current_y), radius = 0.35) +
  geom_point(aes(color = factor(is_selected), frame = trial))

gganimate(trials_plot)