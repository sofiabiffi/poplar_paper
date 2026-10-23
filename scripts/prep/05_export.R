paper_data <- list(
  tree_growth = tree_growth, annual_hybrid = annual_hybrid,
  annual_hybrid_treatment = annual_hybrid_treatment, growth_descriptive = growth_descriptive,
  tree_treatment_active = tree_treatment_active, tree_phase_means = tree_phase_means,
  weather_daily = weather_daily, weather_windows = weather_windows,
  weather_wide = weather_wide, weather_coverage = weather_coverage,
  growth_weather = growth_weather, growth_weather_pcs = growth_weather_pcs,
  weather_pc_scores = weather_pc_scores, weather_pca_loadings = weather_pca_loadings,
  weather_pca_variance = weather_pca_variance, weather_pca_scaling = weather_pca_scaling,
  soil_depth = soil_depth, soil_profiles = soil_profiles,
  soil_profile_complete = soil_profile_complete, soil_stock_summary = soil_stock_summary,
  soil_depth_summary = soil_depth_summary, legacy_hybrid_responses = legacy_hybrid_responses
)
for (name in names(paper_data)) {
  utils::write.csv(paper_data[[name]], project_path("data", "processed", paste0(name, ".csv")),
                   row.names = FALSE, na = "")
}
saveRDS(paper_data, project_path("data", "processed", "paper_data.rds"))
saveRDS(weather_pca, project_path("data", "processed", "weather_pca.rds"))
saveRDS(list(config = paper_config, hybrid_key = hybrid_key, treatment_key = treatment_key,
              soil_location_key = soil_location_key), project_path("data", "processed", "preparation_config.rds"))
checks <- list(tree_response_audit = tree_response_audit, response_comparison = response_comparison,
  weather_coverage = weather_coverage, weather_window_definitions = weather_window_definitions,
  weather_pca_exclusions = weather_pca_exclusions,
  incomplete_soil_profiles = dplyr::filter(soil_profiles, !profile_complete))
for (name in names(checks)) utils::write.csv(checks[[name]],
  project_path("results", "checks", paste0(name, ".csv")), row.names = FALSE, na = "")
data_inventory <- tibble::tibble(dataset = names(paper_data),
  rows = vapply(paper_data, nrow, integer(1)), columns = vapply(paper_data, ncol, integer(1)))
utils::write.csv(data_inventory, project_path("results", "checks", "prepared_dataset_inventory.csv"), row.names = FALSE)
utils::write.csv(hybrid_key, project_path("data", "processed", "hybrid_key.csv"), row.names = FALSE)
utils::write.csv(treatment_key, project_path("data", "processed", "treatment_key.csv"), row.names = FALSE)
utils::write.csv(soil_location_key, project_path("data", "processed", "soil_location_key.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = project_path("results", "checks", "session_info.txt"))

