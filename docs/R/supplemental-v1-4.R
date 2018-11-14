# ---- v1-4
library(tidyverse)
library(gems)

data("Gems")
data("Instructions")

subj_map <- Gems %>%
  filter(landscape_name == "Orientation") %>%
  select(subj_id, version, generation) %>%
  unique() %>%
  drop_na()

inheritance_map <- Gems %>%
  filter(landscape_name == "Orientation") %>%
  select(subj_id, generation, inherit_from) %>%
  unique() %>%
  drop_na()

Instructions <- left_join(subj_map, Instructions) %>%
  select(subj_id, generation, instructions)
