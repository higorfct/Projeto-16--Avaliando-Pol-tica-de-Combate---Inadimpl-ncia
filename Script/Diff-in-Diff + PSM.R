# ============================================================
# 1. CARREGAR PACOTES
# ============================================================
library(dplyr)       # Manipulação de dados
library(tidyr)       # Transformação de formato (wide ↔ long)
library(ggplot2)     # Visualizações
library(MatchIt)     # Propensity Score Matching
library(fixest)      # Modelos econométricos, Diff-in-Diff
library(cowplot)     # Combinar gráficos
library(readxl)      # Ler arquivos Excel

# ============================================================
# 2. IMPORTAR DADOS
# ============================================================
data <- read_excel("dados_inadimplencia.xlsx")  # Lê a base wide (uma linha por cliente)
View(data)  # Apenas para inspeção inicial

# ============================================================
# 3. ANÁLISE EXPLORATÓRIA
# ============================================================
# Histogramas para comparar variáveis entre grupos antes do matching
p1 <- ggplot(data, aes(x = idade, fill = grupo)) +
  geom_histogram(position = "dodge", bins = 30) +
  labs(title = "Distribuição de Idade por Grupo")

p2 <- ggplot(data, aes(x = renda, fill = grupo)) +
  geom_histogram(position = "dodge", bins = 30) +
  labs(title = "Distribuição de Renda por Grupo")

p3 <- ggplot(data, aes(x = historico_credito, fill = grupo)) +
  geom_histogram(position = "dodge", bins = 30) +
  labs(title = "Distribuição de Histórico de Crédito por Grupo")

plot_grid(p1, p2, p3, ncol = 1)  # Combina os gráficos

# ============================================================
# 4. TRANSFORMAÇÃO PARA FORMATO DE PAINEL (long)
# ============================================================
data_long <- data %>%
  select(cliente_id, grupo, idade, renda, historico_credito, dependentes, tempo_cliente,
         periodo_antes, periodo_depois) %>%
  pivot_longer(
    cols = starts_with("periodo"),         # Coloca periodo_antes e periodo_depois em uma única coluna
    names_to = "periodo",                  # Nome da nova coluna de período
    values_to = "inadimplencia"             # Nome da coluna com valores de inadimplência
  ) %>%
  mutate(
    depois_dummy = ifelse(periodo == "periodo_depois", 1, 0),  # 1 se pós-política
    tratamento_dummy = ifelse(grupo == "tratamento", 1, 0)     # 1 se no grupo tratado
  )

# ============================================================
# 5. PROPENSITY SCORE MATCHING (antes da política)
# ============================================================
psm_model <- matchit(
  tratamento_dummy ~ idade + renda + historico_credito + dependentes + tempo_cliente, 
  data = data_long %>% filter(depois_dummy == 0),  # Matching só no período antes
  method = "nearest",  # Pareamento vizinho mais próximo
  ratio = 1            # Um controle para cada tratado
)

matched_data <- match.data(psm_model)   # Extrai dados pareados
matched_ids <- matched_data$cliente_id  # Pega IDs pareados

# Mantém apenas os IDs que foram pareados
data_matched_long <- data_long %>% filter(cliente_id %in% matched_ids)

# ============================================================
# 6. ESTIMAÇÃO DIFF-IN-DIFF
# ============================================================
diff_model <- feols(
  inadimplencia ~ tratamento_dummy * depois_dummy + idade + renda +
    historico_credito + dependentes + tempo_cliente,
  data = data_matched_long
)
summary(diff_model)  # O coef. da interação é o efeito causal estimado

