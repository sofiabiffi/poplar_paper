tree_source <- read_source("tree_diameter.xlsx")
require_columns(tree_source, c("tree_id", "block", "hybrids", "treatment", "year",
                              "diameter_cm", "periodic_c_increment_mg_ha",
                              "mean_annual_c_increment_mg_ha"), "Tree source")
assert_unique(tree_source, c("tree_id", "year"), "tree observations")
if (any(!tree_source$hybrids %in% hybrid_key$hybrid_code) ||
    any(!tree_source$treatment %in% treatment_key$treatment_code)) stop("Unmapped tree codes")

tree_growth <- tree_source |>
  dplyr::rename(hybrid_code = hybrids, treatment_code = treatment,
                measurement_year = year, carbon_stock_mg_ha = c_stock_mg) |>
  dplyr::mutate(
    measurement_year = as.integer(measurement_year),
    age_years = measurement_year - paper_config$planting_year,
    growth_year = measurement_year - paper_config$weather_year_offset,
    PAIC = periodic_c_increment_mg_ha,
    MAIC = mean_annual_c_increment_mg_ha,
    active_cropping = measurement_year >= paper_config$cultivated_first_measurement_year &
      measurement_year <= paper_config$cultivated_last_measurement_year,
    phase = ifelse(active_cropping, "Active cropping", "Post cropping"),
    biomass_kg_recalculated = ifelse(diameter_cm >= 0,
                                    exp(coef_ln_a) * diameter_cm ^ coef_b, NA_real_),
    carbon_stock_mg_ha_recalculated = biomass_kg_recalculated *
      paper_config$carbon_fraction * paper_config$tree_density_ha / 1000,
    MAIC_recalculated = carbon_stock_mg_ha_recalculated / age_years
  ) |>
  dplyr::left_join(hybrid_key, by = "hybrid_code") |>
  dplyr::left_join(treatment_key, by = "treatment_code") |>
  dplyr::arrange(tree_id, measurement_year) |>
  dplyr::group_by(tree_id) |>
  dplyr::mutate(
    previous_measurement_year = dplyr::lag(measurement_year),
    interval_years = measurement_year - previous_measurement_year,
    interval_start_growth_year = previous_measurement_year,
    interval_end_growth_year = growth_year,
    multi_year_increment = !is.na(interval_years) & interval_years > 1,
    interval_crosses_cropping_end = !is.na(previous_measurement_year) &
      previous_measurement_year <= paper_config$cultivated_last_measurement_year &
      measurement_year > paper_config$cultivated_last_measurement_year,
    PAIC_recalculated = (carbon_stock_mg_ha_recalculated -
                          dplyr::lag(carbon_stock_mg_ha_recalculated)) / interval_years,
    PAIC_from_supplied_stocks = (carbon_stock_mg_ha - dplyr::lag(carbon_stock_mg_ha)) / interval_years,
    PAIC_nonpositive = !is.na(PAIC) & PAIC <= 0
  ) |>
  dplyr::ungroup()

annual_hybrid <- summarise_growth(tree_growth, c("measurement_year", "growth_year", "age_years", "hybrid_code", "hybrid"))
annual_hybrid_treatment <- summarise_growth(tree_growth, c("measurement_year", "growth_year", "age_years", "hybrid_code", "hybrid", "treatment_code", "treatment"))
growth_descriptive <- summarise_growth(tree_growth, c("hybrid_code", "hybrid"))
tree_treatment_active <- dplyr::filter(tree_growth, active_cropping)
tree_phase_means <- tree_growth |>
  dplyr::group_by(tree_id, block, tree_row, hybrid_code, hybrid, treatment_code, treatment, phase) |>
  dplyr::summarise(
    PAIC_mean = safe_mean(PAIC), MAIC_mean = safe_mean(MAIC),
    n_PAIC = sum(!is.na(PAIC)), n_MAIC = sum(!is.na(MAIC)),
    first_measurement_year = min(measurement_year), last_measurement_year = max(measurement_year),
    .groups = "drop"
  )
tree_response_audit <- tree_growth |>
  dplyr::select(tree_id, measurement_year, hybrid_code, diameter_cm, interval_years,
    carbon_stock_mg_ha, carbon_stock_mg_ha_recalculated, PAIC, PAIC_from_supplied_stocks,
    PAIC_recalculated, MAIC, MAIC_recalculated, years_since_last_recording) |>
  dplyr::mutate(PAIC_difference_from_supplied_stocks = PAIC - PAIC_from_supplied_stocks,
                MAIC_difference_recalculated = MAIC - MAIC_recalculated,
                stock_difference_recalculated = carbon_stock_mg_ha - carbon_stock_mg_ha_recalculated)

