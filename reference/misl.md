# MISL: Multiple Imputation by Super Learning (v2.0)

Imputes missing values using multiple imputation by super learning.

## Usage

``` r
misl(
  dataset,
  m = 5,
  maxit = 5,
  seed = NA,
  con_method = c("glm", "rand_forest", "boost_tree"),
  bin_method = c("glm", "rand_forest", "boost_tree"),
  cat_method = c("rand_forest", "boost_tree"),
  ord_method = c("polr", "rand_forest", "boost_tree"),
  cv_folds = 5,
  ignore_predictors = NA,
  quiet = TRUE
)
```

## Arguments

- dataset:

  A dataframe or matrix containing the incomplete data. Missing values
  are represented with `NA`.

- m:

  The number of multiply imputed datasets to create. Default `5`.

- maxit:

  The number of iterations per imputed dataset. Default `5`.

- seed:

  Integer seed for reproducibility, or `NA` to skip. Default `NA`.

- con_method:

  Character vector of learner IDs, a list of parsnip model specs, or a
  mixed list of both, for continuous columns. Default
  `c("glm", "rand_forest", "boost_tree")`.

- bin_method:

  Character vector of learner IDs, a list of parsnip model specs, or a
  mixed list of both, for binary columns (values must be `0/1/NA` or a
  two-level factor). Default `c("glm", "rand_forest", "boost_tree")`.

- cat_method:

  Character vector of learner IDs, a list of parsnip model specs, or a
  mixed list of both, for unordered categorical columns. Default
  `c("rand_forest", "boost_tree")`.

- ord_method:

  Character vector of learner IDs, a list of parsnip model specs, or a
  mixed list of both, for ordered categorical columns. Default
  `c("polr", "rand_forest", "boost_tree")`.

- cv_folds:

  Integer number of cross-validation folds used when stacking multiple
  learners. Reducing this (e.g. to `3`) speeds up computation at a small
  cost to ensemble accuracy. Default `5`. Ignored when only a single
  learner is supplied.

- ignore_predictors:

  Character vector of column names to exclude as predictors. Default
  `NA`.

- quiet:

  Suppress console progress messages. Default `TRUE`.

## Value

A list of `m` named lists, each with:

- `datasets`:

  A fully imputed tibble.

- `trace`:

  A long-format tibble of mean/sd trace statistics per iteration, for
  convergence inspection.

## Details

Built-in named learners (see
[`list_learners()`](https://justinmanjourides.github.io/misl/reference/list_learners.md)):

- `"glm"` - base R (logistic for binary, linear for continuous)

- `"rand_forest"` - ranger

- `"boost_tree"` - xgboost

- `"mars"` - earth

- `"multinom_reg"` - nnet (unordered categorical only)

- `"polr"` - MASS (ordered categorical only)

Any parsnip-compatible model spec can also be passed directly via the
`*_method` arguments. Named strings and parsnip specs can be mixed in
the same list:


    library(parsnip)
    misl(data,
      con_method = list(
        "glm",
        rand_forest(trees = 500) |> set_engine("ranger")
      )
    )

The mode (regression vs classification) is always enforced by `misl`
regardless of what is set on the spec.

## Parallelism

Imputation across the `m` datasets is parallelised via future.apply. To
enable parallel execution, set a future plan before calling `misl()`:


    library(future)
    plan(multisession, workers = 4)
    result <- misl(data, m = 5)
    plan(sequential)

## Examples

``` r
# Using named learners (same as v1.0)
set.seed(1)
n <- 100
demo_data <- data.frame(x1 = rnorm(n), x2 = rnorm(n), y = rnorm(n))
demo_data[sample(n, 10), "y"] <- NA
misl_imp <- misl(demo_data, m = 2, maxit = 2, con_method = "glm")

# Using a custom parsnip spec
if (FALSE) { # \dontrun{
library(parsnip)
misl_imp <- misl(
  demo_data, m = 2, maxit = 2,
  con_method = list(
    "glm",
    rand_forest(trees = 500) |> set_engine("ranger")
  )
)
} # }
```
