# ---- v1-1
library(tidyverse)
library(gems)
data("Gems")
data("SimpleHill")
t_ <- get_theme()

TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

recode_generation <- function(frame) {
  map <- data_frame(generation = 1:2, generation_f = factor(c(1, 2)))
  if(missing(frame)) return(map)
  left_join(frame, map)
}

GemsV1.1 <- Gems %>%
  filter(version == 1.1, !is.na(selected)) %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos) %>%
  recode_generation()

GemsV1.1Final <- GemsV1.1 %>%
  group_by(generation, subj_id, block_ix) %>%
  filter(trial == max(trial)) %>%
  ungroup()

# * v1-1-positions ----
v1.1_positions_plot <- ggplot(GemsV1.1) +
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

# * v1-1-scores ----
v1.1_scores_plot <- ggplot(GemsV1.1) +
  aes(trial, score) +
  geom_line(aes(group = interaction(subj_id, block_ix), color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2,
            show.legend = FALSE) +
  facet_wrap("block_ix", nrow = 1) +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * v1-1-distance ----
v1.1_distance_plot <- ggplot(GemsV1.1) +
  aes(trial, distance_2d) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.25) +
  geom_line(aes(group = generation_f, color = generation_f),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = 2) +
  facet_wrap("block_ix", nrow = 1) +
  scale_y_reverse("distance to 2D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(expand = FALSE) +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * v1.1-final ----
v1.1_final_scores_plot <- ggplot(GemsV1.1Final) +
  aes(block_ix, score) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  geom_hline(yintercept = 100, linetype = 2) +
  xlab("block") +
  t_$theme +
  theme(legend.position = "bottom")

v1.1_final_distances_plot <- ggplot(GemsV1.1Final) +
  aes(block_ix, distance_2d) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  xlab("block") +
  scale_y_reverse("distance to 2d peak") +
  geom_hline(yintercept = 0, linetype = 2) +
  t_$theme +
  theme(legend.position = "bottom")
