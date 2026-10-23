# Authoritative study-site measurements and permanent company core IDs.
soil_source <- read.csv(project_path("data", "raw", "study_site_soil_2024.csv"),
                        fileEncoding="UTF-8-BOM", stringsAsFactors=FALSE, check.names=FALSE)
require_columns(soil_source, c("profile_id", "sample_id", "location_code", "location",
  "company_core_number", "depth_interval_cm", "depth_top_cm", "depth_bottom_cm",
  "depth_thickness_cm", "fine_bd_gcm3", "SOC_perc", "former_treatment_code", "sampling_year"), "Soil source")
soil_depth <- soil_source |>
  dplyr::rename(bulk_density_g_cm3=fine_bd_gcm3, SOC_percent=SOC_perc) |>
  dplyr::mutate(sampling_id=company_core_number,
    SOC_stock_mg_ha=bulk_density_g_cm3 * depth_thickness_cm * SOC_percent)
if (anyNA(soil_depth$bulk_density_g_cm3) || anyNA(soil_depth$SOC_percent) ||
    any(soil_depth$bulk_density_g_cm3 <= 0) || any(soil_depth$SOC_percent < 0) ||
    any(!soil_depth$depth_interval_cm %in% c("0-15","15-30")) ||
    any(soil_depth$depth_thickness_cm != soil_depth$depth_bottom_cm-soil_depth$depth_top_cm) ||
    any(soil_depth$depth_thickness_cm <= 0) || any(soil_depth$sampling_year != 2024))
  stop("Invalid soil measurement, depth or year")
loc_match <- match(soil_depth$location_code,soil_location_key$location_code)
if (anyNA(loc_match) || any(soil_depth$location != soil_location_key$location[loc_match]))
  stop("Unmapped or inconsistent soil location")
assert_unique(soil_depth, c("sample_id"), "soil samples")
assert_unique(soil_depth, c("profile_id", "depth_interval_cm"), "soil depths")
soil_profile_metadata <- soil_depth |>
  dplyr::select(profile_id, sample_id, location_code, location, company_core_number,
    former_treatment_code, former_treatment, block, tree_row, spatial_band,
    sampling_year, latitude, longitude, field_id, strata_id, legacy_profile_id,
    legacy_potential_samplingID, legacy_location_code) |>
  dplyr::select(-sample_id, -location_code, -location) |> dplyr::distinct()
assert_unique(soil_profile_metadata,"profile_id","soil profile metadata")
soil_profiles <- soil_depth |>
  dplyr::group_by(profile_id, sampling_id, location_code, location) |>
  dplyr::summarise(
    n_depths = dplyr::n(),
    profile_complete = all(c("0-15", "15-30") %in% depth_interval_cm) &
      sum(depth_thickness_cm) == 30 & all(!is.na(SOC_stock_mg_ha)),
    SOC_stock_available_depths_mg_ha = safe_sum(SOC_stock_mg_ha),
    mean_BD_available_depths = safe_mean(bulk_density_g_cm3),
    mean_SOC_percent_available_depths = safe_mean(SOC_percent), .groups = "drop"
  ) |>
  dplyr::mutate(SOC_stock_0_30_mg_ha = ifelse(profile_complete,
                    SOC_stock_available_depths_mg_ha, NA_real_))
soil_profiles <- dplyr::left_join(soil_profiles,soil_profile_metadata,by="profile_id")
soil_profile_complete <- dplyr::filter(soil_profiles, profile_complete)
soil_stock_summary <- soil_profile_complete |>
  dplyr::group_by(location_code, location) |>
  dplyr::summarise(n_profiles = dplyr::n(), mean = mean(SOC_stock_0_30_mg_ha),
    median = median(SOC_stock_0_30_mg_ha), sd = sd(SOC_stock_0_30_mg_ha),
    q25 = safe_quantile(SOC_stock_0_30_mg_ha, .25),
    q75 = safe_quantile(SOC_stock_0_30_mg_ha, .75), .groups = "drop")
soil_depth_summary <- soil_depth |>
  dplyr::group_by(location_code, location, depth_interval_cm) |>
  dplyr::summarise(n = dplyr::n(), mean_SOC_stock = safe_mean(SOC_stock_mg_ha),
    median_SOC_stock = safe_median(SOC_stock_mg_ha), mean_BD = safe_mean(bulk_density_g_cm3),
    mean_SOC_percent = safe_mean(SOC_percent), .groups = "drop")

