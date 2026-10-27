# PAIC treatment analysis: active cropping and post-cropping legacy.
if (!exists("paper_data")) stop("First source prepare_data.R")
source(project_path("scripts", "treatment_presentation.R"))
cessation_year <- paper_config$cultivated_last_measurement_year
# 2002-2005 includes growth through 2004 under t -> t-1 alignment.
# Separate this cessation-boundary interval in primary analyses.
treatment_model_data <- tree_growth |>
  dplyr::mutate(analysis_phase = dplyr::case_when(
    is.na(previous_measurement_year) ~ "No increment interval",
    previous_measurement_year <= cessation_year & measurement_year > cessation_year ~ "Boundary",
    interval_end_growth_year <= cessation_year ~ "Active",
    interval_start_growth_year > cessation_year ~ "Post",
    TRUE ~ "Boundary"),
    interval = paste(previous_measurement_year, measurement_year, sep = "-"))
write_treatment_table <- function(x, name) utils::write.csv(publication_table(x),
  project_path("results", "tables", paste0("treatment_PAIC_", name, ".csv")), row.names = FALSE)
write_treatment_table(treatment_model_data |>
  dplyr::group_by(analysis_phase, previous_measurement_year, measurement_year,
                  interval_start_growth_year, interval_end_growth_year) |>
  dplyr::summarise(n_records = dplyr::n(), n_valid_PAIC = sum(is.finite(PAIC)),
                  n_nonpositive = sum(is.finite(PAIC) & PAIC <= 0), .groups = "drop"), "interval_audit")
# All measured trees contribute; neighbouring trees are subsamples.
# Equal-weight row x hybrid means retain three treatment replicates.
treatment_row_means <- treatment_model_data |>
  dplyr::filter(is.finite(PAIC), !is.na(previous_measurement_year)) |>
  dplyr::group_by(block, tree_row, treatment_code, hybrid_code, hybrid,
    analysis_phase, interval, previous_measurement_year, measurement_year,
    interval_start_growth_year, interval_end_growth_year) |>
  dplyr::summarise(PAIC = mean(PAIC), n_trees = dplyr::n_distinct(tree_id), .groups = "drop") |>
  dplyr::mutate(block = factor(block),
    treatment_code = factor(treatment_code, levels = c("F", "C", "A")),
    hybrid_code = factor(hybrid_code),
    row_id = interaction(block, tree_row, drop = TRUE),
    row_hybrid = interaction(row_id, hybrid_code, drop = TRUE),
    row_interval = interaction(row_id, interval, drop = TRUE))
write_treatment_table(treatment_row_means, "row_means")

