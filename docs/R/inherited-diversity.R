# ---- inherited-diversity
library(tidyverse)
library(magrittr)
library(lattice)

library(lme4)
library(AICcmodavg)

library(gems)
t_ <- get_theme()

# Remove bounding box around all lattice plots.
# Also removes axis arrows!
trellis.par.set("axis.line",list(col=NA,lty=1,lwd=1))

# ---- methods ----
data("OrientationBias")
data("SpatialFrequencyBias")
data("SimpleHill")

# Defined in experiment/gems/landscapes.py
methods <- list(min_ori = 10,
                max_ori = 90,
                min_sf = 0.04,
                max_sf = 0.18) 

methods$n_gabors_in_landscape <- nrow(SimpleHill)

orientation_bias_landscape <- make_landscape(OrientationBias, "Orientation bias")
spatial_frequency_bias_landscape <- make_landscape(SpatialFrequencyBias, "Bar width bias")
simple_hill_landscape <- make_landscape(SimpleHill, "Simple hill")

# ---- results ----
data("Gems")
data("OrientationBias")
data("SpatialFrequencyBias")

# training-landscape-data ----
TrainingStimsLandscape <- bind_rows(
  OrientationBias = OrientationBias,
  SpatialFrequencyBias = SpatialFrequencyBias,
  .id = "landscape_name"
) %>%
  rename(
    gem_x = x,
    gem_y = y,
    gem_score = score,
    gem_ori = ori,
    gem_sf = sf
  )

TrainingLandscape <- bind_rows(
  OrientationBias = OrientationBias,
  SpatialFrequencyBias = SpatialFrequencyBias,
  .id = "landscape_name"
) %>%
  rename(
    current_x = x,
    current_y = y,
    current_score = score,
    current_ori = ori,
    current_sf = sf
  )


# training-data ----
TrainingStims <- Gems %>%
  filter(landscape_ix == 0) %>%
  left_join(TrainingLandscape) %>%
  melt_trial_stims() %>%
  left_join(TrainingStimsLandscape) %>%
  rank_stims_in_trial() %>%
  mutate(gem_selected = (selected == gem_pos)) %>%
  recode_instructions() %>%
  recode_trial()

Training <- TrainingStims %>%
  filter(gem_selected) %>%
  mutate_distance_1d()

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
training_distance_linear_mod <- lmer(
  distance_1d ~ trial_c * instructions_c + (trial_c|subj_id),
  data = Training
)

