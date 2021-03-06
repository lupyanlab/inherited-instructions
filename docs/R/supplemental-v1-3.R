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

# * positions ----
positions_plot <- ggplot(Gems) +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y) +
  geom_segment(aes(group = subj_id, color = generation_f)) +
  facet_wrap("block_ix", nrow = 1) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  annotate("point", x = 50, y = 50, shape = 4, size = 3) +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines")) +
  labs(x = "orientation", y = "bar width") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)

# * scores ----
scores_plot <- ggplot(Gems) +
  aes(trial, score) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  geom_line(aes(group = simulation_type), stat = "summary", fun.y = "mean", color = "gray",
            data = BotsMirror, size = 1, linetype = "twodash") +
  scale_color_discrete("Generation") +
  facet_wrap("block_ix", nrow = 1) +
  t_$theme +
  theme(legend.position = "bottom",
        panel.spacing.x = unit(1, "lines"))

# * rts ----
rts_plot <- ggplot(Gems) +
  aes(trial, rt) +
  geom_point(aes(color = generation_f), stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = generation_f, color = generation_f), se = FALSE, method = "lm") +
  scale_color_discrete("Generation") +
  facet_wrap("block_ix", nrow = 1) +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * distance ----
distance_plot <- ggplot(Gems) +
  aes(trial, distance_2d) +
  geom_line(aes(group = generation_f, color = generation_f),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_line(aes(group = simulation_type), stat = "summary", fun.y = "mean", color = "gray", linetype = "twodash",
            data = Bots, size = 1) +
  geom_hline(yintercept = 0, linetype = 2) +
  facet_wrap("block_ix", nrow = 1) +
  scale_y_reverse("distance to 2D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(expand = FALSE) +
  t_$theme +
  theme(legend.position = "bottom",
        panel.spacing.x = unit(1, "lines"))

# * final ----

final_scores_plot <- ggplot(GemsFinal) +
  aes(factor(block_ix), score) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  geom_line(aes(group = simulation_type),
            data = BotsFinal, color = "gray", linetype = "twodash", size = 2) +
  scale_color_discrete("Generation") +
  xlab("block") +
  ylab("final score") +
  t_$theme +
  theme(legend.position = "bottom")

final_distances_plot <- ggplot(GemsFinal) +
  aes(block_ix, distance_2d) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  xlab("block") +
  scale_y_reverse("distance to 2d peak") +
  geom_hline(yintercept = 0, linetype = 2) +
  t_$theme +
  theme(legend.position = "bottom")