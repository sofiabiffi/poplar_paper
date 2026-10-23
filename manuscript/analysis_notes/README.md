## Model standard errors for current weather reporting 23 October 2026

The user chose conventional model estimates and standard errors for this exploratory secondary analysis. Current analysis/14_raw_paic_weather_final.R no longer runs a bootstrap. It fits the same Gamma(log) models and calculates model-based SEs for the same absolute PAIC contrasts by the delta method using the full coefficient covariance matrix. All fitted coefficients are unchanged (maximum difference zero against the archived fit). Analytic contrast gradients agree with finite differences to less than 8e-11. Current effects table/figure use estimate +/-1 SE, not 95% confidence intervals. Conventional coefficient t tests and p-values are available in final_weather_coefficients.csv; both weather terms have nominal p<0.05 in each hybrid under the independent-observation model. Separate hybrid tests do not establish between-hybrid differences. No paired-bootstrap comparison is part of the current report.

Diagnostics were regenerated with analysis/14_raw_paic_weather_checks.R and inspected for distribution, variance pattern, temporal structure and influence. Current 26-year consecutive-calendar-year deviance-residual correlations are 0.351, 0.557, 0.289 and -0.005 for Beaupre, Gibecq, Robusta and Trichobel. Some influential observations, residual spread differences and temporal structure remain; conventional SEs/p-values may be optimistic. The Word note retains a proportionate independence qualification and exploratory interpretation. Precision of DBH measurements does not establish independence of annual growth. Diagnostic CSV/PDF and derivative audit are saved in results/checks. Earlier 24-year hypothesis ranking is unchanged.

The previous bootstrap model, source and outputs are preserved in archive/weather_before_model_se_20261023_160524. Retired bootstrap-only final tables were removed from the active tables folder after backup. The current Word note contains the final model-SE account only, retaining month windows and age-curve explanations. All eight pages were rendered and visually checked in _qa/weather_model_se_20261023. Current figure is final_weather_hybrid_effects (600 dpi PNG and vector PDF).

Word maintenance: run scripts/update_weather_model_se_note.py last after any older hypothesis/timing builders; do not run update_weather_bootstrap_note.py for the current account. The latest updater preserves a pre-edit Word backup. Earlier reporting instructions below are superseded where they conflict.
## Timing clarification and Word explanation, 23 October 2026

