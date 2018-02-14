# ---- mountain-climbers-setup
library(tidyverse)
library(plotly)
library(magrittr)
library(gridExtra)

library(totems)
library(mountainclimbers)
library(crotchet)

library(RColorBrewer)
base_theme <- theme_minimal()

theme_colors <- brewer.pal(4, "Set2")
names(theme_colors) <- c("green", "orange", "blue", "pink")
get_theme_color_values <- function(names) theme_colors[names] %>% unname()

scale_color_strategy <- scale_color_manual(
  "strategy",
  labels = c("diachronic", "synchronic"),
  values = get_theme_color_values(c("blue", "green"))
)
scale_fill_strategy <- scale_fill_manual(
  "strategy",
  labels = c("diachronic", "synchronic"),
  values = get_theme_color_values(c("blue", "green"))
)

scale_color_team_label <- scale_color_manual(
  "skill overlap",
  labels = c("4 disjoint", "3", "2 overlapping", "1", "0 identical"),
  values = brewer.pal(7, "BuGn")[7:3]
)
scale_alpha_team <- scale_alpha_discrete(
  "skill overlap",
  labels = c("4 disjoint", "3", "2 overlapping", "1", "0 identical"),
  range = c(1.0, 0.3)
)

scale_y_fitness_pct <- scale_y_continuous("fitness", labels = scales::percent)
scale_x_strategy_rev <- scale_x_discrete("strategy", labels = c("synchronic", "diachronic"))


# Vision of 1 gives a visible range of 3 (from -1 to 1)
visible_range <- function(vision) -vision:vision

# Vision in two dimensions is a search area
calculate_player_search_area <- function(vision_x, vision_y) {
  expand.grid(x = visible_range(vision_x),
              y = visible_range(vision_y)) %>%
    mutate(vision_x = vision_x, vision_y = vision_y) %>%
    select(vision_x, vision_y, x, y)
}

calculate_team_search_area <- function(p1_vision_x, p1_vision_y,
                                       p2_vision_x, p2_vision_y) {
  expand.grid(
    p1_x = visible_range(p1_vision_x),
    p1_y = visible_range(p1_vision_y),
    p2_x = visible_range(p2_vision_x),
    p2_y = visible_range(p2_vision_y)
  ) %>% mutate(
    p1_vision_x = p1_vision_x,
    p1_vision_y = p1_vision_y,
    p2_vision_x = p2_vision_x,
    p2_vision_y = p2_vision_y,
    x = p1_x + p2_x,
    y = p1_y + p2_y
  ) %>%
    select(p1_vision_x, p1_vision_y, p2_vision_x, p2_vision_y, x, y)
}
