# ---- inherited-diversity
library(plotly)
library(tidyverse)
library(magrittr)
library(lattice)

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
  coord_landscape = coord_equal(xlim = c(0, 99), ylim = c(0, 99)),
  scale_x_orientation = scale_x_continuous("Orientation"),
  scale_y_spatial_frequency = scale_y_continuous("Spatial frequency")
)

label_training <- function(frame) {
  frame %>% mutate(training = ifelse(landscape_ix == 0, "training", "test"))
}

recode_training <- function(frame) {
  labels <- c("training", "test")
  map <- data_frame(
    training = labels,
    training_label = factor(labels, levels = labels)
  )
  if(missing(frame)) return(map)
  left_join(frame, map)
}

recode_landscape <- function(frame) {
  labels <- c("SimpleHill", "ReverseOrientation", "ReverseSpatialFrequency", "ReverseBoth")
  map <- data_frame(
    landscape_name = labels,
    landscape_label = factor(labels, levels = labels)
  )
  if(missing(frame)) return(map)
  left_join(frame, map)
}

# ---- pilot
data("Pilot")

Pilot %<>%
  label_training() %>%
  recode_training() %>%
  recode_landscape()

# ---- gems
data("Gems")

Gems %<>%
  label_training() %>%
  recode_training() %>%
  recode_landscape() %>%
  arrange(subj_id, trial)