# ---- peaks-setup
library(tidyverse)
library(plotly)
library(magrittr)
library(gridExtra)

library(totems)
library(peaks)
library(crotchet)

library(RColorBrewer)
library(lattice)

# Remove bounding box around all lattice plots.
# Also removes axis arrows!
trellis.par.set("axis.line",list(col=NA,lty=1,lwd=1))

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

# ---- peaks-methods ----

# * ability-as-vision ----
ability <- data_frame(vision = 1:9)

gg_single_dimension <- ggplot(ability) +
  aes(vision, vision) +
  geom_bar(aes(alpha = vision), stat = "identity", fill = theme_colors[["blue"]]) +
  scale_x_continuous("", breaks = NULL) +
  scale_y_continuous("vision", breaks = 1:9) +
  scale_alpha_continuous(range = c(0.5, 1.0)) +
  guides(alpha = "none") +
  coord_cartesian(xlim = c(1, 9.2), ylim = c(0, 9.6)) +
  base_theme +
  theme(
    panel.grid.minor.y = element_blank()
  ) +
  ggtitle("Vision in a single dimension")


data("differing_skills")
teams <- differing_skills %>%
  get_team_info() %>%
  gather(dimension, value, -c(team, player, team_id)) %>%
  recode_team() %>%
  select(-team)

legend_text <- data_frame(
  team_label_rev = factor(0, levels = 0:4),
  player = 1,
  value = c(0.1, 0.1),
  dimension = c("vision_x", "vision_y"),
  label = c("vision x", "vision y")
)

dodge_width <- position_dodge(width = 0.9)

tradeoffs_plot <- ggplot() +
  aes(x = player, y = value, group = dimension) +
  geom_bar(aes(fill = team_label_rev, alpha = dimension),
           stat = "identity", position = dodge_width) +
  facet_wrap("team_label_rev", nrow = 1) +
  geom_text(aes(label = label), data = legend_text, position = dodge_width,
            angle = 90, vjust = 0.75, hjust = 0) +
  scale_x_continuous(breaks = c(1, 2)) +
  scale_y_continuous("vision", breaks = 1:10, expand = c(0, 0)) +
  scale_fill_brewer(palette = "Set2") +
  scale_alpha_manual(values = c(0.9, 0.5)) +
  coord_cartesian(ylim = c(0, 9)) +
  base_theme +
  theme(
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank()
  )

gg_two_dimensions <- (tradeoffs_plot %+% filter(teams, player == 1)) +
  scale_x_continuous("", labels = NULL) +
  theme(strip.text = element_blank()) +
  coord_cartesian(xlim = c(0, 2))


gg_differing_skills <- (tradeoffs_plot %+% teams)

# * search-areas ----

# Vision of 1 gives a visible range of 3 (from -1 to 1)
visible_range <- function(vision) vision * 2 + 1

# Vision in two dimensions is a search area
calculate_search_area <- function(vision_x, vision_y) {
  search_area <- visible_range(vision_x) * visible_range(vision_y)
  return(search_area)
}

search_areas <- data_frame(
  vision_x = 5:1,
  vision_y = 5:9,
  search_area = calculate_search_area(vision_x, vision_y)
)

diachronic_team_search_areas <- search_areas %>%
  mutate(
    strategy = "diachronic",
    team_label_rev = factor(0:4)
  )

synchronic_team_search_areas <- data_frame(
  vision_x = 10, vision_y = 10,
  search_area = calculate_search_area(vision_x, vision_y),
  strategy = "synchronic",
  agg_func = "sum"
)

search_areas_by_strategy <- bind_rows(diachronic_team_search_areas,
                                      synchronic_team_search_areas) %>%
  mutate(vision_x_range = visible_range(vision_x),
         vision_y_range = visible_range(vision_y))

gg_search_areas <- ggplot() +
  aes(x = 0, y = 0, width = vision_y_range, height = vision_x_range,
      fill = team_label_rev) +
  geom_tile() +
  scale_x_continuous("vision x", labels = NULL) +
  scale_y_continuous("vision y", labels = NULL) +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  coord_cartesian(xlim = c(-10, 10), ylim = c(-10, 10)) +
  facet_wrap("team_label_rev", nrow = 1, scales = "fixed") +
  base_theme +
  theme(strip.text = element_blank())

gg_search_rects <- (gg_search_areas %+% filter(search_areas_by_strategy, strategy == "diachronic"))