# ============================================================
# 7. VISUALIZAÇÃO DO EFEITO
# ============================================================
effect_plot <- data_matched_long %>%
  group_by(grupo, periodo) %>%
  summarise(taxa_inadimplencia = mean(inadimplencia), .groups = "drop") %>%
  ggplot(aes(x = periodo, y = taxa_inadimplencia, color = grupo, group = grupo)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(title = "Taxa de Inadimplência por Grupo e Período",
       x = "Período", y = "Taxa média de inadimplência")

print(effect_plot)

# ============================================================
# 8. TESTES DE ROBUSTEZ COMPLETO
# ============================================================

## 8.1 Caliper Matching
psm_caliper <- matchit(
  tratamento_dummy ~ idade + renda + historico_credito + dependentes + tempo_cliente, 
  data = data_long %>% filter(depois_dummy == 0),
  method = "nearest", caliper = 0.1
)
summary(psm_caliper)  # Ver balanceamento

# Extrai dados pareados
matched_caliper <- match.data(psm_caliper)
data_caliper_long <- data_long %>% filter(cliente_id %in% matched_caliper$cliente_id)

# Diff-in-Diff sobre dados pareados com caliper
robust_model1 <- feols(
  inadimplencia ~ tratamento_dummy * depois_dummy + idade + renda +
    historico_credito + dependentes + tempo_cliente,
  data = data_caliper_long
)
summary(robust_model1)  # Coef. da interação = efeito da política

## 8.2 Matching com variáveis alternativas
psm_alt <- matchit(
  tratamento_dummy ~ idade + historico_credito + dependentes,
  data = data_long %>% filter(depois_dummy == 0),
  method = "nearest"
)
summary(psm_alt)  # Ver balanceamento

# Extrai dados pareados
matched_alt <- match.data(psm_alt)
data_alt_long <- data_long %>% filter(cliente_id %in% matched_alt$cliente_id)

# Diff-in-Diff sobre dados pareados com variáveis alternativas
robust_model2 <- feols(
  inadimplencia ~ tratamento_dummy * depois_dummy + idade +
    historico_credito + dependentes,
  data = data_alt_long
)
summary(robust_model2)  # Coef. da interação = efeito da política

## 8.3 Placebo test (apenas pré-política)
placebo_data <- data_long %>% filter(periodo == "periodo_antes")
placebo_model <- feols(
  inadimplencia ~ tratamento_dummy * depois_dummy + idade + renda +
    historico_credito + dependentes + tempo_cliente,
  data = placebo_data
)
summary(placebo_model)  # Se der efeito, pode haver viés
--------------------------------------------------------------------------------

## Parte 2 - Resumindo os Resultados em uma tabela 

library(broom)       # Converte modelos estatísticos em data frames tidy, facilitando a extração de coeficientes, erros padrão e p-values
library(dplyr)       # Permite manipulação de dados de forma intuitiva (filtros, seleções, agrupamentos, junções)
library(kableExtra)  # Gera tabelas bonitas e formatadas, compatíveis com GitHub, HTML e PDF


# Supondo que diff_model seja o modelo Diff-in-Diff com covariáveis
# Transformar os coeficientes em um tibble
coef_table <- tidy(diff_model) %>%
  select(term, estimate, p.value) %>%
  mutate(
    interpretacao = case_when(
      term == "(Intercept)" ~ "Taxa média inadimplência grupo controle antes da política",
      term == "tratamento_dummy" ~ "Diferença inicial entre grupos antes da política",
      term == "depois_dummy" ~ "Mudança no grupo controle após a política",
      term == "idade" ~ "Idade não influencia significativamente",
      term == "renda" ~ "Renda não significativa",
      term == "historico_credito" ~ "Histórico de crédito não significativo",
      term == "dependentes" ~ "Mais dependentes → maior inadimplência",
      term == "tempo_cliente" ~ "Tempo como cliente não significativo",
      term == "tratamento_dummy:depois_dummy" ~ "Efeito causal da política: aumento da inadimplência",
      TRUE ~ ""
    )
  )

# Criar tabela compacta
coef_table %>%
  kable(
    col.names = c("Variável", "Estimativa", "p-valor", "Interpretação rápida"),
    digits = 4,
    caption = "Resumo dos resultados com modelo Diff-in-Diff e testes de robustez"
  ) %>%
  kable_styling(full_width = F, position = "center", bootstrap_options = c("striped", "hover"))








