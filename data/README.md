# Data conventions

`raw/` contains source workbooks and the study-site soil CSV. Preparation never edits them. Their hashes and original locations are in `references/source_manifest.csv`. `processed/` contains regenerated tables and RDS objects.

## Tree growth

- `measurement_year` is the year attached to the DBH visit in the supplied data. No missing visits are interpolated.
- `growth_year = measurement_year - 1`, including when an increment spans more than one year, as requested.
- `age_years = measurement_year - 1992`.
- `PAIC` is the supplied periodic annual C increment, Mg C ha-1 yr-1; `MAIC` is the supplied mean annual C increment since planting, in the same units.
- `carbon_stock_mg_ha` is the supplied per-hectare AGB C stock.
- Columns ending `_recalculated` are audit calculations using supplied DBH/allometry, density 166 trees/ha and carbon fraction 0.5. They do not overwrite the primary responses.
- `interval_years` and interval endpoints identify measurement gaps. `multi_year_increment` and `interval_crosses_cropping_end` are flags for interpretation and later sensitivity checks, not exclusion rules for weather analysis.
- `tree_treatment_active` follows the existing measurement-year cutoff of 2004. Keep `block`, `tree_row` and `tree_id` for the final experimental/repeated-measure design.

Annual tables use long format: one row per group and `metric` (PAIC, MAIC or stock). `n_valid` and quartiles refer to observed tree values, with no imputation. In contrast, `growth_descriptive` pools available visits and should not be read as a statistical model accounting for repeated trees.

## Weather and PCA

Daily temperature, soil temperature and wind are averaged within windows; rainfall, sunshine, frost/growing/windy days and GDD are summed. Window dates and metric-valid counts are explicit. Partial daily records follow the prior workflow's available-day aggregation, while incomplete calendar windows are masked. `weather_coverage` distinguishes both cases.

`growth_weather` preserves the legacy hybrid median response series used by the old weather analysis. `annual_hybrid` is rebuilt from individual tree values. The comparison is saved in `results/checks/response_comparison.csv`; the two sources are not silently substituted.

Each period has its own standardised weather PCA on common complete-case response years. PC1 in summer is not the same gradient as PC1 in winter. `weather_pca` retains the prcomp objects and centring/scaling; score/loadings/variance tables retain year and period identifiers. PC scores retain their original PCA scale.

## Soil

`SOC_percent` is a percentage, not a g/kg value or fraction. Depth-specific stock uses BD (g cm-3) x thickness (cm) x SOC (%), yielding Mg C ha-1.

The soil analysis reads `raw/study_site_soil_2024.csv` with full-precision fine BD and SOC measurements. Permanent company core IDs define `profile_id`, and permanent sample IDs identify layers. Land cover is Arable reference (48 cores), Alley (24) or Tree row (24); there are 188 layers and 92 complete profiles. Company core 016 in reference Field 1 belongs to Arable reference. Legacy IDs remain audit fields.

Soil location differs from former cropping treatment. The CSV includes confirmed block, original tree-row and former-treatment metadata for agroforestry cores; arable reference has no experimental treatment or block assignment. Former treatment is confounded with sampled band and block in this subset. Coordinates are retained rather than inferred from profile numbers.

Run `analysis/04_soc_stocks.R` for fixed-depth stocks, linear ESM outputs and supplementary BD/SOC-content summaries with Dunn/BH letters. It reloads the raw CSV, refreshes soil processed CSVs and soil members of `paper_data.rds`, and records the source hash in `results/checks/soc_source_audit.csv`. ESM uses arable mean layer masses and straight segments through cumulative endpoints; upper-only shallow-bedrock profiles receive an upper reference estimate but no lower increment or total. Mass-weighted BD and arithmetic-average SOC content describe complete measured 0-30 cm profiles. The supplementary facet key uses company core numbers, linked to permanent IDs in `soc_ESM_figure_profile_key.csv`.

`soil_profiles` preserves all profiles and available-depth stock sums. Its `SOC_stock_0_30_mg_ha` is missing unless both expected depths are present with observed stocks. `soil_profile_complete` supplies the complete-profile analysis set.

No stock difference is automatically converted to a SOC sequestration rate in this setup.