# * search-areas-by-strategy ----
search_areas_by_strategy %<>%
  arrange(vision_y) %>%
  mutate(
    visions = paste0("(", vision_x, ",", vision_y, ")"),
    visions_f = factor(visions, levels = visions)
  )

gg_search_areas_by_strategy <- ggplot(search_areas_by_strategy) +
  aes(visions_f, search_area, fill = visions_f) +
  geom_bar(stat = "identity") +
  annotate("text", x = 6, y = 10, label = "all synchronic teams",
           hjust = -0.1, angle = 90) +
  scale_x_discrete("(vision x, vision y)") +
  scale_y_continuous("search area") +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  base_theme

# ---- peaks-experiments ----

# * identical-teammates ----
data("identical_team")

identical_team %<>%
  recode_fitness_as_pct() %>%
  recode_strategy() %>%
  extract_position()

gg_identical_team_timeline <- ggplot(identical_team) +
  aes(time, fitness_pct, color = strategy) +
  geom_line(stat = "summary", fun.y = "mean", size = 1.2) +
  scale_x_continuous("calendar hours") +
  scale_y_continuous("fitness", labels = scales::percent) +
  scale_color_manual(
    "strategy",
    labels = c("diachronic", "synchronic"),
    values = get_theme_color_values(c("blue", "green")),
    guide = guide_legend(reverse = TRUE)
  ) +
  base_theme +
  theme(legend.position = "top")

max_fitness <- identical_team %>%
  group_by(sim_id, strategy) %>%
  summarize(fitness_pct = max(fitness_pct)) %>%
  recode_strategy()

gg_identical_team_final_fitness <- ggplot(max_fitness) +
  aes(strategy_rev, fitness_pct) +
  geom_bar(aes(fill = strategy), stat = "summary", fun.y = "mean", alpha = 0.5) +
  geom_point(aes(color = strategy), alpha = 0.2,
             position = position_jitter(width = 0.2, height = 0.0)) +
  scale_x_strategy_rev +
  scale_y_fitness_pct +
  scale_color_manual(values = get_theme_color_values(c("blue", "green"))) +
  scale_fill_manual(values = get_theme_color_values(c("blue", "green"))) +
  base_theme +
  theme(legend.position = "none",
        panel.grid.major.x = element_blank())

# * random-walk-plot ----
set.seed(782)
sample_sim_ids <- identical_team %>%
  filter(exp_id == 1) %>%
  group_by(strategy, starting_pos) %>%
  sample_n(1) %>%
  .$sim_id

random_walk_plot <- ggplot(identical_team %>% filter(exp_id == 1)) +
  aes(pos_x, pos_y, group = sim_id, color = strategy) +
  geom_path(alpha = 0.2) +
  annotate("point", x = 0, y = 0, shape = 4) +
  annotate("point", x = -127.3, y = -127.3, shape = 1) +
  coord_equal() +
  facet_wrap("strategy_rev") +
  scale_x_continuous("", labels = NULL) +
  scale_y_continuous("", labels = NULL) +
  scale_color_strategy +
  base_theme +
  theme(legend.position = "none")

 # * differing-skills ----
data("differing_skills")

differing_skills %<>%
  recode_fitness_as_pct() %>%
  recode_team() %>%
  extract_position()

differing_skills %<>%
  filter(strategy == "diachronic")

gg_differing_skills_timeline <- ggplot(differing_skills) +
  aes(time, fitness_pct, alpha = team_label, color = strategy) +
  geom_line(stat = "summary", fun.y = "mean", size = 1.2) +
  scale_x_continuous("calendar hours") +
  scale_y_fitness_pct +
  scale_color_strategy +
  scale_alpha_team +
  guides(color = "none",
         alpha = guide_legend(order = 2)) +
  base_theme +
  theme(legend.position = c(0.8, 0.1))

max_fitness <- differing_skills %>%
  group_by(sim_id, strategy, team_label) %>%
  summarize(fitness_pct = max(fitness_pct)) %>%
  recode_strategy()

dodge_width <- 0.9
team_dodge <- position_dodge(width = dodge_width)
sim_dodge <- position_jitterdodge(dodge.width = dodge_width, jitter.width = 0.4)

