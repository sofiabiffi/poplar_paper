# Current weather analysis on original PAIC

Updated 21 October 2026. The agreed reporting model uses original tree-derived hybrid median PAIC, summer rainfall and temperature, and hybrid-specific quadratic age trajectories. Both age and age squared are retained to allow curved PAIC changes associated with stand development over time. Age is a proxy for temporal development, not an independently identified causal age effect or a complete removal of confounding. Weather remains aligned to growth year t-1, including annualised multi-year PAIC.

Run from the workspace root: `Rscript --vanilla poplar_paper/analysis/14_raw_paic_weather_final.R`, then `Rscript --vanilla poplar_paper/analysis/14_raw_paic_weather_checks.R`. The main script sources `14_raw_paic_weather_figures.R`. Nine raw weather candidates are screened within hybrids; age-only, age plus summer rainfall, age plus summer temperature, and age plus both are compared on the same 26 years (16 fits). No preliminary detrending or standardisation is used. Candidate weather values are reused from weather_departure_screen_data.csv, but none of its standardised departures enter the models.

The active weather figure set contains only `final_weather_raw_screen`, `final_weather_hybrid_effects`, and supplementary `final_weather_quadratic_age_shapes`, with 600 dpi PNG, vector PDF and preview exports. Companion checks export residual diagnostics without recreating archived candidate scatterplots. Superseded weather plots were moved to archive/weather_figures_before_quadratic_final_2026-10-21, with a manifest and prior current model. Growth, treatment and soil figures and the saved Trichobel comparison were retained.

Model/table outputs are final_raw_paic_weather.rds and final_weather_* tables. Absolute weather contrasts use paired circular three-visit block-bootstrap intervals (1,000 replicates). The whiskers describe uncertainty in the mean associations, not variation in annual weather slopes. Trichobel has the largest point estimates, but all direct paired hybrid-difference intervals include zero. Rainfall intervals are above zero for all hybrids; Trichobel's temperature interval includes zero. Rare extreme quadratic-age bootstrap contrasts were retained and audited. Residual serial dependence and unstable tails limit inference.

Deviance-based pseudo-R² compares the full mean model with an intercept-only reference and describes age and weather together. Deviance reductions against quadratic age alone describe the added fitted weather contribution. Neither is a causal share of raw PAIC variance explained. AICc comparisons remain descriptive under residual dependence.

The current Word note is built by scripts/build_final_weather_note.py, which preserves a timestamped backup. Do not refresh it with the historical all-notes builder. Export its PDF using Word, render and inspect all changed pages before delivery. The note contains only the current account, variable selection, final dot-and-whisker figure and supplementary quadratic age shapes.

## Earlier analysis modules retained for reproducibility

# Analysis modules

Absolute PAIC weather associations: `Rscript --vanilla poplar_paper/analysis/13_absolute_weather_paic.R`. Original PAIC Gamma(log) models with fully interacting hybrid age trajectories and June-August rainfall/temperature. Absolute contrasts average over a common observed age distribution and compare weather values centred within the observed range; percentage contrasts are separate. Paired three-visit block-bootstrap intervals and direct hybrid comparisons are exploratory after screening. No further weather-variable search is introduced.

Hybrid summer-weather responses: `Rscript --vanilla poplar_paper/analysis/12_hybrid_weather_departures.R`. Fully interacting rainfall and temperature slopes on hybrid-specific standardised departures; direct paired slope differences with simultaneous exploratory bootstrap intervals. Three-visit circular blocks preserve hybrid pairing and short temporal structure; age trends/scales are refitted. Standardised and unstandardised log-scale slopes and linear-detrending sensitivities are distinct. In-sample time-series fits and residual dependence are reported; this is explanatory exploration, not forecasting.

Weather models of shared departures: `Rscript --vanilla poplar_paper/analysis/11_weather_departure_models.R`. Compares no weather, June-August rainfall, temperature, and both. Every held-out year or contiguous block has training-only hybrid age trends and residual scales. Linear-trend sensitivity is exported. This is a post-screen exploratory comparison, not nested validation of the earlier weather search. Large edge-block errors reveal age extrapolation instability. The weather Word note records the results and limits.

