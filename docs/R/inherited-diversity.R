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

# * trial-plot ----
path_data <- data_frame(
  x = c(0, 4, 9),
  xend = c(4, 9, 10),
  y = c(0, 1, 5),
  yend = c(1, 5, 10)
)

gem_data <- data_frame(
  x = c(7, 8, 14, 6, 17, 10),
  y = c(3, 6, 12, 13, 8, 17)
)

radius_data <- data_frame(
  x0 = 10,
  y0 = 10,
  r = 8
)

trial_plot <- ggplot() +
  geom_point(aes(x, y), data = gem_data) +
  geom_segment(aes(x, y, xend = xend, yend = yend), data = path_data) +
  ggforce::geom_circle(aes(x0 = x0, y0 = y0, r = r), data = radius_data) +
  coord_fixed(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE) +
  scale_x_continuous("orientation", breaks = seq(0, 70, by = 10)) +
  scale_y_continuous("bar width", breaks = seq(0, 70, by = 10)) +
  t_$theme

# ---- results ----
data("Gems")
data("OrientationBias")
data("SpatialFrequencyBias")

r_ <- list()

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

r_$training_distance_linear_trial <- report_lmer_mod(training_distance_linear_mod, "trial_c")
r_$training_distance_linear_trial_v_instructions <- report_lmer_mod(training_distance_linear_mod, "trial_c:instructions_c")

r_$training_distance_quad_trial_sqr <- report_lmer_mod(training_distance_quad_mod, "trial_z")


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
training_sensitivity_ori_mod <- lmer(gem_x_rel_c ~ instructions_c + (1|subj_id), data = Training)
training_sensitivity_sf_mod <- lmer(gem_y_rel_c ~ instructions_c + (1|subj_id), data = Training)

r_$training_sensitivity_ori <- report_lmer_mod(training_sensitivity_ori_mod, "instructions_c")
r_$training_sensitivity_sf <- report_lmer_mod(training_sensitivity_sf_mod, "instructions_c")

training_sensitivity_ori_preds <- expand.grid(
  instructions_c = c(-0.5, 0.5)
) %>%
  cbind(., predictSE(training_sensitivity_ori_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(relative = fit, se = se.fit)

training_sensitivity_sf_preds <- expand.grid(
  instructions_c = c(-0.5, 0.5)
) %>%
  cbind(., predictSE(training_sensitivity_sf_mod, newdata = ., se = TRUE)) %>%
  as_data_frame() %>%
  rename(relative = fit, se = se.fit)

training_sensitivity_preds <- bind_rows(
  gem_x_rel_c = training_sensitivity_ori_preds,
  gem_y_rel_c = training_sensitivity_sf_preds,
  .id = "dimension"
) %>%
  recode_instructions() %>%
  recode_dimension()

TrainingRel <- Training %>%
  select(subj_id, instructions_c, gem_x_rel_c, gem_y_rel_c) %>%
  gather(dimension, relative, -subj_id, -instructions_c) %>%
  recode_instructions() %>%
  recode_dimension() %>%
  label_trained_dimension() %>%
  recode_trained_dimension()

training_sensitivity_plot <- ggplot(TrainingRel) +
  aes(dimension_label, relative, color = instructions) +
  geom_line(aes(group = subj_id), stat = "summary", fun.y = "mean",
            size = 0.3) +
  geom_smooth(aes(ymin = relative-se, ymax = relative+se, group = instructions),
              data = training_sensitivity_preds, stat = "identity",
              size = 1.5) +
  facet_wrap("instructions_facet_label") +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_x_discrete("") +
  scale_y_continuous("sensitivity") +
  coord_cartesian(xlim = c(1.45, 1.55)) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "none",
        panel.spacing.x = grid::unit(3, "lines"))

training_sensitivity_trained_dimensions_mod <- lmer(
  relative ~ trained_dimension_c * instructions_c + (1|subj_id), data = TrainingRel
)

training_sensitivity_trained_dimensions_preds <- expand.grid(
  trained_dimension_c = c(-0.5, 0.5),
  instructions_c = c(-0.5, 0.5)
) %>%
  cbind(., predictSE(training_sensitivity_trained_dimensions_mod, newdata = ., se = TRUE)) %>%
  rename(relative = fit, se = se.fit) %>%
  recode_instructions() %>%
  recode_trained_dimension()

training_sensitivity_trained_dimensions_plot <- ggplot(TrainingRel) +
  aes(trained_dimension_label, relative, color = instructions) +
  geom_line(aes(group = subj_id),
            size = 0.3, stat = "summary", fun.y = "mean") +
  geom_smooth(aes(group = instructions, ymin = relative - se, ymax = relative + se),
              stat = "identity",
              data = training_sensitivity_trained_dimensions_preds,
              size = 1.5) +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_x_discrete("") +
  scale_y_continuous("sensitivity") +
  coord_cartesian(xlim = c(1.45, 1.55)) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = c(0.5, 0.9))

