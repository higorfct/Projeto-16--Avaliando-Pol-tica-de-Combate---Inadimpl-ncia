# ============================================================
# 1. LOADING PACKAGES
# ============================================================
library(dplyr)       # Data manipulation
library(tidyr)       # Data reshaping (wide ↔ long)
library(ggplot2)     # Visualizations
library(MatchIt)     # Propensity Score Matching
library(fixest)      # Econometric models, Diff-in-Diff
library(cowplot)     # Combine plots
library(readxl)      # Read Excel files
library(broom)       #tidy model output
library(kableExtra)  # Pretty tables
# ============================================================
# 2. IMPORTING DATA
# ============================================================
data <- read_excel("data_delinquency.xlsx")  # Reads the wide dataset (one row per client)
View(data)  # Initial inspection only

# ============================================================
# 3. EXPLORATORY ANALYSIS
# ============================================================
# Histograms to compare variables between groups before matching
p1 <- ggplot(data, aes(x = age, fill = group)) +
  geom_histogram(position = "dodge", bins = 30) +
  labs(title = "Age Distribution by Group")

p2 <- ggplot(data, aes(x = income, fill = group)) +
  geom_histogram(position = "dodge", bins = 30) +
  labs(title = "Income Distribution by Group")

p3 <- ggplot(data, aes(x = credit_history, fill = group)) +
  geom_histogram(position = "dodge", bins = 30) +
  labs(title = "Credit History Distribution by Group")

plot_grid(p1, p2, p3, ncol = 1)  # Combine plots

# ============================================================
# 4. TRANSFORMATION TO PANEL FORMAT (long)4
# ============================================================
data_long <- data %>%
  select(client_id, group, age, income, credit_history, dependents, client_time,
         period_before, period_after) %>%
  pivot_longer(
    cols = starts_with("period"),       # Put period_before and period_after into one column
    names_to = "period",                # Name of the new period column
    values_to = "delinquency"           # Column with default values
  ) %>%
  mutate(
    after_dummy = ifelse(period == "period_after", 1, 0),     # 1 if post-policy
    treatment_dummy = ifelse(group == "treatment", 1, 0)      # 1 if in treatment group
  )


# ============================================================
# 5. PROPENSITY SCORE MATCHING (pre-policy rows only)
# ============================================================
psm_model <- matchit(
  treatment_dummy ~ age + income + credit_history + dependents + client_time,
  data = data_long %>% filter(after_dummy == 0),  # matching on pre-policy observations
  method = "nearest",
  ratio = 1
)

matched_data <- match.data(psm_model)   # matched dataset from MatchIt
matched_ids  <- matched_data$client_id  # matched client IDs

# Keep only matched clients in the long format
data_matched_long <- data_long %>% filter(client_id %in% matched_ids)
summary(psm_model)
# ============================================================
# 6. DIFF-IN-DIFF ESTIMATION
# ============================================================
diff_model <-feols(delinquency ~ treatment_dummy * after_dummy + age + income +
                     credit_history + dependents + client_time,
                   data = data_matched_long

)
summary(diff_model)  # interaction coef = estimated causal effect

# ============================================================
# 7. VISUALIZING THE EFFECT
# ============================================================
effect_plot <- data_matched_long %>%
  group_by(group, period) %>%
  summarise(default_rate = mean(delinquency, na.rm = TRUE), .groups = "drop") %>%
  ggplot(aes(x = period, y = default_rate, color = group, group = group)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(title = "Delinquency Rate by Group and Period",
       x = "Period", y = "Average Default Rate")

print(effect_plot)

# ============================================================
# 8. ROBUSTNESS CHECKS
# ============================================================

## 8.1 Caliper Matching
psm_caliper <- matchit(
  treatment_dummy ~ age + income + credit_history + dependents + client_time,
  data = data_long %>% filter(after_dummy == 0),
  method = "nearest",
  caliper = 0.1
)
summary(psm_caliper)

matched_caliper <- match.data(psm_caliper)
data_caliper_long <- data_long %>% filter(client_id %in% matched_caliper$client_id)

robust_model1 <- feols(
  delinquency ~ treatment_dummy * after_dummy + age + income +
    credit_history + dependents + client_time,
  data = data_caliper_long
)
summary(robust_model1)

## 8.2 Matching with alternative variables
psm_alt <- matchit(
  treatment_dummy ~ age + credit_history + dependents,
  data = data_long %>% filter(after_dummy == 0),
  method = "nearest"
)
summary(psm_alt)

matched_alt <- match.data(psm_alt)
data_alt_long <- data_long %>% filter(client_id %in% matched_alt$client_id)

robust_model2 <- feols(
  delinquency ~ treatment_dummy * after_dummy + age + credit_history + dependents,
  data = data_alt_long
)
summary(robust_model2)

## 8.3 Placebo test (pre-policy only)
placebo_data <- data_long %>% filter(period == "period_before")
placebo_model <- feols(
  delinquency ~ treatment_dummy * after_dummy + age + income +
    credit_history + dependents + client_time,
  data = placebo_data
)
summary(placebo_model)

# ============================================================
# 9. SUMMARIZE COEFFICIENTS (table)
# ============================================================
coef_table <- tidy(diff_model) %>%
  select(term, estimate, p.value) %>%
  mutate(
    interpretation = case_when(
      term == "(Intercept)" ~ "Average delinquency rate for control group before policy",
      term == "treatment_dummy" ~ "Initial difference between groups before policy",
      term == "after_dummy" ~ "Change in control group after policy",
      term == "age" ~ "Age not significant",
      term == "income" ~ "Income not significant",
      term == "credit_history" ~ "Credit history not significant",
      term == "dependents" ~ "More dependents → higher delinquency",
      term == "client_time" ~ "Time as client not significant",
      term == "treatment_dummy:after_dummy" ~ "Causal effect of policy: increase in delinquency",
      TRUE ~ ""
    )
  )

coef_table %>%
  kable(
    col.names = c("Variable", "Estimate", "p-value", "Quick Interpretation"),
    digits = 4,
    caption = "Summary of results with Diff-in-Diff model and robustness tests"
  ) %>%
  kable_styling(full_width = F, position = "center", bootstrap_options = c("striped", "hover"))