Weather screening of shared departures: `Rscript --vanilla poplar_paper/analysis/10_weather_departure_screen.R`. Nine predefined candidates are compared on 24 identical complete-coverage years, with available-year, rank, age-adjusted, linear-detrending and individual-hybrid sensitivities. Single-year omission ranges are influence diagnostics, not confidence intervals or held-out predictive validation. All figures, tables and the appended weather Word-note update distinguish calculated results from hypotheses.

Shared PAIC fluctuations: `Rscript --vanilla poplar_paper/analysis/09_paic_shared_fluctuations.R` uses tree medians from the descriptive figure, compares hybrid departures after separate log-scale age trends, and exports linear-trend and legacy-response sensitivity tables. The last ten observations form a descriptive subset, not a fitted change point. See the updated weather Word note for methods, results, hypotheses and open decisions.

Interpretable weather models: `Rscript --vanilla poplar_paper/analysis/07_weather_temperature_rainfall.R` from workspace root. Compares Gamma(log) hybrid-specific quadratic age trends plus a random measurement-year intercept against April-September temperature and rainfall, leaving whole years out. Predictions integrate over the unseen year random effect. Additional hybrid slopes and winter mean temperature are explored only if the shared weather model improves both held-out RMSE and Gamma deviance. These are exploratory comparisons, not nested validation of a selected final model. See results/tables/weather_temperature_rainfall_* and references/WEATHER_MODEL_NOTES.md.

Combined seasonal weather exploration: from the workspace root run `Rscript --vanilla poplar_paper/analysis/06_combined_seasonal_weather.R`. This reads prepared CSVs and saves separate combined-seasonal PCA/model tables, an RDS, and draft PNG/PDF figures. It retains enough PCs for 80% weather variance provisionally. **Before finalising weather results, revisit [the open PCA review](../references/WEATHER_PCA_REVIEW.md): weather variance does not determine PAIC relevance.** Final PC retention, validation, temporal adjustment and redundancy handling remain open.

Run the master `prepare_data.R` once at the start of the session. Then source an analysis module. For example, from the project root:

```r
source("prepare_data.R")
source("analysis/01_growth_descriptive.R")
```

Use `project_path("analysis", "01_growth_descriptive.R")` when your working directory is elsewhere.

The current scripts supply descriptive outputs, a baseline continuation of the existing PCA/Gamma weather models, a provisional active-treatment dataset, and SOC stock presentation. They establish a working starting point; final trend modelling, weather inference, treatment design, uncertainty and scenarios remain for discussion.


## PAIC treatment analysis

After `source("prepare_data.R")`, run:

```r
source("analysis/03_treatment_active.R")
```

The module fits separate active-cropping and post-cropping Gaussian mixed models of PAIC. All available measured trees contribute to equally weighted row-by-hybrid means for each observed growth interval. The treatment replicates are the three blocks, not the five trees per hybrid. Block remains a fixed adjustment; random intercepts for treatment row, row-by-hybrid, and row-by-interval represent shared and repeated observations. The full treatment-by-hybrid-by-interval interaction allows contrasts to change over time without imposing decay. Interval effects account for shared weather and other temporal conditions; no weather predictors are added.

Cropping ended after the 2004 harvest. The primary active fit uses intervals ending at the 2002 visit; the primary post fit starts with the 2005-2006 interval (growth year 2005). The 2002-2005 boundary interval includes growth years 2002-2004 under the adopted timing convention. It is excluded from both primary fits and included in a separate active-with-boundary sensitivity fit. No initial-visit PAIC is invented. The preparation objects' historical measurement-year phase labels remain unchanged; `treatment_model_data$analysis_phase` supplies the analysis-specific classification.

Results are available as `treatment_paic_results` and in `results/models/treatment_PAIC_models.rds`. Tables begin `results/tables/treatment_PAIC_`; plots begin `results/figures/treatment_PAIC_`. For each fit, review:

- `overall_contrasts`: C-F, A-F and C-A, equally averaged over hybrids and observed intervals (not weighted by interval duration).
- `hybrid_contrasts`: the same comparisons for each hybrid.
- `interval_contrasts`: comparisons for each hybrid and observed interval, for examining legacy trajectories.
- `tests`, `variance`, `residuals`, model text summaries and diagnostic plots.
- `interval_audit` and `row_means`: included growth intervals, nonpositive values, and tree counts. Nonpositive PAIC is retained; a Gamma model is not appropriate without further decisions.