# * training-sensitivity-ranks ----
training_sensitivity_ranks_plot <- ggplot(Training) +
  aes(color = instructions) +
  geom_density(aes(group = subj_id), size = 0.25, adjust = 1.5) +
  geom_density(size = 2, adjust = 1.5) +
  t_$scale_color_instructions +
  t_$theme +
  coord_cartesian(ylim = c(0, 0.6)) +
  theme(legend.position = "top")

orientation_sensitivity_ranks_plot <- training_sensitivity_ranks_plot +
  aes(gem_x_rank) +
  scale_x_reverse("rank (by orientation)", breaks = 1:6)

spatial_frequency_sensitivity_ranks_plot <- training_sensitivity_ranks_plot +
  aes(gem_y_rank) +
  scale_x_reverse("rank (by spatial frequency)", breaks = 1:6)

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

TestLandscapeCurrentScores <- SimpleHill %>%
  select(current_x = x, current_y = y, current_score = score)

TestLandscapeStims <- SimpleHill %>%
  select(gem_x = x, gem_y = y, gem_score = score, gem_ori = ori, gem_sf = sf)

ancestor_instructions <- Gems %>%
  select(subj_id, ancestor_instructions) %>%
  unique()

Sensitivities <- Gems %>%
  filter(landscape_ix == 0, team_trial >= 19, team_trial <= 39) %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeStims) %>%
  rank_stims_in_trial() %>%
  mutate(gem_selected = (selected == gem_pos)) %>%
  recode_instructions() %>%
  recode_trial() %>%
  filter(gem_selected) %>%
  mutate_distance_2d() %>%
  select(subj_id, instructions_c, gem_x_rel_c, gem_y_rel_c) %>%
  gather(dimension, relative, -subj_id, -instructions_c) %>%
  recode_instructions() %>%
  recode_dimension() %>%
  label_trained_dimension() %>%
  recode_trained_dimension() %>%
  left_join(ancestor_instructions) %>%
  label_team_strategy() %>%
  recode_team_strategy()

# * strategies-scores ----
strategies_scores_treat_mod <- lm(
  score ~ isolated_v_complementary + congruent_v_complementary,
  data = Strategies)

r_$strategies_scores_mod_isolated_v_complementary <- totems::report_lm_mod(
  strategies_scores_treat_mod, "isolated_v_complementary")
r_$strategies_scores_mod_congruent_v_complementary <- totems::report_lm_mod(
  strategies_scores_treat_mod, "congruent_v_complementary")

strategies_scores_helmert_mod <- lm(
  score ~ helmert_isolated_v_congruent + helmert_complementary_v_all,
  data = Strategies)

r_$strategies_scores_helmert_mod_main <- totems::report_lm_mod(
  strategies_scores_helmert_mod, "helmert_complementary_v_all")
r_$strategies_scores_helmert_mod_resid <- totems::report_lm_mod(
  strategies_scores_helmert_mod, "helmert_isolated_v_congruent")

strategies_scores_preds <- recode_team_strategy() %>%
  cbind(., predict(strategies_scores_treat_mod, newdata = ., se = TRUE)) %>%
  rename(score = fit, se = se.fit)

strategies_scores_plot <- ggplot(Strategies) +
  aes(team_strategy_label, score) +
  geom_bar(aes(fill = team_strategy_label),
           stat = "summary", fun.y = "mean",
           alpha = 0.4) +
  geom_errorbar(aes(ymin = score-se, ymax = score+se),
                width = 0.2, data = strategies_scores_preds) +
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

strategies_relative_scores_treat_mod <- lm(
  achieved_score ~ isolated_v_complementary + congruent_v_complementary,
  data = Strategies)

r_$strategies_relative_scores_mod_isolated_v_complementary <- totems::report_lm_mod(
  strategies_relative_scores_treat_mod, "isolated_v_complementary")
r_$strategies_relative_scores_mod_congruent_v_complementary <- totems::report_lm_mod(
  strategies_relative_scores_treat_mod, "congruent_v_complementary")

strategies_relative_scores_helmert_mod <- lm(
  score ~ helmert_isolated_v_congruent + helmert_complementary_v_all,
  data = Strategies)

r_$strategies_relative_scores_helmert_mod_main <- totems::report_lm_mod(
  strategies_relative_scores_helmert_mod, "helmert_complementary_v_all")
