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
## Weather hypothesis comparison decision 23 October 2026

- Compare the same eight biological hypotheses for each hybrid on the same 24 complete-weather years. Use original PAIC with a Gamma log link and hybrid-specific quadratic age. Do not use correlation strength to exclude predictors before model comparison.
- Summer rainfall plus temperature rank first for every hybrid; separation from the age-only model is weaker for Gibecq and Trichobel. AICc and single-year omission checks are exploratory under residual dependence and prior data inspection.
- Retain the verified 26-year summer model for the conditional absolute association plot and age shapes; clearly distinguish those 26 reporting years from the 24 common comparison years. Conditional coefficient intervals omit selection uncertainty. The selected grouped hypothesis does not establish both predictors are individually essential.
- Analysis 17 and scripts/update_weather_hypothesis_note.py are the current selection entry points. Preserve manual Word revisions and publication captions. Archive the retired correlation figure; keep earlier correlation tables as descriptive background. This decision supersedes earlier correlation-screen and four-candidate selection descriptions below.

# Scope and preparation decisions

## Current weather reporting decision 21 October 2026

- Use original PAIC and a single hybrid-specific quadratic age specification, retaining both age and age squared, to allow curved changes associated with stand development over time. It does not fully identify or remove temporal confounding. No preliminary response detrending or standardisation.
- Explain variable selection using the nine hypothesis-guided raw candidates. Compare quadratic age alone and the additions of summer rainfall, summer temperature, and both, on the same 26 years. Report the combined-weather absolute associations in the dot-and-whisker plot; provide fixed-weather quadratic age curves as supplementary material.
- Trichobel has the largest point estimates, but direct paired hybrid differences all have intervals including zero. Whiskers quantify uncertainty in mean associations, not annual variation in weather sensitivity. Its broader temperature interval does not establish lower sensitivity. Keep inference exploratory given residual dependence and rare extreme bootstrap contrasts.
- Retain previous-growth-year weather for multi-year annualised PAIC and state the unresolved within-interval growth timing. Explain observed growth; do not claim forecasting or causal attribution of Trichobel's advantage.
- Current code is analysis 14 and its figure helper/residual checks. Rebuild the current Word note with scripts/build_final_weather_note.py, preserving earlier versions. Archive superseded weather plots outside results/figures, retaining the three current figure stems and all growth, treatment and soil figures, including the separately saved Trichobel comparison.
- Earlier PCA, standardised-response and alternative-age reporting decisions below are historical where they conflict with this account.

## Agreed scope, 20 October 2026

- Paper combines material from thesis chapters 2 and 3, with scope and methods improved where agreed.
- Describe PAIC and MAIC through time, with PAIC a central contribution.
- Predict PAIC by hybrid from multivariate weather PCs, using previous-growth-year weather even for gaps between measurements. Measurement t maps to growth year t-1; no gap averaging of weather has been introduced.
- Set up treatment comparisons during active cultivation. A later decision may replace/refine treatment selection using central rows. Keep block/tree-row identifiers available.
- Present SOC stocks; BD and SOC% can support supplementary material.
- Develop scenarios jointly later, including an Excel workbook colleagues can edit without R.

## Transparent setup choices

- Primary tree-level PAIC/MAIC are the supplied workbook values, preserved without replacing them using reconstructed allometry. Recalculated stock/PAIC/MAIC are separate audit columns. This avoids silently revising previous results during project organisation.
- Weather response values remain the legacy hybrid summaries used by script05. `response_comparison.csv` compares them with tree-level medians. B/G/T agree closely; the R series has a small discrepancy to resolve before final analysis.
- Use the existing 1993-2004 **measurement-year** definition for the provisional active-treatment subset. Actual observed years stop at 2002 before the next visit in 2005. `growth_year`, interval endpoints and crossing flags allow later refinement. The 2005 increment spans the cessation boundary and is not automatically placed in the active subset.
- Six separate weather PCAs: winter, spring, summer, autumn, winterhalf and summerhalf. Each is shared across hybrids and uses complete weather observations in common positive-response years. This matches the current script05 basis because eligible response years coincide across hybrids. Retain enough axes for >=80% weather variance, as before.
- Keep previous daily missing-value aggregation for continuity (available-day means/sums). Add variable-level valid-day counts and fractions. Missingness policy is not yet a final analytical decision.
- Whole-profile SOC requires both 0-15 and 15-30 cm with observed stocks. Keep available-depth sums separately; do not label a one-depth sum as 0-30 cm.
- Starter weather models retain the existing Gamma(log) approach using PCs. They are a baseline for development, not a claim that the final model, age/time handling or uncertainty analysis has been settled.

## Thesis context checked

The source PDF is copied to `references/thesis_submitted.pdf`. Relevant context: PDF pages 64-70 (printed 44-50) for experimental design, allometry, carbon metrics and weather; PDF pages 97-99 (printed 77-79) for soil sampling and stocks.

