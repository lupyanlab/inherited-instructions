# ---- inherited-instructions ----
library(tidyverse)
library(gems)

data("Gems")
data("SimpleHill")
data("Survey")
data("Instructions")
data("InstructionsCoded")
data("Bots")

t_ <- get_theme()

TestLandscapeCurrentScores <- SimpleHill %>%
  transmute(current_x = x, current_y = y, current_score = score)
TestLandscapeGemScores <- SimpleHill %>%
  transmute(gem_x = x, gem_y = y, gem_score = score)

Gems <- Gems %>%
  filter(version == 1.3) %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos) %>%
  recode_generation()

Bots <- Bots %>%
  filter(trial < 80) %>%
  mutate_distance_2d() %>%
  left_join(TestLandscapeCurrentScores) %>%
  melt_trial_stims() %>%
  left_join(TestLandscapeGemScores) %>%
  rank_stims_in_trial() %>%
  filter(selected == gem_pos)

BotsMirror <- bind_rows(
  `1` = Bots,
  `2` = Bots,
  .id = "block_ix_chr"
) %>%
  mutate(block_ix = as.integer(block_ix_chr)) %>%
  select(-block_ix_chr)

GemsFinal <- Gems %>%
  group_by(generation, subj_id, block_ix) %>%
  filter(trial == max(trial)) %>%
  ungroup()

BotsFinal <- Bots %>%
  filter(trial == 79) %>%
  group_by(simulation_type, block_ix) %>%
  summarize(score = mean(score)) %>%
  ungroup()

InstructionsCoded <- InstructionsCoded %>%
  filter(name == "pierce") %>%
  drop_na(score)

InstructionsSummarized <- InstructionsCoded %>%
  filter(name == "pierce") %>%
  group_by(subj_id) %>%
  summarize(instructions_score = sum(score)) %>%
  recode_instructions_score()

GemsCoded <- left_join(GemsFinal, InstructionsSummarized) %>%
  drop_na(instructions_score)

InheritanceMap <- select(Gems, subj_id, generation, inherit_from) %>% unique()
InheritanceMap <- left_join(InheritanceMap, InstructionsSummarized)

Gen1 <- InheritanceMap %>%
  filter(generation == 1) %>%
  select(-inherit_from, -generation) %>%
  rename(inherit_from = subj_id)

Gen2 <- InheritanceMap %>%
  filter(generation == 2) %>%
  select(-instructions_score, -instructions_label)

InheritanceMap <- left_join(Gen1, Gen2) %>%
  recode_instructions_score()

Gen2Block1 <- Gems %>%
  filter(generation == 2, block_ix == 1) %>%
  left_join(InheritanceMap) %>%
  drop_na(instructions_score)

Gen1Block1 <- Gems %>%
  filter(generation == 1, block_ix == 1)

Gen1Block2 <- Gems %>%
  filter(generation == 1, block_ix == 2)

subj_map <- select(Gems, subj_id, version, generation) %>% unique() %>% drop_na()
inheritance_map <- select(Gems, subj_id, version, generation, inherit_from) %>% unique() %>% drop_na()

Survey <- Survey %>%
  left_join(subj_map) %>%
  filter(version == 1.3) %>%
  recode_generation()

Instructions <- left_join(Instructions, subj_map) %>%
  select(subj_id, version, generation, instructions) %>%
  filter(version == 1.3)

