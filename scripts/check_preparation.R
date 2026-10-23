# Data-integrity checks, run after prepare_data.R. No model p-values are tested.
if (!exists("paper_data")) stop("Source prepare_data.R first")
checks_passed <- character()
check <- function(condition, label) {
  if (!isTRUE(condition)) stop("Preparation check failed: ", label)
  checks_passed <<- c(checks_passed, label)
}
check(nrow(tree_growth) == nrow(tree_source), "All supplied tree records preserved")
check(dplyr::n_distinct(tree_growth$tree_id) == 180L, "180 tree IDs")
check(!anyDuplicated(tree_growth[c("tree_id", "measurement_year")]), "Unique tree/visit keys")
check(all(tree_growth$growth_year == tree_growth$measurement_year - 1L), "Requested previous-year alignment")
check(identical(sort(unique(tree_growth$measurement_year[tree_growth$multi_year_increment])), c(2001L, 2005L)),
      "Three-year intervals retained and flagged")
check(all(tree_treatment_active$measurement_year <= 2004L), "Active subset uses agreed measurement-year cutoff")
check(all(c("block", "tree_row", "treatment_code") %in% names(tree_treatment_active)), "Design IDs retained")
ex <- dplyr::filter(weather_windows, measurement_year == 2002L, weather_period == "winter")
check(ex$start_date == as.Date("2000-12-01") && ex$end_date == as.Date("2001-02-28"), "Winter crosses calendar-year boundary correctly")
check(nrow(weather_windows) == 31L * 6L, "All requested weather windows represented")
check(all(weather_coverage$n_valid <= weather_coverage$n_days_expected), "Valid-day counts bounded")
check(all(is.na(soil_profiles$SOC_stock_0_30_mg_ha[!soil_profiles$profile_complete])), "Incomplete profiles not labelled 0-30 cm")
check(nrow(soil_profile_complete) == 92L && nrow(soil_depth) == 188L, "Complete profiles and original soil rows accounted for")
for (period in names(weather_pca)) {
  p <- weather_pca[[period]]
  check(p$n == if (period %in% c("winter", "winterhalf")) 24L else 23L,
        paste("PCA complete-case sample:", period))
  check(sum(p$variance$proportion_variance[p$variance$retained]) >= .80 - 1e-10,
        paste("PCA retained variance:", period))
  check(max(abs(crossprod(p$pca$rotation) - diag(ncol(p$pca$rotation)))) < 1e-8,
        paste("PCA loadings orthonormal:", period))
}
roundtrip <- readRDS(project_path("data", "processed", "paper_data.rds"))
check(identical(roundtrip, paper_data), "RDS round-trip preserves all tables")
utils::write.csv(data.frame(check = checks_passed, status = "PASS"),
  project_path("results", "checks", "validation.csv"), row.names = FALSE)
message(length(checks_passed), " preparation integrity checks passed.")

