# Open poplar_paper.code-workspace, then source("prepare_data.R") in R.
# Also works when sourced with an absolute path from another working directory.
.paper_source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(x) x$ofile))
.paper_root <- if (length(.paper_source_files)) {
  dirname(normalizePath(tail(.paper_source_files, 1)[[1]], winslash = "/", mustWork = TRUE))
} else {
  # Direct Rscript execution, including from outside this project.
  .paper_file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(.paper_file_arg)) dirname(normalizePath(sub("^--file=", "", .paper_file_arg[1]), winslash = "/")) else getwd()
}
if (!file.exists(file.path(.paper_root, "poplar_paper.code-workspace"))) stop("Could not locate poplar_paper project")
options(poplar.paper.root = .paper_root)
source(file.path(.paper_root, "library.R"), local = TRUE)
source(file.path(.paper_root, "scripts", "config.R"), local = TRUE)
for (.paper_dir in c("data/processed", "results/checks", "results/models", "results/figures", "results/tables")) {
  dir.create(file.path(.paper_root, .paper_dir), recursive = TRUE, showWarnings = FALSE)
}
for (.paper_module in c("00_helpers.R", "01_tree_growth.R", "02_weather.R", "03_soc.R",
                        "04_join_and_pca.R", "05_export.R")) {
  message("Preparing: ", .paper_module)
  source(file.path(.paper_root, "scripts", "prep", .paper_module), local = TRUE)
}
message("Ready: ", length(paper_data), " polished datasets in paper_data and as named objects. ",
        "PCA objects: weather_pca. See results/checks for preparation audits.")
rm(list = intersect(c(".paper_source_files", ".paper_file_arg", ".paper_dir", ".paper_module", ".paper_root"), ls()))

