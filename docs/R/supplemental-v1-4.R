# ---- v1-4
library(tidyverse)
library(gems)

data("Gems")
data("SimpleHill")

TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

Gems <- Gems %>%
  filter(version %in% c(1.3, 1.4)) %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos) %>%
  recode_generation() %>%
  recode_block() %>%
  recode_trial_poly() %>%
  mutate(
    generation_label = ifelse(generation == 1, "generation 1", "generation 2"),
    block_label = ifelse(block_ix == 1, "block 1", "block 2")
  )

completed_subjs <- count(Gems, subj_id) %>%
  mutate(completed = n == 160) %>%
  filter(completed) %>%
  .$subj_id

# ---- v1-4-positions
Gems %>%
  filter(subj_id %in% completed_subjs) %>%
  group_by(landscape_name, block_ix, generation, trial, generation_label, block_label) %>%
  summarize(
    x = mean(current_x, na.rm = TRUE),
    y = mean(current_y, na.rm = TRUE),
    xend = mean(selected_x, na.rm = TRUE),
    yend = mean(selected_y, na.rm = TRUE)
  ) %>%
ggplot() +
  aes(x = x, y = y, xend = xend, yend = yend) +
  geom_segment(aes(color = landscape_name)) +
  facet_grid(generation_label ~ block_label)

# ---- v1-4-scores
ggplot(Gems) +
  aes(trial, score) +
  geom_line(aes(color = landscape_name), stat = "summary", fun.y = "mean") +
  facet_grid(generation_label ~ block_label)
