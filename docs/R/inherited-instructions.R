# ---- inherited-instructions ----
library(tidyverse)
library(gems)
data("Gems")
data("SimpleHill")
t_ <- get_theme()

# ---- gen1 ----
TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

Gen1 <- Gems %>%
  filter(generation == 1) %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos)

Gen1Final <- Gen1 %>%
  filter(trial == 29)

# * gen1-positions ----
gen1_positions_plot <- ggplot(Gen1) +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y) +
  geom_segment(aes(group = subj_id)) +
  facet_wrap("block_ix", nrow = 1) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  annotate("point", x = 50, y = 50, shape = 4, size = 3) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines")) +
  labs(x = "orientation", y = "bar width") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)

# * gen1-scores ----
gen1_scores_plot <- ggplot(Gen1) +
  aes(trial, score) +
  geom_line(aes(group = interaction(subj_id, block_ix)), size = 0.2) +
  geom_line(stat = "summary", fun.y = "mean", size = 2,
            show.legend = FALSE) +
  facet_wrap("block_ix", nrow = 1) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * gen1-distance ----
gen1_distance_plot <- ggplot(Gen1) +
  aes(trial, distance_2d) +
  geom_line(aes(group = subj_id), size = 0.25) +
  geom_line(aes(group = 1),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = 2) +
  facet_wrap("block_ix", nrow = 1) +
  scale_y_reverse("distance to 2D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(expand = FALSE) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * gen1-final ----
gen1_final_scores_plot <- ggplot(Gen1Final) +
  aes(block_ix, score) +
  geom_line(aes(group = subj_id), size = 0.2) +
  geom_line(aes(group = 1), stat = "summary", fun.y = "mean", size = 2) +
  geom_hline(yintercept = 100, linetype = 2) +
  xlab("block") +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "bottom")

gen1_final_distances_plot <- ggplot(Gen1Final) +
  aes(block_ix, distance_2d) +
  geom_line(aes(group = subj_id), size = 0.2) +
  geom_line(aes(group = 1), stat = "summary", fun.y = "mean", size = 2) +
  xlab("block") +
  scale_y_reverse("distance to 2d peak") +
  geom_hline(yintercept = 0, linetype = 2) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "bottom")