The current Word note includes expanded timing Methods on pages 2-3, verified against config.R, prep/01_tree_growth.R, prep/02_weather.R and analyses 10, 14 and 17, plus the earlier online discussion "Jyoti Code Walkthrough Thesis Analysis" (https://chatgpt.com/c/6a1ebf0c-89a8-8391-abab-ad1e97d666a1). Measurement year t uses growth year g = t - 1. Spring is March-May g; summer June-August g; autumn September-November g; preceding winter December g-1 through February g; winter half-year October g-1 through March g; summer half-year/dry-spell window April-September g. All boundaries are inclusive. The current eight-model comparison tests spring/summer predictors and the April-September dry spell; the prepared winter/autumn windows are not current candidates.

Daily temperature is averaged across daily means; rain and sunshine are summed. Required variables must have complete daily coverage. No additional gap filling is introduced. PAIC remains the supplied annualised response. Multi-year increments retain final-growth-year weather, not interval-average weather. The March measurement convention is supported by the earlier co-author discussion; the thesis gives November-March and individual visit dates are not available in the current tree table, so the note explicitly describes the adopted year-label convention without claiming verified March dates for every visit.

The supplementary age plot now has a plain-language explanation and is marked optional working material. Model estimates and figure files are unchanged. Timing checks are saved in results/checks/weather_timing_methods_audit.csv. The eight-page Word note was exported to PDF and every page visually inspected in manuscript/analysis_notes/_qa/weather_timing_final.

Maintenance: scripts/update_weather_timing_note.py updates the existing Word note in place and preserves a timestamped backup. Apply it after update_weather_hypothesis_note.py if rebuilding; older builders alone do not retain these expanded timing explanations. Export to a fresh QA PDF path before rendering with the packaged render_docx.py workflow.
## Current hypothesis comparison 23 October 2026

The current weather-selection workflow is analysis/17_weather_hypothesis_models.R. Run `Rscript --vanilla analysis/17_weather_hypothesis_models.R` from the project root, or pass the project directory as its first argument. It compares eight biological hypotheses separately for each hybrid, with original PAIC, Gamma log-link models and quadratic age throughout. No candidate is filtered by its PAIC correlation. Models are age alone; spring rainfall plus temperature; summer rainfall plus temperature; spring sunshine; summer sunshine; longest April-September dry spell; spring air frost; spring ground frost.

All 32 candidate fits use the same 24 complete-weather years (96 summaries), excluding measurement years 2001 and 2019. AICc includes Gamma dispersion in the parameter count. Summer rainfall and temperature rank first for all four hybrids; age alone ranks second, with delta AICc 5.98 / 2.30 / 5.85 / 2.13 for Beaupre / Gibecq / Robusta / Trichobel. After omission of each single year, summer remains first in 24 / 23 / 24 / 22 of 24 checks. These are influence checks, not independent validation. Residual serial correlation remains (summer-model lag-one residual correlations approximately 0.50 / 0.63 / 0.38 / 0.02), so independent-error AICc rankings are approximate. The eight-model candidate set was informed by earlier exploration and is not an independent prespecified test.

The reporting summer model uses all 26 years with complete summer weather. Its existing input PAIC and overlapping weather values were checked against the current data; the new hypothesis comparison does not change those estimates. Selection uses 24 common years, while the conditional summer association figure and age curves use 26. Their bootstrap intervals do not include model-selection uncertainty. The grouped summer hypothesis ranking does not prove both weather variables are individually necessary in each hybrid or show that hybrids have different biological responses.

Outputs: results/models/weather_hypothesis_models.rds; results/tables/weather_hypothesis_*; results/figures/weather_hypothesis_comparison (600 dpi PNG, vector PDF and preview); results/figure_descriptions/weather_hypothesis_comparison.txt. Reporting figures remain final_weather_hybrid_effects and final_weather_quadratic_age_shapes. The retired raw-correlation figure was moved to archive/weather_selection_before_hypothesis_comparison_2026-10-23; correlation tables remain descriptive background.

The current Word note is updated in place by scripts/update_weather_hypothesis_note.py. It preserves the previous Word version and retains other manual publication captions. Do not regenerate the new selection account with the older build_final_weather_note.py. Export the updated note with Word, then render with scripts/render_publication_notes.py and inspect every changed page. Existing source analyses and earlier notes below are historical wherever they conflict with this update.

## Earlier workflow details retained for reference

# Analysis notes for paper drafting

## Publication figure presentation updated 23 October 2026

The current PNG, PDF and preview figures omit overall titles, subtitles and explanatory footnotes. Facet labels, axes, legends, statistical letters and significance symbols remain. The associated Word notes contain expanded figure descriptions, including uncertainty definitions, model specifications and symbol meanings. Additional exported figures have descriptions at the end of the relevant note. Diagnostic plots are analysis checks rather than publication figures.

The project now uses its own `plot_style.R`. Run `Rscript --vanilla scripts/refresh_publication_figures.R` from this project folder to refresh presentation from existing models and prepared data. No treatment or weather model refitting is needed. Run `scripts/update_publication_figure_descriptions.py` then `scripts/finalise_publication_captions.py` with the bundled Python to refresh embedded figures and captions. The caption registry in `results/figure_descriptions/publication_captions.json` is also used by the current weather and general Word builders. Preserve and revise that registry if scientific definitions change. The historical all-notes builder still must not replace the current scientific accounts.

Prior Word versions are preserved in `_history/figure_presentation_*`. Export with `scripts/export_publication_notes.ps1`, rasterise with `scripts/render_publication_notes.py`, and visually inspect the resulting QA pages.

## Current weather note updated 21 October 2026

02_weather_and_PAIC.docx contains only the current original-PAIC analysis with hybrid-specific quadratic age, summer rainfall and temperature. It explains variable selection and stand-development adjustment, presents the final absolute dot-and-whisker figure, and includes fixed-weather quadratic age shapes as Figure S1. Whiskers describe uncertainty in mean associations, not annual variation in sensitivity. No preliminary detrending or response standardisation is required. Weather remains aligned to the preceding growth year, including annualised multi-year intervals.

The active figure stems are final_weather_raw_screen, final_weather_hybrid_effects and final_weather_quadratic_age_shapes. Superseded weather figures are in archive/weather_figures_before_quadratic_final_2026-10-21. Growth, treatment and soil figures and the separately saved Trichobel comparison remain in results/figures. Earlier Word versions, including manual edits, are preserved in _history.

Use analysis/14_raw_paic_weather_final.R and its companion diagnostics, then scripts/build_final_weather_note.py. Do not overwrite the current weather account using the original all-notes builder below. Export with Word and run scripts/render_analysis_notes.py; visually inspect the changed pages. QA files are internal. Other Word notes are unchanged.

## Original notes and general maintenance

Updated 20 October 2026. The five Word files cover tree growth, weather relationships with PAIC, cropping treatments and legacy, soil carbon stocks, and scenario planning. Each separates methods, calculated results, interpretation and outstanding decisions, with source pointers to the project files. Scenario planning has no new calculated results.

The notes explicitly explain that the 2001 PAIC is an annualised average over growth years 1998-2000. Missing visits reduce temporal resolution; they do not themselves cause low PAIC. The weather explanation has not yet been tested with predictors aligned to that entire interval.

These documents are reference notes to develop alongside the analyses. They are not refreshed automatically when R outputs change. Update the relevant Word note after a substantive analysis change, including its numerical values, interpretation and date. The script scripts/build_analysis_notes.py recreates the initial notes from project tables and recorded decisions; preserve manual Word revisions before rerunning it. QA renders are kept in _qa and are not manuscript deliverables.

Documents

- 01_tree_growth.docx
- 02_weather_and_PAIC.docx
- 03_cropping_treatment_and_legacy.docx
- 04_soil_carbon_stocks.docx
- 05_carbon_scenario_planning.docx

Treatment note update on 22 October 2026: the current expanded version is 03_cropping_treatment_and_legacy_updated_20261022.docx. It adds the pseudo-R model, the explicit block tests and design-based rationale for retaining block, and the active cropping figure. The earlier file could not be overwritten because it was locked; it remains unchanged. A backup was preserved in the QA folder. Use the expanded version for further edits.


Bootstrap explanation expanded 23 October 2026: page 6 of 02_weather_and_PAIC.docx now contains a simple explanation, paper-ready Methods wording and interpretation limits. Update in place with scripts/update_weather_bootstrap_note.py after the hypothesis and timing updaters if rebuilding. A pre-edit backup was retained in _history. The nine-page note was rendered and all pages visually checked in _qa/weather_bootstrap_final_20261023. No model estimates or figures changed.

