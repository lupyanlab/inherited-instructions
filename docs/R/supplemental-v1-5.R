# ---- v1-5
library(tidyverse)
library(gems)

data("Gems")
data("SimpleHill")

TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

Gems <- Gems %>%
  filter(version %in% c(1.3, 1.4, 1.5), landscape_name == "SimpleHill") %>%
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
    feedback_source = ifelse(inherit_from == "GEMS000", "optimal", "endogenous")
  )

ggplot(filter(Gems, generation == 2)) +
  aes(trial, score) +
  geom_line(aes(color = feedback_source), stat = "summary", fun.y = "mean") +
  facet_wrap("block_ix")
