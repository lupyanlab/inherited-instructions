#' Create a list of theme elements
#' @import ggplot2
#' @import dplyr
#' @export
get_mountainclimbers_theme <- function() {
  theme_colors <- RColorBrewer::brewer.pal(4, "Set2")
  names(theme_colors) <- c("green", "orange", "blue", "pink")
  get_theme_color_values <- function(names) theme_colors[names] %>% unname()

  theme = list(
    base_theme = theme_minimal(),
    colors = theme_colors,
    scale_color_strategy = scale_color_manual(
      "Strategy",
      labels = c("Diachronic", "Synchronic"),
      values = get_theme_color_values(c("blue", "green"))
    ),
    scale_fill_strategy = scale_fill_manual(
      "Strategy",
      labels = c("Diachronic", "Synchronic"),
      values = get_theme_color_values(c("blue", "green"))
    ),
    scale_alpha_team = scale_alpha_discrete(
      "Skill overlap",
      labels = c("4 disjoint", "3", "2 overlapping", "1", "0 identical"),
      range = c(1.0, 0.3)
    ),
    scale_y_fitness_pct = scale_y_continuous(
      "Fitness", labels = scales::percent
    ),
    scale_x_strategy_rev = scale_x_discrete(
      "Strategy", labels = c("Synchronic", "Diachronic")
    )
  )

  theme
}
