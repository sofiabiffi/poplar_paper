# Run deliberately after changing dependencies. Normal preparation never changes
# the lockfile or installs packages.
root <- getOption("poplar.paper.root", getwd())
root <- normalizePath(root, winslash = "/", mustWork = TRUE)
lib <- file.path(root, "renv", "library")
.libPaths(c(lib, .libPaths()))
Sys.setenv(RENV_PATHS_CACHE = file.path(root, "renv", "cache"),
           RENV_PATHS_ROOT = file.path(root, "renv", "local"),
           RENV_PATHS_LIBRARY = lib,
           RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
options(repos = c(CRAN = "https://cloud.r-project.org"))
renv::snapshot(project = root, library = c(lib, .Library),
                lockfile = file.path(root, "renv.lock"), type = "explicit",
                prompt = FALSE, force = TRUE)

