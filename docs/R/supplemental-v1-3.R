# ---- v1-3
library(tidyverse)
library(gems)

data("Gems")
data("SimpleHill")
data("Survey")
data("Instructions")
data("InstructionsCoded")
data("Bots")

t_ <- get_theme()

TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

Gems <- Gems %>%
  filter(version == 1.3) %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos) %>%
  recode_generation()

GemsFinal <- Gems %>%
  group_by(generation, subj_id, block_ix) %>%
  filter(trial == max(trial)) %>%
  ungroup()

subj_map <- select(Gems, subj_id, version, generation) %>% unique() %>% drop_na()
inheritance_map <- select(Gems, subj_id, version, generation, inherit_from) %>% unique() %>% drop_na()

Survey <- Survey %>%
  left_join(subj_map) %>%
  filter(version == 1.3) %>%
  recode_generation()

Instructions <- left_join(Instructions, subj_map) %>%
  select(subj_id, version, generation, instructions) %>%
  filter(version == 1.3)

Bots <- Bots %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos)

bots_asymptote_plot <- ggplot(Bots) +
  aes(trial, score) +
  geom_line(aes(color = simulation_type), stat = "summary", fun.y = "mean")
