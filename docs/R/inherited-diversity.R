# ---- inherited-diversity
library(tidyverse)
library(magrittr)
library(lattice)

library(gems)
t_ <- get_theme()

# Remove bounding box around all lattice plots.
# Also removes axis arrows!
trellis.par.set("axis.line",list(col=NA,lty=1,lwd=1))

# ---- methods ----
# Defined in experiment/gems/landscapes.py
methods <- list(min_ori = 10,
                max_ori = 90,
                min_sf = 0.04,
                max_sf = 0.18) 

data("SimpleHill")
methods$n_gabors_in_landscape <- nrow(SimpleHill)

# ---- results ----
data("Gems")
data("OrientationBias")
data("SpatialFrequencyBias")

# training-data ----
TrainingLandscapes <- bind_rows(
    OrientationBias = OrientationBias,
    SpatialFrequencyBias = SpatialFrequencyBias,
    .id = "landscape_name"
  ) %>%
  rename(
    gem_x = x,
    gem_y = y,
    gem_score = score
  )

Training <- Gems %>%
  filter(landscape_ix == 0) %>%
  mutate_distance_1d() %>%
  melt_trial_stims() %>%
  left_join(TrainingLandscapes) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos)

# * training-positions ----
training_positions_plot <- ggplot(Training) +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y, color = instructions) +
  geom_segment(aes(group = subj_id), size = 0.25) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  geom_hline(yintercept = 50, linetype = 2, color = t_$get_colors("blue")) +
  geom_vline(xintercept = 50, linetype = 2, color = t_$get_colors("green")) +
  annotate("text", x = 30, y = 50, label = "peak sf",
           vjust = 1.3, color = t_$get_colors("blue")) +
  annotate("text", x = 50, y = 30, label = "peak ori", angle = 90,
           vjust = -0.5, color = t_$get_colors("green")) +
  labs(x = "orientation", y = "bar width") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "top")

# * training-distance ----
training_distance_plot <- ggplot(Training) +
  aes(trial, distance_1d, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.25) +
  geom_line(aes(group = instructions),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_y_reverse("distance to 1D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(xlim = c(0, 30), expand = FALSE) +
  t_$scale_x_trial +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top")

# * training-scores ----
training_scores_plot <- ggplot(Training) +
  aes(x = trial, y = score, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.25) +
  geom_line(aes(group = instructions),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  coord_cartesian(xlim = c(0, 30), expand = FALSE) +
  t_$scale_x_trial +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top")

# * training-score-rank ----
training_score_rank_plot <- ggplot(Training) +
  aes(gem_score_rank, color = instructions) +
  geom_density(aes(group = subj_id),
               size = 0.25) +
  geom_density(size = 2, adjust = 2) +
  scale_x_reverse("stim score (rank)", breaks = 1:6) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top")

# gen1-data ----
Gen1 <- Gems %>%
  filter(landscape_ix != 0, generation == 1) %>%
  mutate_distance_1d() %>%
  mutate_distance_2d()

# * gen1-positions ----
gen1_positions_plot <- ggplot(Gen1) +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y) +
  geom_segment(aes(color = instructions, group = subj_id)) +
  facet_wrap("landscape_ix", nrow = 1) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  annotate("point", x = 50, y = 50, shape = 4, size = 3) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "bottom",
        panel.spacing.x = unit(1, "lines")) +
  labs(x = "orientation", y = "bar width") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)
gen1_positions_plot

# * gen1-scores ----
gen1_scores_plot <- ggplot(Gen1) +
  aes(trial, score, color = instructions) +
  geom_line(aes(group = interaction(subj_id, landscape_ix)), size = 0.2) +
  geom_line(stat = "summary", fun.y = "mean", size = 2,
            show.legend = FALSE) +
  facet_wrap("landscape_ix", nrow = 1) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "bottom",
        panel.spacing.x = unit(1, "lines"))
  
# * gen1-distance ----
gen1_distance_plot <- ggplot(Gen1) +
  aes(trial, distance_2d, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.25) +
  geom_line(aes(group = instructions),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = 2) +
  facet_wrap("landscape_ix", nrow = 1) +
  scale_y_reverse("distance to 2D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(expand = FALSE) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "bottom",
        panel.spacing.x = unit(1, "lines"))

# * gen1-final-scores ----
Gen1Final <- Gen1 %>%
  filter(trial == 39)
gen1_final_scores_plot <- ggplot(Gen1Final) +
  aes(landscape_ix, score, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.2) +
  geom_line(aes(group = instructions), stat = "summary", fun.y = "mean", size = 2) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "bottom")

# strategies-data ----
Strategies <- Gems %>%
  filter(landscape_ix != 0, team_trial == 39) %>%
  label_team_strategy() %>%
  recode_team_strategy() %>%
  mutate(distance_to_peak = distance_to_peak(selected_x, selected_y))

# * strategies-scores ----
strategies_plot <- ggplot(Strategies) +
  aes(team_strategy_label, score) +
  geom_bar(aes(fill = team_strategy_label),
           stat = "summary", fun.y = "mean",
           alpha = 0.4) +
  geom_point(aes(color = team_strategy_label),
             position = position_jitter(width = 0.2, height = 0)) +
  coord_cartesian(ylim = c(0, 100), expand = FALSE) +
  labs(x = "") +
  t_$scale_color_strategy +
  t_$scale_fill_strategy +
  guides(fill = "none", color = "none") +
  t_$theme +
  theme(panel.grid.major.x = element_blank())
  