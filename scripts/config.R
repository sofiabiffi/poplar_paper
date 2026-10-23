# Scientific assumptions are explicit here rather than repeated across scripts.
paper_config <- list(
  planting_year = 1992L,
  tree_density_ha = 166,
  carbon_fraction = 0.5,
  cultivated_first_measurement_year = 1993L,
  cultivated_last_measurement_year = 2004L,
  treatment_phase_basis = "measurement_year",
  # Retain the requested t -> t-1 alignment even for multi-year increments.
  weather_year_offset = 1L,
  base_temperature_c = 5.5,
  windy_day_threshold_knots = 17,
  require_full_calendar_window = TRUE,
  # Preserve existing aggregation of partial daily series; expose n_valid below.
  partial_weather_policy = "available_days_with_coverage_flags",
  # Preserve the previous weather analysis response values, with an audit
  # against tree-level medians. Tree summaries are available independently.
  weather_response_source = "legacy_hybrid_medians",
  pca_variance_threshold = 0.80,
  pca_basis = "common_positive_hybrid_response_years",
  weather_periods = c("winter", "spring", "summer", "autumn", "winterhalf", "summerhalf"),
  weather_metrics = c("temp", "soil_temp", "rainfall", "sunshine", "ground_frost_days",
                      "air_frost_days", "growing_days", "growing_degree_days", "windspeed", "windy_days")
)

hybrid_key <- tibble::tribble(
  ~hybrid_code, ~hybrid, ~taxon,
  "B", "Beaupre", "Populus trichocarpa x P. deltoides",
  "G", "Gibecq", "Populus deltoides x P. nigra",
  "R", "Robusta", "Populus nigra x P. deltoides",
  "T", "Trichobel", "Populus trichocarpa"
)
treatment_key <- tibble::tribble(
  ~treatment_code, ~treatment, ~treatment_short,
  "A", "Alternate cropping", "AC",
  "C", "Continuous cropping", "CC",
  "F", "Continuous fallow", "CF"
)
soil_location_key <- tibble::tribble(
  ~location_code, ~location,
  "1_tree", "Tree row",
  "2_alley", "Alley",
  "3_arable", "Arable reference"
)

