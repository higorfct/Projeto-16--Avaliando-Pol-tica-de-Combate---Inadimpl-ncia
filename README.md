# Projeto 16: Avaliando uma Política de Combate à Inadimplência

## Contexto
Um banco implementou uma política focada em reduzir a inadimplência através de três mecanismos principais:
- **Renegociação e reestruturação de dívidas existentes**: oferecer prazos maiores, perdão parcial de dívidas e juros reduzidos a clientes inadimplentes;
- **Oferta de crédito condicionada a clientes com status regular**;
- **Monitoramento e suporte ativo** a clientes com risco de inadimplência.

**Efeito colateral:** tais políticas podem gerar relaxamento excessivo dos critérios de crédito, oferecendo crédito a clientes de maior risco e gerando efeito contrário ao desejado.

---
## Problema de Negócio
A pergunta central é: **a política foi efetiva em diminuir a inadimplência?**

---

## Análise Exploratória de Dados (EDA)

<img width="862" height="811" alt="image" src="https://github.com/user-attachments/assets/204bdd11-d5ef-4e51-b284-c1616b658f62" />

As variáveis parecem estar bem equilibradas para ambos os grupos, o que é essencial para garantir que não determinem os resultados. 

---

## Solução do Problema
Para solucionar o problema , utilizamos:
- **Diff-in-Diff (DiD)**: para estimar o impacto causal capturando os períodos anterior e posterior à política;
- **Propensity Score Matching (PSM)**: para balancear covariáveis que diferem entre grupos de tratamento e controle.

**Variável Dependente:** `Inadimplência`
  
**Covariáveis incluídas nos modelos**:
- `Idade`
- `Renda`
- `Histórico de Crédito`
- `Número de Dependentes`
- `Tempo como Cliente`
  
Essa combinação permite estimar o efeito causal da política garantindo que os resultados não sejam influenciados por quaisquer vieses.

OBS: para que o modelo diff-in-diff seja válido, é necessário que a hipótese de tendências paralelas - de que na ausência do tratamento os valores da variável de interesse sejam os mesmos para os grupos de tratamento e controle - seja atendida. Esta hipótese será testada com efeito placebo.

---

## Resultados e Interpretação

<img width="860" height="707" alt="image" src="https://github.com/user-attachments/assets/f95b92e8-3cd9-4fb6-800d-4348f7695fa7" />



### Efeito sobre inadimplência
- O coeficiente de interação `tratamento_dummy:depois_dummy` do modelo com covariáveis é **0,061** (significativo, p < 0,001).  
- Isso indica um aumento de **6,1 pontos percentuais na inadimplência** no grupo de tratamento devido à política.

### Impacto financeiro
Considerando:
- Número de clientes: 3.932  
- Prejuízo médio por cliente inadimplente: R$ 1.500  

O efeito estimado da política é:
- **Clientes inadimplentes adicionais**: 0,061 × 3.932 ≈ 240  
- **Prejuízo financeiro estimado**: 240 × 1.500 ≈ **R$ 360.000**

> Ou seja, a política gerou efeito contrário ao esperado, aumentando a inadimplência e causando prejuízo direto ao banco.

### Robustez
Testes de robustez confirmam o resultado:
- **PSM com caliper**: efeito da política ainda positivo (inadimplência aumentada)  
- **PSM com variáveis alternativas**: efeito similar  
- **Placebo test**: nenhum efeito detectado no período anterior à política, indicando validade do modelo.

---

## Conclusão
A política **não reduziu a inadimplência** e gerou prejuízos financeiros adicionais. A principal razão é que medidas de renegociação e concessão de crédito acabaram relaxando critérios de risco, permitindo que clientes de maior risco continuassem ou voltassem a tomar crédito, aumentando a inadimplência.

---

## Ferramentas
- Modelos estimados com `R` usando pacotes: `dplyr`, `tidyr`, `MatchIt`, `fixest`, `ggplot2`, `broom`,  `kableExtra`, `ggplot2`, `cowplot`