fit_treatment_phase <- function(phases, label) {
  dat <- droplevels(dplyr::filter(treatment_row_means, analysis_phase %in% phases))
  dat$interval <- factor(dat$interval, levels = unique(dat$interval[order(dat$measurement_year)]))
  # Row is the treatment unit; row-hybrid models persistent local differences.
  # Row-interval models fluctuations shared by hybrids in a treatment row.
  model <- lmerTest::lmer(
    PAIC ~ block + treatment_code * hybrid_code * interval +
      (1 | row_id) + (1 | row_hybrid) + (1 | row_interval),
    data = dat, REML = TRUE,
    contrasts = list(block = "contr.sum", treatment_code = "contr.sum",
                     hybrid_code = "contr.sum", interval = "contr.sum"))
  tests <- as.data.frame(anova(model, type = 3, ddf = "Satterthwaite"))
  tests$term <- rownames(tests)
  write_treatment_table(tests, paste0(label, "_tests"))
  marginal <- emmeans::emmeans(model, ~ treatment_code, weights = "equal", lmer.df = "satterthwaite")
  by_hybrid <- emmeans::emmeans(model, ~ treatment_code | hybrid_code, weights = "equal", lmer.df = "satterthwaite")
  by_interval <- emmeans::emmeans(model, ~ treatment_code | interval, weights = "equal", lmer.df = "satterthwaite")
  by_hybrid_interval <- emmeans::emmeans(model, ~ treatment_code | hybrid_code * interval, lmer.df = "satterthwaite")
  contrast_list <- list("C - F" = c(-1, 1, 0), "A - F" = c(-1, 0, 1), "C - A" = c(0, 1, -1))
  export_emm <- function(emm, suffix) {
    write_treatment_table(as.data.frame(confint(emm)), paste0(label, "_", suffix, "_means"))
    out <- as.data.frame(summary(emmeans::contrast(emm, contrast_list),
      infer = c(TRUE, TRUE), adjust = "bonferroni"))
    write_treatment_table(out, paste0(label, "_", suffix, "_contrasts"))
    out
  }
  overall <- export_emm(marginal, "overall")
  hybrids <- export_emm(by_hybrid, "hybrid")
  intervals <- export_emm(by_interval, "interval")
  hybrid_intervals <- export_emm(by_hybrid_interval, "hybrid_interval")
  intervals$measurement_year <- as.integer(sub(".*-", "", as.character(intervals$interval)))
  intervals$years_since_cessation <- intervals$measurement_year - 1L - cessation_year
  write_treatment_table(intervals, paste0(label, "_interval_contrasts"))
  diagnostic <- dat |>
    dplyr::mutate(fitted = fitted(model), residual = residuals(model),
                  scaled_residual = residuals(model) / sigma(model))
  write_treatment_table(diagnostic, paste0(label, "_residuals"))
  write_treatment_table(as.data.frame(lme4::VarCorr(model)), paste0(label, "_variance"))
  convergence <- model@optinfo$conv$lme4$messages
  capture.output(summary(model), tests,
    cat("\nSingular fit:", lme4::isSingular(model), "\n"),
    cat("Convergence:", if (is.null(convergence)) "OK" else convergence, "\n"),
    file = project_path("results", "models", paste0("treatment_PAIC_", label, ".txt")))
  grDevices::png(project_path("results", "figures", paste0("treatment_PAIC_", label, "_diagnostics.png")), width = 1300, height = 650)
  par(mfrow = c(1, 2))
  plot(fitted(model), residuals(model), xlab = "Fitted PAIC", ylab = "Residual", main = label)
  abline(h = 0, lty = 2)
  qqnorm(residuals(model)); qqline(residuals(model))
  grDevices::dev.off()
  presentation <- present_treatment_phase(by_interval, label)
  mean_intervals <- presentation$means
  message(label, ": ", nrow(dat), " row-hybrid-interval means; singular = ", lme4::isSingular(model))
  print(publication_table(overall))
  list(model = model, data = dat, overall = overall, hybrid = hybrids, interval = intervals, hybrid_interval = hybrid_intervals, interval_means = mean_intervals, interval_inference = presentation$contrasts, significance_markers = presentation$markers,
       singular = lme4::isSingular(model), convergence = convergence)
}
treatment_paic_results <- list(
  active = fit_treatment_phase("Active", "active"),
  post = fit_treatment_phase("Post", "post"),
  active_with_boundary = fit_treatment_phase(c("Active", "Boundary"), "active_with_boundary"))
# Write a complete temporary file before replacing the saved models.
model_file <- project_path("results", "models", "treatment_PAIC_models.rds")
model_temp <- tempfile("treatment_PAIC_", tmpdir = dirname(model_file), fileext = ".rds")
saveRDS(treatment_paic_results, model_temp)
if (!file.copy(model_temp, model_file, overwrite = TRUE)) stop("Could not replace saved treatment models: ", model_file)
unlink(model_temp)
message("Review residual diagnostics and singular-fit flags before inference. ",
        "Nonsignificance does not establish equivalence or date disappearance of a legacy.")







# Export the combined primary phase figure.
source(project_path("analysis", "03c_treatment_figure.R"))