gg_differing_skills_final_fitness <- ggplot(max_fitness) +
    aes(x = strategy, fitness_pct, alpha = team_label) +
    scale_y_fitness_pct +
    # geom_point(aes(color = strategy), position = sim_dodge) +
    geom_bar(aes(fill = strategy),
             stat = "summary", fun.y = "mean", position = team_dodge) +
    scale_alpha_team +
    scale_fill_strategy +
    guides(fill = "none") +
    base_theme +
    theme(panel.grid.major.x = element_blank())

gg_differing_skills_walk <- (random_walk_plot %+% filter(differing_skills, exp_id == 1)) +
  facet_wrap("team_label_rev", nrow = 1)

# * solo-teams ----
data("solo_teams")

solo_teams %<>%
  recode_fitness_as_pct() %>%
  recode_team()

gg_solo_teams_timeline <- ggplot(solo_teams) +
    aes(time, fitness_pct, alpha = team_label, color = strategy) +
    geom_line(stat = "summary", fun.y = "mean", size = 1.2) +
    scale_x_continuous("calendar hours") +
    scale_y_continuous("fitness", labels = scales::percent) +
    scale_color_manual("strategy", values = get_theme_color_values(c("blue", "green"))) +
    scale_alpha_team +
    guides(color = guide_legend(order = 1),
           alpha = guide_legend(order = 2)) +
    base_theme

max_fitness <- solo_teams %>%
  group_by(sim_id, strategy, team_label) %>%
  summarize(fitness_pct = max(fitness_pct))

gg_solo_teams_final_fitness <- (gg_differing_skills_final_fitness %+% max_fitness)

# * number-of-exchanges ----
data("alternating")

exchange_rate_strategies <- c("diachronic", "diachronic_2", "diachronic_3", "diachronic_4", "diachronic_max")
exchange_rate_labels <- c(1:4, "max")
exchange_rate_map <- data_frame(
  strategy = exchange_rate_strategies,
  exchange_rate = factor(exchange_rate_strategies, levels = exchange_rate_strategies,
                         labels = exchange_rate_labels)
)

alternating %<>%
  recode_fitness_as_pct() %>%
  left_join(exchange_rate_map)

# * aggregate ----
data("aggregate_fns")

aggregate_fns %<>%
  recode_fitness_as_pct()

gg_aggregate <- ggplot(aggregate_fns) +
  aes(time, fitness_pct, color = aggregate_fn) +
  geom_line(stat = "summary", fun.y = "mean", size = 1.2) +
  scale_x_continuous("calendar hours") +
  scale_y_continuous("fitness", labels = scales::percent) +
  scale_color_brewer("aggregate function", palette = "Set2") +
  base_theme

gg_alternating <- ggplot(alternating) +
  aes(time, fitness_pct, color = exchange_rate) +
  geom_line(stat = "summary", fun.y = "mean", size = 1.2) +
  scale_x_continuous("calendar hours") +
  scale_y_continuous("fitness", labels = scales::percent) +
  scale_color_brewer("exchanges", palette = "Set2", guide = guide_legend(reverse = TRUE)) +
  base_theme

# * variable-feedback ----
data("variable_feedback")

variable_feedback %<>%
  recode_fitness_as_pct()

feedback_trials_plot <- ggplot(variable_feedback) +
  aes(factor(strategy, levels = c("synchronic", "diachronic")), feedback, fill = strategy) +
  geom_bar(aes(alpha = factor(p_feedback, levels = c(0.1, 0.5, 1.0))),
           stat = "summary", fun.y = "sum", position = "dodge") +
  scale_x_discrete("strategy") +
  scale_y_continuous("feedback trials", labels = NULL) +
  scale_fill_manual(values = get_theme_color_values(c("blue", "green"))) +
  scale_alpha_discrete("prob feedback", labels = c("10%", "50%", "100%"), range = c(0.4, 1.0)) +
  base_theme

variable_feedback_plot <- ggplot(variable_feedback) +
  aes(time, fitness_pct, color = strategy, alpha = factor(p_feedback)) +
  geom_line(stat = "summary", fun.y = "mean", size = 1.2) +
  scale_x_continuous("calendar hours") +
  scale_y_continuous("fitness", labels = scales::percent) +
  scale_color_strategy +
  scale_alpha_discrete("prob feedback", labels = c("10%", "50%", "100%"), range = c(0.6, 1.0)) +
  guides(
    color = guide_legend(order = 1),
    alpha = guide_legend(order = 2, reverse = TRUE)
  ) +
  base_theme
