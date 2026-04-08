── R CMD check results ───────────────────────── misl 2.0.0 ────
Duration: 1m 45.1s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## Test environments
* macOS (local), R 4.4.1
* Windows (win-builder), R devel
* Windows (win-builder), R release
* Linux (rhub)
* Windows (rhub)
* m1-san (rhub)
* macos-arm64 (rhub) 

## Changes in v2.0.0 relative to v1.0.0
* Added `ord_method` argument to `misl()` for ordered categorical (ordinal)
  outcomes, routed through proportional odds logistic regression (`polr`) via
  the MASS package by default.
* `check_datatype()` now distinguishes ordered from unordered factors, routing
  ordered factors to `ord_method` automatically.
* `*_method` arguments now accept parsnip model specs in addition to named
  character strings, allowing any parsnip-compatible learner to be used.
* Added `plot_misl_trace()` as an exported function for convergence
  diagnostics.
* `list_learners()` updated with an ordinal column and the `polr` learner.
* MASS added to Suggests for the `polr` learner.

## Downstream dependencies
None -- this is a new package.