training_distance_linear_preds <- expand.grid(
  trial = 0:29,
  instructions_c = c(-0.5, 0.5)
) %>%
  recode_trial() %>%
  recode_instructions() %>%
  cbind(., predictSE(training_distance_linear_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(distance_1d = fit, se = se.fit)

training_distance_quad_mod <- lmer(
  distance_1d ~ (trial_z + trial_z_sqr) * instructions_c + (trial_z + trial_z_sqr|subj_id),
  data = Training
)

training_distance_quad_preds <- expand.grid(
  trial = 0:29,
  instructions_c = c(-0.5, 0.5)
) %>%
  recode_trial() %>%
  recode_instructions() %>%
  cbind(., predictSE(training_distance_quad_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(distance_1d = fit, se = se.fit)

training_distance_plot <- ggplot(Training) +
  aes(trial, distance_1d) +
  geom_ribbon(aes(ymin = distance_1d-se, ymax = distance_1d+se, fill = instructions),
              data = training_distance_quad_preds,
              alpha = 0.5, show.legend = FALSE) +
  geom_line(aes(color = instructions, group = subj_id), size = 0.25) +
  geom_line(aes(color = instructions, group = instructions),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_y_reverse("distance to 1D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(xlim = c(0, 30), expand = FALSE) +
  t_$scale_x_trial +
  t_$scale_color_instructions +
  t_$scale_fill_instructions +
  t_$theme +
  theme(legend.position = "top")

# * training-scores ----
training_scores_quad_mod <- lmer(
  score ~ (trial_z + trial_z_sqr) * instructions_c + (trial_z + trial_z_sqr|subj_id),
  data = Training
)

training_scores_quad_preds <- expand.grid(
  trial = 0:29,
  instructions_c = c(-0.5, 0.5)
) %>%
  recode_trial() %>%
  recode_instructions() %>%
  cbind(., predictSE(training_scores_quad_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(score = fit, se = se.fit)

training_scores_plot <- ggplot(Training) +
  aes(x = trial, y = score) +
  geom_ribbon(aes(ymin = score-se, ymax = score+se, fill = instructions),
              data = training_scores_quad_preds,
              alpha = 0.5, show.legend = FALSE) +
  geom_line(aes(color = instructions, group = subj_id), size = 0.25) +
  geom_line(aes(color = instructions, group = instructions),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  coord_cartesian(xlim = c(0, 30), expand = FALSE) +
  t_$scale_x_trial +
  t_$scale_color_instructions +
  t_$scale_fill_instructions +
  t_$theme +
  theme(legend.position = "top")

# * training-sensitivity ----
training_sensitivity_plot <- ggplot(Training) +
  aes(color = instructions) +
  geom_density(aes(group = subj_id), size = 0.25, adjust = 1.5) +
  geom_density(size = 2, adjust = 1.5) +
  t_$scale_color_instructions +
  t_$theme +
  coord_cartesian(ylim = c(0, 0.6)) +
  theme(legend.position = "top")

score_sensitivity_plot <- training_sensitivity_plot +
  aes(gem_score_rank) +
  scale_x_reverse("rank (by score)", breaks = 1:6)

orientation_sensitivity_plot <- training_sensitivity_plot +
  aes(gem_x_rank) +
  scale_x_reverse("rank (by orientation)", breaks = 1:6)

spatial_frequency_sensitivity_plot <- training_sensitivity_plot +
  aes(gem_y_rank) +
  scale_x_reverse("rank (by spatial frequency)", breaks = 1:6)

# ** training-sensitivity-ori ----
training_sensitivity_ori_mod <- glmer(
  gem_selected ~ gem_x_rel_c * instructions_c + (gem_x_rel_c|subj_id),
  family = "binomial", data = TrainingStims
)

training_sensitivity_ori_preds <- expand.grid(
  gem_x_rel_c = seq(-10, 10),
  instructions_c = c(-0.5, 0.5)
) %>%
  cbind(., predictSE(training_sensitivity_ori_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(gem_selected = fit, se = se.fit) %>%
  recode_instructions()

training_sensitivity_ori_plot <- ggplot(TrainingStims) +
  aes(x = gem_x_rel_c, y = gem_selected) +
  geom_smooth(aes(ymin = gem_selected-se, ymax = gem_selected+se,
                  color = instructions),
              data = training_sensitivity_ori_preds,
              stat = "identity") +
  scale_y_continuous("", labels = scales::percent) +
  labs(x = "relative difference in orientation") +
  coord_cartesian(ylim = c(0, 0.6)) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top")

# ** training-sensitivity-sf ----
training_sensitivity_sf_mod <- glmer(
  gem_selected ~ gem_y_rel_c * instructions_c + (gem_y_rel_c|subj_id),
  family = "binomial", data = TrainingStims
)

training_sensitivity_sf_preds <- expand.grid(
    gem_y_rel_c = seq(-10, 10),
    instructions_c = c(-0.5, 0.5)
  ) %>%
  cbind(., predictSE(training_sensitivity_sf_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(gem_selected = fit, se = se.fit) %>%
  recode_instructions()

training_sensitivity_sf_plot <- ggplot(TrainingStims) +
  aes(x = gem_y_rel_c, y = gem_selected) +
  geom_smooth(aes(ymin = gem_selected-se, ymax = gem_selected+se,
                  color = instructions),
              data = training_sensitivity_sf_preds,
              stat = "identity") +
  scale_y_continuous("", labels = scales::percent) +
  labs(x = "relative difference in spatial frequency") +
  coord_cartesian(ylim = c(0, 0.6)) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top")

# gen1-data ----
TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

Gen1 <- Gems %>%
  filter(landscape_ix != 0, generation == 1) %>%
  mutate_distance_1d() %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos)

Gen1Final <- Gen1 %>%
  filter(trial == 39)

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
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines")) +
  labs(x = "orientation", y = "bar width") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)

# * gen1-scores ----
gen1_scores_plot <- ggplot(Gen1) +
  aes(trial, score, color = instructions) +
  geom_line(aes(group = interaction(subj_id, landscape_ix)), size = 0.2) +
  geom_line(stat = "summary", fun.y = "mean", size = 2,
            show.legend = FALSE) +
  facet_wrap("landscape_ix", nrow = 1) +
  t_$scale_color_instructions +
  t_$theme +
  theme(legend.position = "top",
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
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * gen1-final ----
gen1_final_scores_plot <- ggplot(Gen1Final) +
  aes(landscape_ix, score, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.2) +
  geom_line(aes(group = instructions), stat = "summary", fun.y = "mean", size = 2) +
  geom_hline(yintercept = 100, linetype = 2) +
  xlab("block") +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "bottom")

gen1_final_distances_plot <- ggplot(Gen1Final) +
  aes(landscape_ix, distance_2d, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.2) +
  geom_line(aes(group = instructions), stat = "summary", fun.y = "mean", size = 2) +
  xlab("block") +
  scale_y_reverse("distance to 2d peak") +
  geom_hline(yintercept = 0, linetype = 2) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "bottom")

# gen2-data ----
Gen2 <- Gems %>%
  filter(landscape_ix != 0, generation == 2) %>%
  mutate_distance_1d() %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos) %>%
  label_team_strategy() %>%
  recode_team_strategy()

Gen2Final <- Gen2 %>%
  filter(trial == 39)

# * gen2-positions ----
gen2_positions_plot <- (gen1_positions_plot %+% Gen2)

# * gen2-distance ----
gen2_distance_plot <- (gen1_distance_plot %+% Gen2)

# * gen2-scores ----
gen2_scores_plot <- (gen1_scores_plot %+% Gen2)

# * gen2-final ----
gen2_final_scores_plot <- (gen1_final_scores_plot %+% Gen2Final)
gen2_final_distances_plot <- (gen1_final_distances_plot %+% Gen2Final)

# strategies-data ----
TestLandscapeStartingScores <- SimpleHill %>%
  select(starting_x = x, starting_y = y, starting_score = score)

Strategies <- Gems %>%
  filter(landscape_ix != 0, team_trial == 39) %>%
  mutate_distance_1d() %>%
  mutate_distance_2d() %>%
  parse_pos("starting_pos", "starting_") %>%
  select(-starting_score) %>%
  left_join(TestLandscapeStartingScores) %>%
  mutate_distance_1d("starting_x", "starting_y", "inherited_distance_1d") %>%
  mutate(
    # distance from origin to starting position inherited from ancestor
    inherited_distance =
      distance_to_peak(0, 0) - distance_to_peak(starting_x, starting_y),
    # distance from starting position to position after 20 trials
    achieved_distance =
      distance_to_peak(starting_x, starting_y) - distance_to_peak(selected_x, selected_y),
    achieved_score = score - starting_score
  ) %>%
  label_team_strategy() %>%
  recode_team_strategy()

# * strategies-scores ----
strategies_scores_plot <- ggplot(Strategies) +
  aes(team_strategy_label, score) +
  geom_bar(aes(fill = team_strategy_label),
           stat = "summary", fun.y = "mean",
           alpha = 0.4) +
  geom_point(aes(color = team_strategy_label),
             position = position_jitter(width = 0.2, height = 0)) +
  geom_hline(yintercept = 100, linetype = 2) +
  coord_cartesian(ylim = c(0, 100), expand = FALSE) +
  labs(x = "") +
  t_$scale_color_strategy +
  t_$scale_fill_strategy +
  guides(fill = "none", color = "none") +
  t_$theme +
  theme(panel.grid.major.x = element_blank())

strategies_relative_scores_plot <- ggplot(Strategies) +
  aes(team_strategy_label, achieved_score) +
  geom_bar(aes(fill = team_strategy_label),
           stat = "summary", fun.y = "mean",
           alpha = 0.4) +
  geom_point(aes(color = team_strategy_label),
             position = position_jitter(width = 0.2, height = 0)) +
  labs(x = "", y = "relative score") +
  guides(fill = "none", color = "none") +
  t_$scale_color_strategy +
  t_$scale_fill_strategy +
  t_$theme +
  theme(panel.grid.major.x = element_blank())

# * strategies-distances ----
strategies_distance_plot <- ggplot(Strategies) +
  aes(team_strategy_label, distance_2d) +
  geom_boxplot(aes(color = team_strategy_label)) +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_y_reverse() +
  t_$scale_color_strategy +
  t_$theme +
  labs(x = "", y = "distance to 2d peak") +
  guides(color = "none")

strategies_relative_distance_plot <- ggplot(Strategies) +
  aes(team_strategy_label, achieved_distance) +
  geom_boxplot(aes(color = team_strategy_label)) +
  t_$scale_color_strategy +
  t_$theme +
  labs(x = "", y = "relative distance to 2d peak") +
  guides(color = "none")

# * strategies-correlations ----
achieved_to_inherited_plot <- ggplot(Strategies) +
  aes(inherited_distance, achieved_distance) +
  geom_point(aes(color = team_strategy_label))

achieved_to_inherited_1d_plot <- ggplot(Strategies) +
  aes(inherited_distance_1d, achieved_distance) +
  geom_point(aes(color = team_strategy_label))
