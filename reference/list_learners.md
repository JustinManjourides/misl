# List available learners for MISL imputation

Displays the built-in named learners available for use in
[`misl()`](https://justinmanjourides.github.io/misl/reference/misl.md).
Note that any parsnip-compatible model spec can also be passed directly
via the `*_method` arguments.

## Usage

``` r
list_learners(outcome_type = "all", installed_only = FALSE)
```

## Arguments

- outcome_type:

  One of `"continuous"`, `"binomial"`, `"categorical"`, `"ordinal"`, or
  `"all"` (default).

- installed_only:

  If `TRUE`, only learners whose backend package is already installed
  are returned. Default `FALSE`.

## Value

A tibble with columns `learner`, `description`, `package`, `installed`,
and outcome-type support flags (when `outcome_type = "all"`).

## Examples

``` r
list_learners()
#> Note: 'polr' cannot currently be stacked with other ordinal learners. When 'polr' is supplied alongside other learners in ord_method, it will be used as the sole ordinal learner and others will be ignored. Full stacking support for ordinal outcomes is planned for a future release.
#> # A tibble: 6 × 8
#>   learner  description continuous binomial categorical ordinal package installed
#>   <chr>    <chr>       <lgl>      <lgl>    <lgl>       <lgl>   <chr>   <lgl>    
#> 1 glm      Linear / l… TRUE       TRUE     FALSE       FALSE   stats   TRUE     
#> 2 mars     Multivaria… TRUE       TRUE     FALSE       FALSE   earth   TRUE     
#> 3 multino… Multinomia… FALSE      FALSE    TRUE        FALSE   nnet    TRUE     
#> 4 polr     Proportion… FALSE      FALSE    FALSE       TRUE    MASS    TRUE     
#> 5 rand_fo… Random for… TRUE       TRUE     TRUE        TRUE    ranger  TRUE     
#> 6 boost_t… Gradient b… TRUE       TRUE     TRUE        TRUE    xgboost TRUE     
list_learners("continuous")
#> # A tibble: 4 × 4
#>   learner     description                              package installed
#>   <chr>       <chr>                                    <chr>   <lgl>    
#> 1 glm         Linear / logistic regression             stats   TRUE     
#> 2 mars        Multivariate adaptive regression splines earth   TRUE     
#> 3 rand_forest Random forest                            ranger  TRUE     
#> 4 boost_tree  Gradient boosted trees                   xgboost TRUE     
list_learners("ordinal")
#> Note: 'polr' cannot currently be stacked with other ordinal learners. When 'polr' is supplied alongside other learners in ord_method, it will be used as the sole ordinal learner and others will be ignored. Full stacking support for ordinal outcomes is planned for a future release.
#> # A tibble: 3 × 4
#>   learner     description                           package installed
#>   <chr>       <chr>                                 <chr>   <lgl>    
#> 1 polr        Proportional odds logistic regression MASS    TRUE     
#> 2 rand_forest Random forest                         ranger  TRUE     
#> 3 boost_tree  Gradient boosted trees                xgboost TRUE     
list_learners("categorical", installed_only = TRUE)
#> # A tibble: 3 × 4
#>   learner      description            package installed
#>   <chr>        <chr>                  <chr>   <lgl>    
#> 1 multinom_reg Multinomial regression nnet    TRUE     
#> 2 rand_forest  Random forest          ranger  TRUE     
#> 3 boost_tree   Gradient boosted trees xgboost TRUE     
```
