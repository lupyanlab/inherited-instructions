# ---- survey
library(tidyverse)
library(gems)
data("Survey")

questions <- data_frame(question_text = colnames(Survey)) %>%
  mutate(question_id = c("timestamp", "subj_id", "computer", "age", "gender", paste0("Q", 1:9))) %>%
  select(question_id, question_text)

colnames(Survey) <- questions$question_id
