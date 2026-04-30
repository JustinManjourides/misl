# Fit a stacked super learner ensemble

Fit a stacked super learner ensemble

## Usage

``` r
.fit_super_learner(
  train_data,
  full_data,
  xvars,
  yvar,
  outcome_type,
  learner_names,
  cv_folds = 5
)
```

## Arguments

- cv_folds:

  Integer number of cross-validation folds used when stacking multiple
  learners. Ignored when only a single learner is supplied.

## Value

Named list with `$boot` (fit on bootstrap sample) and `$full` (fit on
full observed data; `NULL` unless continuous).
