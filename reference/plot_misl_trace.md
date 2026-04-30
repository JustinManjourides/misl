# Plot trace statistics from a MISL imputation

Plots the mean and standard deviation of imputed values across
iterations for all incomplete variables, paginated in grids of up to 3
variables per page. Stable traces that mix well across datasets indicate
convergence. Note that trace statistics are only computed for continuous
and numeric binary columns – categorical and ordinal columns are
excluded automatically.

## Usage

``` r
plot_misl_trace(misl_result, ncol = 2, nrow = 3)
```

## Arguments

- misl_result:

  A list returned by
  [`misl()`](https://justinmanjourides.github.io/misl/reference/misl.md).

- ncol:

  Number of columns per page. Default `2`.

- nrow:

  Number of rows per page. Default `3`.

## Value

Invisibly returns the long-format trace data frame used for plotting.

## Examples

``` r
set.seed(1)
n <- 100
demo_data <- data.frame(x1 = rnorm(n), x2 = rnorm(n), y = rnorm(n))
demo_data[sample(n, 10), "y"] <- NA
misl_imp <- misl(demo_data, m = 3, maxit = 3, con_method = "glm")
plot_misl_trace(misl_imp)
```
