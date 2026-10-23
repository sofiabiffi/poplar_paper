measurement_intervals <- tree_growth |>
  dplyr::distinct(measurement_year, interval_years, multi_year_increment, interval_crosses_cropping_end)
assert_unique(measurement_intervals, "measurement_year", "measurement intervals")
growth_weather <- legacy_hybrid_responses |>
  dplyr::left_join(weather_wide, by = c("measurement_year", "growth_year")) |>
  dplyr::left_join(measurement_intervals, by = "measurement_year") |>
  dplyr::mutate(response_source = paper_config$weather_response_source,
                weather_alignment = "Previous growth year, including multi-year increments")
response_comparison <- annual_hybrid |>
  dplyr::filter(metric %in% c("PAIC", "MAIC")) |>
  dplyr::select(measurement_year, hybrid_code, metric, tree_median = median) |>
  dplyr::left_join(legacy_hybrid_responses |>
    dplyr::select(measurement_year, hybrid_code, PAIC, MAIC) |>
    tidyr::pivot_longer(c(PAIC, MAIC), names_to = "metric", values_to = "legacy_value"),
    by = c("measurement_year", "hybrid_code", "metric")) |>
  dplyr::mutate(difference = tree_median - legacy_value)

# One common weather PCA per period, shared by all four hybrid responses.
# The current positive/complete response years coincide across hybrids, so this
# reproduces script05's PCA basis without four copies of each identical PCA.
pca_response_years <- legacy_hybrid_responses |>
  dplyr::group_by(measurement_year) |>
  dplyr::summarise(common_positive_PAIC = dplyr::n_distinct(hybrid_code) == 4L &
    all(!is.na(PAIC) & PAIC > 0), .groups = "drop")
build_period_pca <- function(period) {
  predictors <- weather_groups[[period]]
  candidates <- weather_wide |>
    dplyr::left_join(pca_response_years, by = "measurement_year") |>
    dplyr::filter(common_positive_PAIC) |>
    dplyr::select(measurement_year, growth_year, dplyr::all_of(predictors))
  basis <- candidates[stats::complete.cases(candidates[predictors]), ]
  if (nrow(basis) < 3) stop("Insufficient PCA data for ", period)
  varying <- predictors[vapply(basis[predictors], function(x) dplyr::n_distinct(x) > 1, logical(1))]
  if (length(varying) < 2) stop("Fewer than two varying predictors for ", period)
  fit <- stats::prcomp(as.data.frame(basis[varying]), center = TRUE, scale. = TRUE)
  proportions <- fit$sdev ^ 2 / sum(fit$sdev ^ 2)
  n_pcs <- which(cumsum(proportions) >= paper_config$pca_variance_threshold)[1]
  retained <- paste0("PC", seq_len(n_pcs))
  scores <- dplyr::bind_cols(basis[c("measurement_year", "growth_year")],
                              tibble::as_tibble(fit$x[, retained, drop = FALSE])) |>
    dplyr::mutate(weather_period = period, .before = 1)
  loadings <- tibble::as_tibble(fit$rotation, rownames = "variable") |>
    tidyr::pivot_longer(-variable, names_to = "PC", values_to = "loading") |>
    dplyr::mutate(weather_period = period, retained = PC %in% retained, .before = 1)
  variance <- tibble::tibble(weather_period = period, PC = paste0("PC", seq_along(proportions)),
    proportion_variance = proportions, cumulative_variance = cumsum(proportions),
    retained = seq_along(proportions) <= n_pcs)
  scaling <- tibble::tibble(weather_period = period, variable = varying,
    center = unname(fit$center), scale = unname(fit$scale))
  exclusions <- tibble::tibble(weather_period = period, variable = setdiff(predictors, varying),
                                reason = "Constant on complete-case PCA basis")
  list(pca = fit, n = nrow(basis), retained_pcs = retained, scores = scores,
        loadings = loadings, variance = variance, scaling = scaling, exclusions = exclusions)
}
weather_pca <- setNames(lapply(paper_config$weather_periods, build_period_pca), paper_config$weather_periods)
weather_pc_scores <- dplyr::bind_rows(lapply(weather_pca, `[[`, "scores"))
weather_pca_loadings <- dplyr::bind_rows(lapply(weather_pca, `[[`, "loadings"))
weather_pca_variance <- dplyr::bind_rows(lapply(weather_pca, `[[`, "variance"))
weather_pca_scaling <- dplyr::bind_rows(lapply(weather_pca, `[[`, "scaling"))
weather_pca_exclusions <- dplyr::bind_rows(lapply(weather_pca, `[[`, "exclusions"))
growth_weather_pcs <- legacy_hybrid_responses |>
  dplyr::inner_join(weather_pc_scores, by = c("measurement_year", "growth_year"), relationship = "many-to-many") |>
  dplyr::left_join(measurement_intervals, by = "measurement_year")

