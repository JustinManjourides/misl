# Introduction to misl

## Overview

`misl` implements **Multiple Imputation by Super Learning**, a flexible
approach to handling missing data described in:

> Carpenito T, Manjourides J. (2022) MISL: Multiple imputation by super
> learning. *Statistical Methods in Medical Research*. 31(10):1904–1915.
> doi:
> [10.1177/09622802221104238](https://doi.org/10.1177/09622802221104238)

Rather than relying on a single parametric imputation model, `misl`
builds a stacked ensemble of machine learning algorithms for each
incomplete column, producing well-calibrated imputations for continuous,
binary, categorical, and ordered categorical variables.

## Installation

``` r

# Install from GitHub
remotes::install_github("JustinManjourides/misl")

# Optional backend packages for additional learners
install.packages(c("ranger", "xgboost", "earth", "MASS"))
```

## Simulated data

We simulate a small dataset with four types of incomplete variables to
demonstrate `misl` across all supported outcome types.

``` r

library(misl)

set.seed(42)
n <- 300

sim_data <- data.frame(
  # Continuous predictors (always observed)
  age    = round(rnorm(n, mean = 50, sd = 12)),
  bmi    = round(rnorm(n, mean = 26, sd = 4), 1),
  # Continuous outcome with missingness
  sbp    = round(120 + 0.4 * rnorm(n, mean = 50, sd = 12) +
                       0.3 * rnorm(n, mean = 26, sd = 4) + rnorm(n, sd = 10)),
  # Binary outcome with missingness (0 = no, 1 = yes)
  smoker = rbinom(n, 1, prob = 0.3),
  # Unordered categorical outcome with missingness
  group  = factor(sample(c("A", "B", "C"), n, replace = TRUE,
                         prob = c(0.4, 0.35, 0.25))),
  # Ordered categorical outcome with missingness
  health = factor(sample(c("Poor", "Fair", "Good", "Excellent"), n,
                         replace = TRUE, prob = c(0.1, 0.2, 0.5, 0.2)),
                  levels  = c("Poor", "Fair", "Good", "Excellent"),
                  ordered = TRUE)
)

# Introduce missing values
sim_data[sample(n, 40), "sbp"]    <- NA
sim_data[sample(n, 30), "smoker"] <- NA
sim_data[sample(n, 30), "group"]  <- NA
sim_data[sample(n, 30), "health"] <- NA

# Summarise missingness
sapply(sim_data, function(x) sum(is.na(x)))
#>    age    bmi    sbp smoker  group health 
#>      0      0     40     30     30     30
```

## Built-in learners

Use
[`list_learners()`](https://justinmanjourides.github.io/misl/reference/list_learners.md)
to see the available named learners, optionally filtered by outcome
type:

``` r

knitr::kable(list_learners())
```

| learner | description | continuous | binomial | categorical | ordinal | package | installed |
|:---|:---|:---|:---|:---|:---|:---|:---|
| glm | Linear / logistic regression | TRUE | TRUE | FALSE | FALSE | stats | TRUE |
| mars | Multivariate adaptive regression splines | TRUE | TRUE | FALSE | FALSE | earth | TRUE |
| multinom_reg | Multinomial regression | FALSE | FALSE | TRUE | FALSE | nnet | TRUE |
| polr | Proportional odds logistic regression | FALSE | FALSE | FALSE | TRUE | MASS | TRUE |
| rand_forest | Random forest | TRUE | TRUE | TRUE | TRUE | ranger | TRUE |
| boost_tree | Gradient boosted trees | TRUE | TRUE | TRUE | TRUE | xgboost | TRUE |

``` r

knitr::kable(list_learners("ordinal"))
```

| learner     | description                           | package | installed |
|:------------|:--------------------------------------|:--------|:----------|
| polr        | Proportional odds logistic regression | MASS    | TRUE      |
| rand_forest | Random forest                         | ranger  | TRUE      |
| boost_tree  | Gradient boosted trees                | xgboost | TRUE      |

## Basic usage

The primary function is
[`misl()`](https://justinmanjourides.github.io/misl/reference/misl.md).
Supply a dataset and specify:

- `m` – the number of multiply imputed datasets to create
- `maxit` – the number of Gibbs sampling iterations per dataset
- `con_method`, `bin_method`, `cat_method`, `ord_method` – learners for
  each outcome type

Running
[`misl()`](https://justinmanjourides.github.io/misl/reference/misl.md)
with a single named learner per outcome type is the fastest option and
is well suited for exploratory work. Note that ordered factors are
automatically detected and routed to `ord_method`:

``` r

misl_imp <- misl(
  sim_data,
  m          = 5,
  maxit      = 5,
  con_method = "glm",
  bin_method = "glm",
  cat_method = "multinom_reg",
  ord_method = "polr",
  seed       = 42,
  quiet      = TRUE
)
```

[`misl()`](https://justinmanjourides.github.io/misl/reference/misl.md)
returns a list of length `m`. Each element contains:

- `$datasets` – the fully imputed tibble
- `$trace` – a long-format tibble of convergence statistics

``` r

# Number of imputed datasets
length(misl_imp)

# Confirm no missing values remain
anyNA(misl_imp[[1]]$datasets)

# Confirm ordered factor is preserved
is.ordered(misl_imp[[1]]$datasets$health)
levels(misl_imp[[1]]$datasets$health)
```

## Custom learners via parsnip

In addition to the built-in named learners, `misl` v2.0 accepts any
parsnip-compatible model spec directly. This allows you to use any
learner available in the tidymodels ecosystem without waiting for it to
be added to the built-in registry.

### Passing a custom spec

Simply pass a parsnip model spec in place of (or alongside) a named
string. `misl` will automatically enforce the correct mode (regression
vs classification) regardless of what is set on the spec:

``` r

library(parsnip)

# A random forest with custom hyperparameters
custom_rf <- rand_forest(trees = 500, mtry = 3) |>
  set_engine("ranger")

misl_custom <- misl(
  sim_data,
  m          = 5,
  maxit      = 5,
  con_method = list(custom_rf),
  bin_method = list(custom_rf),
  cat_method = "multinom_reg",
  ord_method = "polr",
  seed       = 42,
  quiet      = TRUE
)
```

### Mixing named learners and custom specs

Named strings and parsnip specs can be freely mixed in the same list.
When multiple learners are supplied, `misl` uses cross-validation to
build a stacked ensemble:

``` r

library(parsnip)

# Mix a named learner with a custom tuned spec
custom_xgb <- boost_tree(trees = 200, learn_rate = 0.05) |>
  set_engine("xgboost")

misl_mixed <- misl(
  sim_data,
  m          = 5,
  maxit      = 5,
  con_method = list("glm", custom_xgb),
  bin_method = list("glm", custom_xgb),
  cat_method = list("multinom_reg", "rand_forest"),
  ord_method = list("polr", "rand_forest"),
  cv_folds   = 3,
  seed       = 42
)
```

### Using a learner not in the built-in registry

Any parsnip-supported engine can be used. For example, a support vector
machine via the `kernlab` package:

``` r

library(parsnip)

# SVM - not in the built-in registry but works via parsnip
svm_spec <- svm_rbf() |>
  set_engine("kernlab")

misl_svm <- misl(
  sim_data,
  m          = 5,
  maxit      = 5,
  con_method = list("glm", svm_spec),
  bin_method = list("glm", svm_spec),
  cat_method = "multinom_reg",
  ord_method = "polr",
  cv_folds   = 3,
  seed       = 42
)
```

### Ordinal outcomes and the polr learner

For ordered categorical variables, `misl` automatically detects ordered
factors and routes them to `ord_method`. The default learner is `"polr"`
(proportional odds logistic regression from the `MASS` package), which
respects the ordering of the levels:

``` r

# Ensure your ordered variable is an ordered factor
sim_data$health <- factor(sim_data$health,
  levels  = c("Poor", "Fair", "Good", "Excellent"),
  ordered = TRUE
)

misl_ordinal <- misl(
  sim_data,
  m          = 5,
  maxit      = 5,
  con_method = "glm",
  bin_method = "glm",
  cat_method = "multinom_reg",
  ord_method = "polr",   # proportional odds model for ordered categories
  seed       = 42,
  quiet      = TRUE
)

# Imputed values respect the ordering
is.ordered(misl_ordinal[[1]]$datasets$health)
levels(misl_ordinal[[1]]$datasets$health)
```

## Multiple learners and stacking

When multiple learners are supplied (whether named strings, parsnip
specs, or a mix), `misl` uses cross-validation to learn optimal ensemble
weights via the `stacks` package. Use `cv_folds` to reduce the number of
folds and speed up computation:

``` r

misl_stack <- misl(
  sim_data,
  m          = 5,
  maxit      = 5,
  con_method = c("glm", "rand_forest"),
  bin_method = c("glm", "rand_forest"),
  cat_method = c("multinom_reg", "rand_forest"),
  ord_method = c("polr", "rand_forest"),
  cv_folds   = 3,
  seed       = 42
)
```

## Analysing the imputed datasets

After imputation, fit your analysis model to each of the `m` datasets
and pool the results using Rubin’s rules. Here we implement pooling
manually using base R:

``` r

# Fit a linear model to each imputed dataset
models <- lapply(misl_imp, function(imp) {
  lm(sbp ~ age + bmi + smoker + group + health, data = imp$datasets)
})

# Pool point estimates and standard errors using Rubin's rules
m       <- length(models)
ests    <- sapply(models, function(fit) coef(fit))
vars    <- sapply(models, function(fit) diag(vcov(fit)))

Q_bar   <- rowMeans(ests)                          # pooled estimate
U_bar   <- rowMeans(vars)                          # within-imputation variance
B       <- apply(ests, 1, var)                     # between-imputation variance
T_total <- U_bar + (1 + 1 / m) * B                # total variance

pooled <- data.frame(
  term      = names(Q_bar),
  estimate  = round(Q_bar, 4),
  std.error = round(sqrt(T_total), 4),
  conf.low  = round(Q_bar - 1.96 * sqrt(T_total), 4),
  conf.high = round(Q_bar + 1.96 * sqrt(T_total), 4)
)
print(pooled)
```

For a full implementation of Rubin’s rules including degrees of freedom
and p-values, the `mice` package provides `pool()` and can be used
directly with `misl` output:

``` r

library(mice)
pooled_mice <- summary(pool(models), conf.int = TRUE)
```

## Convergence: trace plots

The
[`plot_misl_trace()`](https://justinmanjourides.github.io/misl/reference/plot_misl_trace.md)
function plots the mean or standard deviation of imputed values across
iterations for a given variable, with one line per imputed dataset.
Stable traces that mix well across datasets indicate convergence. Note
that trace statistics are only computed for continuous and numeric
binary columns — they are not available for categorical or ordinal
columns.

``` r

# Plot mean of imputed sbp values across iterations for each dataset
plot_misl_trace(misl_imp, variable = "sbp", ylab = "Mean imputed sbp (mm Hg)")
```

``` r

# Plot the standard deviation instead
plot_misl_trace(misl_imp, variable = "sbp", statistic = "sd")
```

Stable traces that mix well across datasets indicate the algorithm has
converged.

## Parallelism

The `m` imputed datasets are generated independently and can be run in
parallel using the `future` framework. Set a parallel plan before
calling
[`misl()`](https://justinmanjourides.github.io/misl/reference/misl.md):

``` r

library(future)

# Use all available cores
plan(multisession)

misl_parallel <- misl(
  sim_data,
  m          = 10,
  maxit      = 5,
  con_method = c("glm", "rand_forest"),
  bin_method = c("glm", "rand_forest"),
  cat_method = c("multinom_reg", "rand_forest"),
  ord_method = c("polr", "rand_forest"),
  seed       = 42
)

# Always reset the plan when done
plan(sequential)
```

To limit the number of cores:

``` r

plan(multisession, workers = 4)
```

The largest speedup comes from running the `m` datasets simultaneously.
Check how many cores are available with:

``` r

parallel::detectCores()
```

## Session info

``` r

sessionInfo()
#> R version 4.6.0 (2026-04-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] misl_2.0.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] Matrix_1.7-5        jsonlite_2.0.0      compiler_4.6.0     
#>  [4] ranger_0.18.0       plotrix_3.8-14      Rcpp_1.1.1-1.1     
#>  [7] jquerylib_0.1.4     systemfonts_1.3.2   textshaping_1.0.5  
#> [10] yaml_2.3.12         fastmap_1.2.0       lattice_0.22-9     
#> [13] R6_2.6.1            Formula_1.2-5       knitr_1.51         
#> [16] MASS_7.3-65         tibble_3.3.1        desc_1.4.3         
#> [19] nnet_7.3-20         bslib_0.10.0        pillar_1.11.1      
#> [22] rlang_1.2.0         cachem_1.1.0        xfun_0.57          
#> [25] fs_2.1.0            sass_0.4.10         earth_5.3.5        
#> [28] cli_3.6.6           pkgdown_2.2.0       magrittr_2.0.5     
#> [31] digest_0.6.39       grid_4.6.0          plotmo_3.7.0       
#> [34] xgboost_3.2.1.1     lifecycle_1.0.5     vctrs_0.7.3        
#> [37] evaluate_1.0.5      glue_1.8.1          data.table_1.18.2.1
#> [40] ragg_1.5.2          rmarkdown_2.31      tools_4.6.0        
#> [43] pkgconfig_2.0.3     htmltools_0.5.9
```
