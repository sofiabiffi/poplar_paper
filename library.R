# All package loading for preparation and the planned analyses lives here.
# The master script sets poplar.paper.root before sourcing this file.
paper_packages <- c(
  "readxl", "dplyr", "tidyr", "purrr", "lubridate", "ggplot2",
  "openxlsx", "tibble", "broom", "lme4", "lmerTest", "emmeans",
  "broom.mixed", "mgcv", "renv"
)
.libPaths(c(file.path(getOption("poplar.paper.root", getwd()), "renv", "library"),
            .libPaths()))
missing_packages <- paper_packages[!vapply(paper_packages, requireNamespace,
                                          logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Missing project packages: ", paste(missing_packages, collapse = ", "),
       ". Open the paper project and run source('setup_environment.R').")
}
invisible(lapply(paper_packages, function(package) {
  suppressPackageStartupMessages(library(package, character.only = TRUE))
}))

source(file.path(getOption("poplar.paper.root"), "plot_style.R"), local = TRUE)
