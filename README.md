# Project 16: Evaluating a Policy to Combat Loan Default

## Context
A bank implemented a policy focused on reducing default through three main mechanisms:
- **Renegotiation and restructuring of existing debts**: offering longer terms, partial debt forgiveness, and reduced interest rates to delinquent clients;  
- **Conditional credit offers to clients with regular status**;  
- **Active monitoring and support** for clients at risk of default.  

**Side effect:** such policies may lead to excessive relaxation of credit criteria, granting credit to riskier clients and creating the opposite effect of what was intended.

---

## Business Problem
The central question is: **was the policy effective in reducing loan default?**

---

## Exploratory Data Analysis (EDA)

<img width="862" height="811" alt="image" src="https://github.com/user-attachments/assets/204bdd11-d5ef-4e51-b284-c1616b658f62" />

The variables appear to be well balanced for both groups, which is essential to ensure they do not determine the results.

---

## Problem Solution
To solve the problem, we used:
- **Difference-in-Differences (DiD):** to estimate the causal impact by capturing the pre- and post-policy periods;  
- **Propensity Score Matching (PSM):** to balance covariates that differ between treatment and control groups.  

**Dependent Variable:** `Default`  

**Covariates included in the models**:
- `Age`  
- `Income`  
- `Credit History`  
- `Number of Dependents`  
- `Time as Client`  

This combination allows us to estimate the causal effect of the policy while ensuring that results are not driven by biases.

> **Note:** for the diff-in-diff model to be valid, the **parallel trends assumption** must hold—meaning that, in the absence of treatment, the outcome variable would evolve similarly for both treatment and control groups. This assumption will be tested using a placebo effect.

---

## Results and Interpretation

<img width="860" height="707" alt="image" src="https://github.com/user-attachments/assets/f95b92e8-3cd9-4fb6-800d-4348f7695fa7" />

### Effect on default
- The interaction coefficient `treatment_dummy:post_dummy` from the model with covariates is **0.061** (significant, p < 0.001).  
- This indicates an **increase of 6.1 percentage points in default** in the treatment group due to the policy.  

### Financial impact
Considering:  
- Number of clients: 3,932  
- Average loss per defaulting client: R$ 1,500  

The estimated effect of the policy is:  
- **Additional defaulting clients**: 0.061 × 3,932 ≈ 240  
- **Estimated financial loss**: 240 × 1,500 ≈ **R$ 360,000**  

> In other words, the policy produced the opposite effect of what was intended, increasing defaults and causing direct financial losses for the bank.

### Robustness
Robustness checks confirm the result:  
- **PSM with caliper:** policy effect still positive (higher default)  
- **PSM with alternative variables:** similar effect  
- **Placebo test:** no effect detected in the pre-policy period, supporting the model’s validity.

---

## Conclusion
The policy **did not reduce loan default** and led to additional financial losses. The main reason is that renegotiation measures and credit concessions ended up relaxing risk criteria, allowing higher-risk clients to continue or resume borrowing, thereby increasing default rates.

---

## Tools
- Models estimated with `R` using packages: `dplyr`, `tidyr`, `MatchIt`, `fixest`, `ggplot2`, `broom`, `kableExtra`, `ggplot2`, `cowplot`
