# ---- inherited-diversity
library(tidyverse)
library(magrittr)
library(lattice)
trellis.par.set("axis.line",list(col=NA,lty=1,lwd=1))

library(gems)


colors <- RColorBrewer::brewer.pal(4, "Set2")
names(colors) <- c("green", "orange", "blue", "pink")
get_colors <- function(...) {
  names <- list(...)
  unname(colors[unlist(names)])
}

t_ <- list(
  theme = theme_minimal(),
  get_colors = get_colors,
  scale_color_instructions =
    scale_color_manual("Training", labels = c("Orientation", "Stripe width"), values = get_colors("green", "blue")),
  scale_color_strategy =
    scale_color_manual("Strategy", labels = recode_team_strategy()$team_strategy_label,
                       values = get_colors("orange", "green", "blue")),
  scale_fill_strategy =
    scale_fill_manual("Strategy", labels = recode_team_strategy()$team_strategy_label,
                      values = get_colors("orange", "green", "blue")),
  coord_landscape = coord_equal(xlim = c(0, 99), ylim = c(0, 99)),
  scale_x_orientation = scale_x_continuous("Orientation"),
  scale_y_spatial_frequency = scale_y_continuous("Spatial frequency")
)

# ---- methods
methods <- list(min_ori = 10,
                max_ori = 90,
                min_sf = 0.04,
                max_sf = 0.18) 

data("SimpleHill")
methods$n_gabors_in_landscape <- nrow(SimpleHill)

# ---- results
data("Gems")

Gen1 <- filter(Gems, landscape_ix != 0, generation == 1)
Gen2 <- filter(Gems, landscape_ix != 0, generation == 2)

# training ----
data("OrientationBias")
data("SpatialFrequencyBias")


OrientationTraining <- Gems %>%
  filter(instructions == "orientation", landscape_name == "OrientationBias")
SpatialFrequencyTraining <- Gems %>%
  filter(instructions == "spatial_frequency", landscape_name == "SpatialFrequencyBias")

training_plot <- ggplot() +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y) +
  geom_segment(aes(group = subj_id), size = 0.25) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  t_$theme +
  labs(x = "ori", y = "sf") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)


orientation_bias <- wireframe(
  score ~ x * y, xlab = "ori", ylab = "sf", data = OrientationBias,
  main = grid::textGrob("A. Orientation bias", x = 0))

orientation_training_plot <- (training_plot %+% OrientationTraining) +
  geom_vline(xintercept = 50, linetype = 2) +
  ggtitle("B. Orientation training")

spatial_frequency_bias <- wireframe(
  score ~ x * y, xlab = "ori", ylab = "sf", data = SpatialFrequencyBias,
  main = grid::textGrob("C. Spatial frequency bias", x = 0))

spatial_frequency_training_plot <- (training_plot %+% SpatialFrequencyTraining) +
  geom_hline(yintercept = 50, linetype = 2) +
  ggtitle("D. Spatial frequency training")


# gen1-scores ----
gen1_scores_plot <- ggplot(Gen1) +
  aes(trial, score, color = instructions) +
  geom_line(aes(group = interaction(subj_id, landscape_ix)), size = 0.2) +
  geom_line(stat = "summary", fun.y = "mean", size = 2) +
  facet_wrap("landscape_ix", nrow = 1) +
  t_$theme +
  theme(legend.position = "bottom")

# gen1-positions ----
gen1_positions_plot <- ggplot(Gen1) +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y) +
  geom_segment(aes(color = instructions, group = subj_id)) +
  facet_wrap("landscape_ix", nrow = 1) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  annotate("point", x = 50, y = 50, shape = 4, size = 3) +
  t_$theme +
  theme(legend.position = "bottom") +
  labs(x = "ori", y = "sf") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)

# gen1-final-scores ----
Gen1Final <- Gen1 %>%
  filter(trial == 39)
gen1_final_scores_plot <- ggplot(Gen1Final) +
  aes(landscape_ix, score, color = instructions) +
  geom_line(aes(group = subj_id), size = 0.2) +
  geom_line(aes(group = instructions), stat = "summary", fun.y = "mean", size = 2) +
  t_$theme +
  theme(legend.position = "bottom")

# strategies ----
Strategies <- Gems %>%
  filter(landscape_ix != 0, team_trial == 39) %>%
  label_team_strategy() %>%
  recode_team_strategy() %>%
  mutate(distance_to_peak = distance_to_peak(selected_x, selected_y))

strategies_plot <- ggplot(Strategies) +
  aes(team_strategy_label, score) +
  geom_bar(aes(fill = team_strategy_label),
           stat = "summary", fun.y = "mean",
           alpha = 0.4) +
  geom_point(aes(color = team_strategy_label),
             position = position_jitter(width = 0.2, height = 0)) +
  coord_cartesian(ylim = c(0, 100), expand = FALSE) +
  t_$scale_color_strategy +
  t_$scale_fill_strategy +
  t_$theme +
  guides(fill = "none", color = "none") +
  theme(
    panel.grid.major.x = element_blank()
  ) +
  labs(x = "")