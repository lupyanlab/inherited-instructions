library(tidyverse)
library(gems)
data("Gems")

Search <- Gems %>%
  filter(landscape_ix == 0, team_trial >= 19, team_trial <= 39) %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeStims) %>%
  select(subj_id, instructions, ancestor_instructions, ori = gem_x, sf = gem_y) %>%
  gather(dimension, value, -(subj_id:ancestor_instructions)) %>%
  label_team_strategy() %>%
  recode_team_strategy()

Search %>%
  filter(subj_id == "GEMS115") %>%
  ggplot() +
  aes(value) +
  geom_density(aes(color = dimension))

ggplot(Search) +
  aes(value) +
  geom_density(aes(group = interaction(subj_id, dimension), color = dimension),
               alpha = 0.4) +
  geom_density(aes(group = dimension, color = dimension),
               size = 2) +
  facet_wrap("team_strategy")

ggplot(Search) +
  aes(value) +
  geom_density(aes(group = interaction(subj_id, dimension), color = dimension),
               alpha = 0.4) +
  geom_density(aes(group = dimension, color = dimension),
               size = 2) +
  facet_grid(instructions ~ team_strategy)
