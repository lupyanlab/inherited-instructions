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
  filter(version %in% c(1.3, 1.4), landscape_name == "SimpleHill") %>%
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

InstructionsSummarized <- InstructionsCoded %>%
  group_by(subj_id) %>%
  summarize(instructions_score = sum(score)) %>%
  recode_instructions_score()

GemsCoded <- left_join(Gems, InstructionsSummarized) %>%
  drop_na(instructions_score)

GemsFinalCoded <- left_join(GemsFinal, InstructionsSummarized) %>%
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

Gen2Block2 <- Gems %>%
  filter(generation == 2, block_ix == 2) %>%
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
  filter(version %in% c(1.3, 1.4)) %>%
  recode_generation()

Instructions <- left_join(Instructions, subj_map) %>%
  select(subj_id, version, generation, instructions) %>%
  filter(version %in% c(1.3, 1.4))

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
  coord_flip() +
  theme(legend.position = "none")

instruction_quality_and_performance_plot <- ggplot(filter(GemsCoded, generation == 1)) +
  aes(trial, score, color = instructions_label) +
  geom_line(stat = "summary", fun.y = "mean") +
  xlab("") +
  scale_color_discrete("") +
  guides(color = guide_legend(reverse = TRUE)) +
  t_$theme +
  theme(legend.position = c(0.8, 0.28))

instruction_quality_and_final_performance_plot <- ggplot(filter(GemsFinalCoded, generation == 1, block_ix == 1)) +
  aes(instructions_label, score) +
  geom_point(aes(color = instructions_label), position = position_jitter(width = 0.1)) +
  labs(x = "", y = "final score in block 1") +
  t_$theme +
  theme(legend.position = "none",
        axis.text.x = element_text(angle=45, hjust=1))

# * versus no instructions ----

library(lme4)
recode_block <- function(frame) {
  map <- data_frame(block_ix = c(1, 2), block_c = c(-0.5, 0.5))
  if(missing(frame)) return(map)
  left_join(frame, map)
}

recode_trial_poly <- function(frame) {
  map <- data_frame(
    trial = 1:79,
    trial_z = (trial - mean(trial))/sd(trial),
    trial_z_sqr = trial_z^2,
    trial_z_cub = trial_z^3
  )
  if(missing(frame)) return(map)
  left_join(frame, map)
}

Gems <- Gems %>%
  recode_block() %>%
  recode_trial_poly()

block1_mod <- lmer(score ~ generation_c * (trial_z + trial_z_sqr + trial_z_cub) + 
                     (trial_z + trial_z_sqr + trial_z_cub|subj_id),
                   data = filter(Gems, block_ix == 1))

block1_preds <- expand.grid(generation = c(1, 2), trial = 1:78) %>%
  recode_trial_poly() %>%
  recode_generation() %>%
  cbind(., AICcmodavg::predictSE(block1_mod, newdata = ., se = TRUE)) %>%
  rename(score = fit, se = se.fit)

block2_mod <- lmer(score ~ generation_c * (trial_z + trial_z_sqr + trial_z_cub) + (trial_z + trial_z_sqr + trial_z_cub|subj_id),
                   data = filter(Gems, block_ix == 2))

block2_preds <- expand.grid(generation = c(1, 2), trial = 1:78) %>%
  recode_trial_poly() %>%
  recode_generation() %>%
  cbind(., AICcmodavg::predictSE(block2_mod, newdata = ., se = TRUE)) %>%
  rename(score = fit, se = se.fit)

labels <- Gems %>%
  filter(trial == 79) %>%
  group_by(generation, block_ix) %>%
  summarize(score = mean(score)) %>%
  ungroup() %>%
  mutate(
    trial = 80,
    label = c("Gen1Block1", "Gen1Block2", "Gen2Block1", "Gen2Block2"),
    generation = c(1, 1, 2, 2),
    block_ix = c(1, 2, 1, 2)
  ) %>%
  recode_generation()

score_by_generation_plot <- ggplot(Gems) +
  aes(trial, score) +
  geom_line(aes(group = interaction(generation, block_ix),
                color = generation_f,
                linetype = factor(block_ix)),
            stat = "summary", fun.y = "mean") +
  geom_smooth(aes(ymin = score - se, ymax = score + se, group = generation_f, fill = generation_f),
              data = block1_preds, stat = "identity", color = NA, show.legend = FALSE) +
  # geom_smooth(aes(ymin = score - se, ymax = score + se, group = generation_f, fill = generation_f),
  #             data = block2_preds, stat = "identity", color = NA, show.legend = FALSE,
  #             alpha = 0.2) +
  geom_text(aes(label = label, color = generation_f), data = labels, hjust = 0,
            show.legend = FALSE) +
  scale_x_continuous(breaks = seq(0, 80, by = 10)) +
  scale_color_discrete("Generation") +
  scale_linetype_manual("Block", values = c("solid", "longdash")) +
  coord_cartesian(xlim = c(0, 100)) +
  theme(
    legend.position = c(0.8, 0.3)
  )

instructions_versus_no_instructions_plot <- ggplot() +
  aes(trial, score) +
  geom_line(aes(color = instructions_label), data = Gen2Block1,
            stat = "summary", fun.y = "mean") +
  geom_line(aes(group = 1), data = Gen1Block1, stat = "summary", fun.y = "mean") +
  scale_color_discrete("") +
  guides(color = guide_legend(reverse = TRUE))

Block1Diff <- bind_rows(
  left_join(Gen1Block1, InstructionsSummarized),
  Gen2Block1
) %>%
  group_by(generation, instructions_label, trial) %>%
  summarize(score = mean(score)) %>%
  ungroup() %>%
  group_by(instructions_label, trial) %>%
  summarize(diff = score[generation == 2] - score[generation == 1]) %>%
  ungroup()

diff_plot <- ggplot(Block1Diff) +
  aes(trial, diff) +
  geom_line(aes(color = instructions_label)) +
  geom_hline(yintercept = 0, linetype = "dotted") +
  scale_color_discrete("") +
  guides(color = guide_legend(reverse = TRUE))

overall_diff_plot <- ggplot(Block1Diff) +
  aes(instructions_label, diff) +
  geom_bar(aes(fill = instructions_label), stat = "summary", fun.y = "mean", alpha = 0.3,
           show.legend = FALSE) +
  geom_point(aes(color = instructions_label), position = position_jitter(width=0.1, height=0)) +
  geom_hline(yintercept = 0, linetype = "dotted") +
  scale_x_discrete("") +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45))
