# First use on another computer: restore the versions recorded in renv.lock.
# No package installation is performed by prepare_data.R.
local({
  src <- Filter(Negate(is.null), lapply(sys.frames(), function(x) x$ofile))
  root <- if (length(src)) dirname(normalizePath(tail(src, 1)[[1]], winslash = "/")) else getwd()
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  options(poplar.paper.root = root, repos = c(CRAN = "https://cloud.r-project.org"))
  lib <- file.path(root, "renv", "library")
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(lib, .libPaths()))
  Sys.setenv(RENV_PATHS_CACHE = file.path(root, "renv", "cache"),
             RENV_PATHS_LIBRARY = lib,
             RENV_PATHS_ROOT = file.path(root, "renv", "local"))
  if (!requireNamespace("renv", quietly = TRUE)) {
    install.packages("renv", lib = lib)
  }
  renv::restore(project = root, library = lib, prompt = interactive())
})

