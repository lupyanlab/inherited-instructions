library(devtools)
library(tidyverse)
source("R/mountain-climbers.R")

get_experiment_data <- function(experiment) {
  file.path("data-raw", paste0(experiment, ".csv")) %>%
    read_csv() %>%
    recode_fitness_as_pct() %>%
    mutate(sim_id = paste(exp_id, sim_id, sep = ":"))
}

identical_team <- get_experiment_data("identical-team") %>%
  extract_position() %>%
  recode_strategy()

differing_skills <- get_experiment_data("differing-skills") %>%
  recode_team() %>%
  extract_position()

solo_teams <- get_experiment_data("solo-teams") %>%
  recode_team()

exchange_rate_strategies <- c("diachronic", "diachronic_2", "diachronic_3", "diachronic_4", "diachronic_max")
exchange_rate_labels <- c(1:4, "max")
exchange_rate_map <- data_frame(
  strategy = exchange_rate_strategies,
  exchange_rate = factor(exchange_rate_strategies, levels = exchange_rate_strategies,
                         labels = exchange_rate_labels)
)

alternating <- get_experiment_data("alternating") %>%
  left_join(exchange_rate_map)

aggregate_fns <- get_experiment_data("aggregate-functions")
variable_feedback <- get_experiment_data("variable-feedback")

omniscient <- get_experiment_data("omniscient")

use_data(
  identical_team,
  differing_skills,
  solo_teams,
  alternating,
  aggregate_fns,
  variable_feedback,
  omniscient,
  overwrite = TRUE
)


SimpleHill <- read_csv("data-raw/simple-hill.csv")
use_data(SimpleHill, overwrite = TRUE)
