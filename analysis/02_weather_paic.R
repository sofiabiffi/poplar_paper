# Baseline continuation of the existing PCA -> Gamma(log) approach.
# This is a starting model, not an agreed final inferential specification.
# Each period uses its prepared complete-case basis; cross-period AIC ranking
# is deliberately left for a comparison using identical years.
if (!exists("paper_data")) stop("First source prepare_data.R")
weather_paic_models <- list()
weather_model_summary <- list()
weather_model_coefficients <- list()
weather_model_diagnostics <- list()
for (period in paper_config$weather_periods) {
  pcs <- weather_pca[[period]]$retained_pcs
  for (code in hybrid_key$hybrid_code) {
    id <- paste(code, period, sep = "_")
    dat <- growth_weather_pcs |>
      dplyr::filter(weather_period == period, hybrid_code == code, !is.na(PAIC), PAIC > 0) |>
      dplyr::arrange(measurement_year)
    model <- stats::glm(stats::reformulate(pcs, response = "PAIC"),
                        data = dat, family = stats::Gamma(link = "log"))
    null <- stats::glm(PAIC ~ 1, data = dat, family = stats::Gamma(link = "log"))
    weather_paic_models[[id]] <- list(model = model, null = null, data = dat, retained_pcs = pcs)
    weather_model_summary[[id]] <- tibble::tibble(hybrid_code = code,
      weather_period = period, n = stats::nobs(model), n_pcs = length(pcs),
      AIC = stats::AIC(model), deviance_reduction = 1 - model$deviance / null$deviance,
      converged = model$converged, first_measurement_year = min(dat$measurement_year),
      last_measurement_year = max(dat$measurement_year))
    weather_model_coefficients[[id]] <- broom::tidy(model) |>
      dplyr::mutate(hybrid_code = code, weather_period = period, .before = 1)
    weather_model_diagnostics[[id]] <- dat |>
      dplyr::select(hybrid_code, weather_period, measurement_year, growth_year, interval_years, PAIC) |>
      dplyr::mutate(fitted = stats::fitted(model), deviance_residual = stats::residuals(model, type = "deviance"),
                    cooks_distance = stats::cooks.distance(model))
  }
}
weather_model_summary <- dplyr::bind_rows(weather_model_summary)
weather_model_coefficients <- dplyr::bind_rows(weather_model_coefficients)
weather_model_diagnostics <- dplyr::bind_rows(weather_model_diagnostics)
utils::write.csv(publication_table(weather_model_summary), project_path("results", "tables", "baseline_weather_model_summary.csv"), row.names = FALSE)
utils::write.csv(publication_table(weather_model_coefficients), project_path("results", "tables", "baseline_weather_model_coefficients.csv"), row.names = FALSE)
utils::write.csv(publication_table(weather_model_diagnostics), project_path("results", "checks", "baseline_weather_model_diagnostics.csv"), row.names = FALSE)
saveRDS(weather_paic_models, project_path("results", "models", "baseline_weather_paic_models.rds"))


