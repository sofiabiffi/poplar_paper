weather_source <- read_source("weather_daily.xlsx", "Sheet1")
require_columns(weather_source, c("Date", "Precipitation", "Mean air temp", "Min air temp",
                                 "Min grass temp", "Sunshine hrs", "Mean 10 cm soil temp",
                                 "Mean wind speed, knots"), "Weather source")
weather_daily <- weather_source |>
  dplyr::transmute(
    date = as.Date(Date), rainfall = as.numeric(Precipitation),
    temp = as.numeric(`Mean air temp`), min_air_temp = as.numeric(`Min air temp`),
    min_grass_temp = as.numeric(`Min grass temp`), sunshine = as.numeric(`Sunshine hrs`),
    soil_temp = as.numeric(`Mean 10 cm soil temp`), windspeed = as.numeric(`Mean wind speed, knots`)
  ) |>
  dplyr::mutate(
    calendar_year = lubridate::year(date),
    air_frost_days = ifelse(is.na(min_air_temp), NA_real_, as.numeric(min_air_temp < 0)),
    ground_frost_days = ifelse(is.na(min_grass_temp), NA_real_, as.numeric(min_grass_temp < 0)),
    growing_days = ifelse(is.na(temp), NA_real_, as.numeric(temp > paper_config$base_temperature_c)),
    growing_degree_days = pmax(temp - paper_config$base_temperature_c, 0),
    windy_days = ifelse(is.na(windspeed), NA_real_, as.numeric(windspeed > paper_config$windy_day_threshold_knots))
  ) |>
  dplyr::arrange(date)
if (anyNA(weather_daily$date)) stop("Invalid weather dates")
assert_unique(weather_daily, "date", "daily weather")

response_source <- read_source("legacy_hybrid_responses.xlsx")
legacy_hybrid_responses <- response_source |>
  dplyr::select(measurement_year = year, dplyr::matches("^(PAI|MAI)_")) |>
  tidyr::pivot_longer(-measurement_year, names_to = c("metric", "hybrid_code"), names_sep = "_", values_to = "value") |>
  tidyr::pivot_wider(names_from = metric, values_from = value) |>
  dplyr::rename(PAIC = PAI, MAIC = MAI) |>
  dplyr::left_join(hybrid_key, by = "hybrid_code") |>
  dplyr::mutate(measurement_year = as.integer(measurement_year),
                growth_year = measurement_year - paper_config$weather_year_offset,
                age_years = measurement_year - paper_config$planting_year)
assert_unique(legacy_hybrid_responses, c("measurement_year", "hybrid_code"), "hybrid responses")
if (paper_config$weather_response_source != "legacy_hybrid_medians") stop("Implement response choice explicitly before changing config")

make_window <- function(measurement_year, weather_period) {
  g <- measurement_year - paper_config$weather_year_offset
  start <- switch(weather_period, winter = sprintf("%d-12-01", g-1),
    spring = sprintf("%d-03-01", g), summer = sprintf("%d-06-01", g),
    autumn = sprintf("%d-09-01", g), winterhalf = sprintf("%d-10-01", g-1),
    summerhalf = sprintf("%d-04-01", g))
  end <- switch(weather_period, winter = as.character(as.Date(sprintf("%d-03-01", g))-1),
    spring = sprintf("%d-05-31", g), summer = sprintf("%d-08-31", g),
    autumn = sprintf("%d-11-30", g), winterhalf = sprintf("%d-03-31", g),
    summerhalf = sprintf("%d-09-30", g))
  tibble::tibble(measurement_year, growth_year = g, weather_period,
                 start_date = as.Date(start), end_date = as.Date(end))
}
weather_window_definitions <- tidyr::crossing(
  measurement_year = sort(unique(legacy_hybrid_responses$measurement_year)),
  weather_period = paper_config$weather_periods
) |>
  purrr::pmap_dfr(make_window)

aggregate_window <- function(measurement_year, growth_year, weather_period, start_date, end_date) {
  x <- dplyr::filter(weather_daily, date >= start_date, date <= end_date)
  expected <- as.integer(end_date - start_date) + 1L
  available <- dplyr::n_distinct(x$date)
  complete <- available == expected
  result <- tibble::tibble(measurement_year, growth_year, weather_period, start_date, end_date,
                           n_days_expected = expected, n_days_available = available,
                           calendar_complete = complete)
  for (metric in paper_config$weather_metrics) {
    result[[paste0("n_valid_", metric)]] <- sum(!is.na(x[[metric]]))
    result[[metric]] <- if (paper_config$require_full_calendar_window && !complete) {
      NA_real_
    } else if (metric %in% c("temp", "soil_temp", "windspeed")) {
      safe_mean(x[[metric]])
    } else safe_sum(x[[metric]])
  }
  result
}
weather_windows <- purrr::pmap_dfr(weather_window_definitions, aggregate_window)
weather_coverage <- weather_windows |>
  dplyr::select(measurement_year, growth_year, weather_period, n_days_expected,
                n_days_available, calendar_complete, dplyr::starts_with("n_valid_")) |>
  tidyr::pivot_longer(dplyr::starts_with("n_valid_"), names_prefix = "n_valid_",
                     names_to = "metric", values_to = "n_valid") |>
  dplyr::mutate(coverage_fraction = n_valid / n_days_expected,
                variable_complete = calendar_complete & n_valid == n_days_expected)
weather_wide <- weather_windows |>
  dplyr::select(measurement_year, growth_year, weather_period, dplyr::all_of(paper_config$weather_metrics)) |>
  tidyr::pivot_wider(names_from = weather_period, values_from = dplyr::all_of(paper_config$weather_metrics),
                     names_glue = "{weather_period}_{.value}")
weather_groups <- setNames(lapply(paper_config$weather_periods, function(period) {
  paste(period, paper_config$weather_metrics, sep = "_")
}), paper_config$weather_periods)

