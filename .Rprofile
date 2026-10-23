# Project-local packages; restore uses the versioned renv.lock.
local({
  project <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  options(poplar.paper.root = project)
  .libPaths(c(file.path(project, "renv", "library"), .libPaths()))
})

