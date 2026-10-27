# Refresh figures and multiplicity tables from existing fitted models.
# Run after prepare_data.R; this does not refit the statistical models.
if (!exists("paper_data")) stop("First source prepare_data.R")
source(project_path("scripts", "treatment_presentation.R"))
treatment_paic_results <- readRDS(project_path("results", "models", "treatment_PAIC_models.rds"))
for (label in names(treatment_paic_results)) {
  emm <- emmeans::emmeans(treatment_paic_results[[label]]$model,
    ~ treatment_code | interval, weights = "equal", lmer.df = "satterthwaite")
  presentation <- present_treatment_phase(emm, label)
  treatment_paic_results[[label]]$interval_inference <- presentation$contrasts
  treatment_paic_results[[label]]$interval_means <- presentation$means
  treatment_paic_results[[label]]$significance_markers <- presentation$markers
}
model_file <- project_path("results", "models", "treatment_PAIC_models.rds")
model_temp <- tempfile("treatment_PAIC_", tmpdir = dirname(model_file), fileext = ".rds")
saveRDS(treatment_paic_results, model_temp)
if (!file.copy(model_temp, model_file, overwrite = TRUE)) stop("Could not replace saved models")
unlink(model_temp)

# Export the combined primary phase figure.
source(project_path("analysis", "03c_treatment_figure.R"))