# * positions ----
positions_plot <- ggplot(Gems) +
  aes(x = current_x, y = current_y, xend = selected_x, yend = selected_y) +
  geom_segment(aes(group = subj_id, color = generation_f)) +
  facet_wrap("block_ix", nrow = 1) +
  scale_x_continuous(breaks = seq(0, 70, by = 10)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  annotate("point", x = 50, y = 50, shape = 4, size = 3) +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines")) +
  labs(x = "orientation", y = "bar width") +
  coord_cartesian(xlim = c(0, 70), ylim = c(0, 70), expand = FALSE)

# * scores ----
scores_plot <- ggplot(Gems) +
  aes(trial, score) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  geom_line(aes(group = simulation_type), stat = "summary", fun.y = "mean", color = "gray",
            data = BotsMirror, size = 1, linetype = "twodash") +
  scale_color_discrete("Generation") +
  facet_wrap("block_ix", nrow = 1) +
  t_$theme +
  theme(legend.position = "top",
        panel.spacing.x = unit(1, "lines"))

# * distance ----
distance_plot <- ggplot(Gems) +
  aes(trial, distance_2d) +
  geom_line(aes(group = generation_f, color = generation_f),
            stat = "summary", fun.y = "mean",
            size = 2, show.legend = FALSE) +
  geom_line(aes(group = simulation_type), stat = "summary", fun.y = "mean", color = "gray", linetype = "twodash",
            data = Bots, size = 1) +
  geom_hline(yintercept = 0, linetype = 2) +
  facet_wrap("block_ix", nrow = 1) +
  scale_y_reverse("distance to 2D peak", breaks = seq(-20, 50, by = 10)) +
  coord_cartesian(expand = FALSE) +
  t_$theme +
  theme(legend.position = "bottom",
        panel.spacing.x = unit(1, "lines"))

# * final ----

final_scores_plot <- ggplot(GemsFinal) +
  aes(factor(block_ix), score) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  geom_line(aes(group = simulation_type),
            data = BotsFinal, color = "gray", linetype = "twodash", size = 2) +
  scale_color_discrete("Generation") +
  xlab("block") +
  ylab("final score") +
  t_$theme +
  theme(legend.position = "bottom")

final_distances_plot <- ggplot(GemsFinal) +
  aes(block_ix, distance_2d) +
  geom_line(aes(group = subj_id, color = generation_f), size = 0.2) +
  geom_line(aes(group = generation_f, color = generation_f), stat = "summary", fun.y = "mean", size = 2) +
  xlab("block") +
  scale_y_reverse("distance to 2d peak") +
  geom_hline(yintercept = 0, linetype = 2) +
  t_$theme +
  theme(legend.position = "bottom")

# * instructions ----
instructions_coded_plot <- ggplot(InstructionsCoded) +
  aes(factor(dimension)) +
  geom_bar(aes(fill = factor(score)), stat = "count", position = "stack") +
  scale_fill_discrete("Instructions score", labels = c("Didn't mention", "Incomplete or inaccurate", "Correct")) +
  xlab("")

instructions_summarized_plot <- ggplot(InstructionsSummarized) +
  aes(instructions_label, y = ..count..) +
  geom_bar(aes(fill = instructions_label)) +
  scale_x_discrete("") +
  scale_y_continuous("") +
  coord_flip()

instruction_quality_and_performance_plot <- ggplot(filter(GemsCoded, generation == 1, block_ix == 1)) +
  aes(instructions_label, score) +
  geom_point(aes(color = instructions_label), position = position_jitter(width = 0.1))

# * versus no instructions ----
instructions_versus_no_instructions_plot <- ggplot() +
  aes(trial, score) +
  geom_line(aes(color = instructions_label), data = Gen2Block1,
            stat = "summary", fun.y = "mean") +
  geom_line(aes(group = 1), data = Gen1Block1, stat = "summary", fun.y = "mean") +
  scale_color_discrete("") +
  guides(color = guide_legend(reverse = TRUE))

# * versus one block ----
instructions_versus_one_block_plot <- ggplot() +
  aes(trial, score) +
  geom_line(aes(color = instructions_label), data = Gen2Block1,
            stat = "summary", fun.y = "mean") +
  geom_line(aes(group = 1), data = Gen1Block2, stat = "summary", fun.y = "mean") +
  scale_color_discrete("") +
  guides(color = guide_legend(reverse = TRUE))