Contrast confidence intervals and p-values use Bonferroni adjustment for three comparisons within each family (overall, each hybrid, or each hybrid-interval). They are not simultaneous across hybrids or time. Interval comparisons are exploratory; an isolated significant or nonsignificant interval cannot establish the duration of a legacy. No equivalence threshold has been specified. Post-cropping contrasts include consequences of earlier differences in tree size; they do not isolate a direct physiological carryover independent of size.

This is a first model to inspect. It assumes common residual variance and persistent within-group dependence through random intercepts. Residual spread, tails, and remaining serial dependence need review before publication-level inference; convergence alone does not validate these assumptions. With only three blocks, uncertainty in treatment effects remains substantial.

## Treatment presentation and workspace figure defaults

Treatment figures now show estimates averaged equally across all four hybrids. The model still adjusts for hybrid and its interactions; pooling the display does not pool the raw trees as independent replicates. `interval_contrasts` now holds the across-hybrid comparisons; the detailed comparisons remain in `hybrid_interval_contrasts` tables and `treatment_paic_results[[phase]]$hybrid_interval`. New `*_means.png` and `.pdf` figures show the three treatment trajectories directly. Both means and contrasts have colour-blind-safe colours, different symbols and line types. Model estimates are unchanged by this presentation update.

Do not report that hybrids have no significant effect: the hybrid main effect is significant in both primary models (active p=1.45e-6; post p=4.81e-13). The treatment-by-hybrid interaction is nonsignificant (active p=0.613; post p=0.570), as is the three-way interaction with interval (active p=0.900; post p=0.876). A suitable description is: "Treatment comparisons were averaged across hybrids; there was no clear evidence that treatment responses differed among hybrids." Nonsignificance is not evidence of equivalence.

The workspace-level `plot_style.R` is sourced by `library.R` and the older plotting scripts. Use `publication_scales()`, `theme_publication()` and `save_publication_plot()` for new figures. The latter exports 600 dpi PNG and vector PDF. Display tables use full names alongside retained identifiers. Existing historical image files are not automatically restyled until their generating scripts are run. The current paper's growth, treatment and SOC figures have been regenerated; older analysis scripts have updated defaults but were not rerun as part of this presentation change.

## Interval-wide multiplicity and significance markers

For claims that identify particular intervals after inspecting the time series, use `*_interval_inference.csv`, specifically `p_holm_phase`. This applies Holm adjustment to all three treatment pairs over all observed intervals within each phase: 21 active, 54 post-cropping, and 24 boundary-sensitivity tests. Keeping all three pairs in the family avoids retrospectively shrinking the family to the most interesting contrast. Active and post phases answer separate questions; the boundary fit remains a sensitivity analysis.

The older `*_interval_contrasts.csv` tables retain within-interval Bonferroni results for traceability. Their p-values must not be used as phase-wide evidence. The new inference tables include unadjusted p-values, phase-wide Holm p-values, family size and pointwise 95% confidence intervals. Holm adjustment is valid under arbitrary dependence (R stats documentation: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/p.adjust.html).

Main figures retain all three treatment mean trajectories. A * above an interval marks a continuous-cropping versus continuous-fallow difference; + marks a continuous-cropping versus alternate-cropping difference, both using phase-wide Holm p<0.05. Contrast figures focus on those two comparisons; stars there mark the corresponding contrast. Confidence intervals are explicitly pointwise, so a zero-excluding interval alone need not imply phase-wide significance. No markers means insufficient evidence of a difference, not equality.

Former continuous cropping exceeds former continuous fallow after correction in the 2008-2009 and 2009-2010 measurement intervals (growth years 2008 and 2009; Holm p=0.00242 and 0.0380). The broader positive pattern over growth years 2007-2010 is descriptive, not four separately significant years. The growth-year-2013 contrast does not survive phase-wide adjustment. No interval is removed as a presumed fluke. The two reference treatments remain distinct; alternate cropping is not continuous fallow.

Refresh presentation from saved models without refitting:

```r
source("prepare_data.R")
source("analysis/03b_refresh_treatment_figures.R")
source("scripts/check_treatment.R")
```