r_$strategies_relative_scores_helmert_mod_resid <- totems::report_lm_mod(
  strategies_relative_scores_helmert_mod, "helmert_isolated_v_congruent")

strategies_relative_scores_preds <- recode_team_strategy() %>%
  cbind(., predict(strategies_relative_scores_treat_mod, newdata = ., se = TRUE)) %>%
  rename(achieved_score = fit, se = se.fit)

strategies_relative_scores_plot <- ggplot(Strategies) +
  aes(team_strategy_label, achieved_score) +
  geom_bar(aes(fill = team_strategy_label),
           stat = "summary", fun.y = "mean",
           alpha = 0.4) +
  geom_errorbar(aes(ymin = achieved_score-se, ymax = achieved_score+se),
                width = 0.2, data = strategies_relative_scores_preds) +
  geom_point(aes(color = team_strategy_label),
             position = position_jitter(width = 0.2, height = 0)) +
  labs(x = "", y = "relative score") +
  guides(fill = "none", color = "none") +
  t_$scale_color_strategy +
  t_$scale_fill_strategy +
  t_$theme +
  theme(panel.grid.major.x = element_blank())

# * strategies-distances ----
strategies_distance_treat_mod <- lm(
  achieved_score ~ isolated_v_complementary + congruent_v_complementary,
  data = Strategies)

r_$strategies_distance_mod_isolated_v_complementary <- totems::report_lm_mod(
  strategies_distance_treat_mod, "isolated_v_complementary")
r_$strategies_distance_mod_congruent_v_complementary <- totems::report_lm_mod(
  strategies_distance_treat_mod, "congruent_v_complementary")

strategies_distance_helmert_mod <- lm(
  score ~ helmert_isolated_v_congruent + helmert_complementary_v_all,
  data = Strategies)

r_$strategies_distance_helmert_mod_main <- totems::report_lm_mod(
  strategies_distance_helmert_mod, "helmert_complementary_v_all")
r_$strategies_distance_helmert_mod_resid <- totems::report_lm_mod(
  strategies_distance_helmert_mod, "helmert_isolated_v_congruent")

strategies_distance_preds <- recode_team_strategy() %>%
  cbind(., predict(strategies_distance_treat_mod, newdata = ., se = TRUE)) %>%
  rename(distance_2d = fit, se = se.fit)

strategies_distance_plot <- ggplot(Strategies) +
  aes(team_strategy_label, distance_2d) +
  geom_boxplot(aes(color = team_strategy_label)) +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_y_reverse() +
  t_$scale_color_strategy +
  t_$theme +
  labs(x = "", y = "distance to 2d peak") +
  guides(color = "none")

strategies_relative_distance_treat_mod <- lm(
  achieved_score ~ isolated_v_complementary + congruent_v_complementary,
  data = Strategies)

r_$strategies_relative_distance_mod_isolated_v_complementary <- totems::report_lm_mod(
  strategies_relative_distance_treat_mod, "isolated_v_complementary")
r_$strategies_relative_distance_mod_congruent_v_complementary <- totems::report_lm_mod(
  strategies_relative_distance_treat_mod, "congruent_v_complementary")

strategies_relative_distance_helmert_mod <- lm(
  score ~ helmert_isolated_v_congruent + helmert_complementary_v_all,
  data = Strategies)

r_$strategies_relative_distance_helmert_mod_main <- totems::report_lm_mod(
  strategies_relative_distance_helmert_mod, "helmert_complementary_v_all")
r_$strategies_relative_distance_helmert_mod_resid <- totems::report_lm_mod(
  strategies_relative_distance_helmert_mod, "helmert_isolated_v_congruent")

strategies_relative_distance_preds <- recode_team_strategy() %>%
  cbind(., predict(strategies_relative_distance_treat_mod, newdata = ., se = TRUE)) %>%
  rename(achieved_distance = fit, se = se.fit)

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

# * strategies-sensitivity ----
sensitivities_plot <- ggplot(Sensitivities) +
  aes(trained_dimension_label, relative, color = instructions) +
  geom_line(aes(group = subj_id),
            size = 0.3, stat = "summary", fun.y = "mean") +
  # geom_smooth(aes(group = instructions, ymin = relative - se, ymax = relative + se),
  #             stat = "identity",
  #             data = training_sensitivity_trained_dimensions_preds,
  #             size = 1.5) +
  geom_hline(yintercept = 0, linetype = 2) +
  scale_x_discrete("") +
  scale_y_continuous("sensitivity") +
  coord_cartesian(xlim = c(1.45, 1.55)) +
  t_$theme +
  t_$scale_color_instructions +
  theme(legend.position = "bottom") +
  facet_wrap("team_strategy")