The thesis describes planting in 1992, density 166 trees/ha, biomass-to-C factor 0.5, and cultivation ending after the 2004 harvest. It describes DBH visits between November and March; this setup follows the user's explicit t-1 weather convention. The source PDF supplies context, not instructions to reproduce every thesis analysis.

Taxon labels are transcribed from the thesis. Treatment A/C/F corresponds to alternate cropping/continuous cropping/continuous fallow. Soil tree-row/alley/reference codes are a separate location classification, not the same treatment factor.

## Open items

- Reporting clarification, 21 October 2026: prioritise absolute original-PAIC weather results; percentages are optional working background. Expand the final Word-summary section beyond one page to explain formulation, selection, bootstrap assumptions, uncertainty and interpretation. Absolute units allow declining PAIC over time; the reported positive fixed-weather contrasts are not net study-period changes. Existing model estimates are unchanged.

- Paper presentation decision, 21 October 2026: use the original PAIC absolute and percentage weather associations as a supporting exploratory analysis, rather than giving the standardised-departure analyses a main-paper role. Retain those analyses as background. Explain hypothesis-guided variable selection, previous-growth-year weather, annualised multi-year increments, age/weather confounding and provisional bootstrap uncertainty. A self-contained summary page is appended to manuscript/analysis_notes/02_weather_and_PAIC.docx.

- Weather modelling update: retain the existing t - 1 weather convention for multi-year increments, as explicitly confirmed by the user. PAIC is divided by elapsed sampling years, accounting for interval length; annualisation cannot recover the within-interval timing of growth. State this limitation in Methods and Discussion rather than treating unobserved years as observed annual growth.

- **Weather PCA review remains OPEN before final inference:** weather variance is not PAIC predictive relevance; the 80% retention rule may omit relevant axes. See [WEATHER_PCA_REVIEW.md](WEATHER_PCA_REVIEW.md) for the saved blog post, methodological reference, and follow-up checks. Combined four-season PCA is an exploratory analysis authorised on 20 October 2026.

- Explain/check supplied carbon calculations against recomputation, missing/zero/negative increments, and the small Robusta summary difference.
- Confirm final cultivated-year boundary and treatment/central-row design with colleague.
- Agree temporal modelling, allometric uncertainty and fair model-comparison/validation strategy before paper inference.
- Confirm weather variable coverage handling.
- Check soil spatial sampling metadata. The current raw soil sheet lacks block/tree-row/geographic coordinates, so the setup does not invent those variables or infer them from sampling ID.
- Agree scenario inputs and workbook design before building projections.


## Treatment analysis update, 20 October 2026

- PAIC is the treatment-analysis response. No explicit weather terms: categorical interval effects absorb shared temporal conditions.
- Retain all measured trees, aggregating to row-by-hybrid interval means; the five trees are subsamples. Retain block as a fixed design adjustment regardless of its p-value.
- Fit separate active and post-cropping models, plus active-with-boundary sensitivity. Cropping ended after the 2004 harvest. The 2002-2005 increment is handled explicitly as a cessation-boundary interval, not as post-cropping growth.
- Model treatment-by-hybrid-by-interval effects with row, row-hybrid and row-interval random intercepts. Report adjusted contrasts and diagnostics, not just significance tests.
- These initial models use equal weighting over observed intervals; no formal legacy disappearance date is inferred. Review variance and temporal dependence assumptions before final inference. See analysis/README.md.

## Figure conventions and treatment presentation, 20 October 2026

- Present this treatment analysis averaged across hybrids; retain hybrid and its interactions in the model. Hybrid main effects are significant, while treatment-by-hybrid interactions are not. Do not describe the latter as no hybrid effect.
- Use full treatment and hybrid names in reader-facing tables and figures, with original identifiers retained for reproducibility.
- Apply workspace plot_style.R: Okabe-Ito discrete colours, distinguishable symbols and line types, readable units and legends, 600 dpi PNG and vector PDF exports. Workspace AGENTS.md records these continuing preferences.

## Time-specific treatment claims

- Use phase-wide Holm correction across all three treatment pairs and all observed intervals for significance markers and claims identifying particular years. Preserve original within-interval comparisons as exploratory outputs.
- Focus contrast plots on continuous cropping versus each reference treatment, while retaining alternate cropping versus continuous fallow in the multiplicity family. Do not combine reference treatments on the basis of nonsignificance.
- Do not remove growth year 2013 (2014 measurement) as a presumed fluke. It does not survive phase-wide correction. The suggested post-cessation growth advantage remains a discussion hypothesis, not a demonstrated competition mechanism.

## Analysis notes for paper assembly

Five Word notes in manuscript/analysis_notes record methods, current results, discussion and decisions for growth, weather, cropping treatments, soil stocks and scenario planning. They should be updated when substantive analyses change; they are not refreshed automatically. Scenario planning is explicitly marked as not yet calculated.

The notes distinguish the measurement-gap issue from a causal explanation: the 2001 PAIC is a three-year average for growth years 1998-2000. Annualisation accounts for elapsed time, so missing visits do not inherently depress PAIC. Annual contributions within that interval remain unresolved, and attribution to weather needs an interval-aware analysis.


