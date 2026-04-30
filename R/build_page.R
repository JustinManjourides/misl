library(pkgdown)

usethis::use_pkgdown()

pkgdown::build_site(
  run_dont_run = FALSE,
  lazy         = TRUE,
  install      = FALSE  # use the already-installed package
)


dir.create("man/figures", recursive = TRUE)  # create folder if it doesn't exist
