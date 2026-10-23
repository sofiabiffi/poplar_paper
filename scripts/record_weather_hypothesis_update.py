from pathlib import Path
import sys
root=Path(sys.argv[1])
entry='''## Current hypothesis comparison 23 October 2026

The current weather-selection workflow is analysis/17_weather_hypothesis_models.R. Run `Rscript --vanilla analysis/17_weather_hypothesis_models.R` from the project root, or pass the project directory as its first argument. It compares eight biological hypotheses separately for each hybrid, with original PAIC, Gamma log-link models and quadratic age throughout. No candidate is filtered by its PAIC correlation. Models are age alone; spring rainfall plus temperature; summer rainfall plus temperature; spring sunshine; summer sunshine; longest April-September dry spell; spring air frost; spring ground frost.

All 32 candidate fits use the same 24 complete-weather years (96 summaries), excluding measurement years 2001 and 2019. AICc includes Gamma dispersion in the parameter count. Summer rainfall and temperature rank first for all four hybrids; age alone ranks second, with delta AICc 5.98 / 2.30 / 5.85 / 2.13 for Beaupre / Gibecq / Robusta / Trichobel. After omission of each single year, summer remains first in 24 / 23 / 24 / 22 of 24 checks. These are influence checks, not independent validation. Residual serial correlation remains (summer-model lag-one residual correlations approximately 0.50 / 0.63 / 0.38 / 0.02), so independent-error AICc rankings are approximate. The eight-model candidate set was informed by earlier exploration and is not an independent prespecified test.

The reporting summer model uses all 26 years with complete summer weather. Its existing input PAIC and overlapping weather values were checked against the current data; the new hypothesis comparison does not change those estimates. Selection uses 24 common years, while the conditional summer association figure and age curves use 26. Their bootstrap intervals do not include model-selection uncertainty. The grouped summer hypothesis ranking does not prove both weather variables are individually necessary in each hybrid or show that hybrids have different biological responses.

Outputs: results/models/weather_hypothesis_models.rds; results/tables/weather_hypothesis_*; results/figures/weather_hypothesis_comparison (600 dpi PNG, vector PDF and preview); results/figure_descriptions/weather_hypothesis_comparison.txt. Reporting figures remain final_weather_hybrid_effects and final_weather_quadratic_age_shapes. The retired raw-correlation figure was moved to archive/weather_selection_before_hypothesis_comparison_2026-10-23; correlation tables remain descriptive background.

The current Word note is updated in place by scripts/update_weather_hypothesis_note.py. It preserves the previous Word version and retains other manual publication captions. Do not regenerate the new selection account with the older build_final_weather_note.py. Export the updated note with Word, then render with scripts/render_publication_notes.py and inspect every changed page. Existing source analyses and earlier notes below are historical wherever they conflict with this update.

'''
for rel in ['analysis/README.md','references/WEATHER_MODEL_NOTES.md','manuscript/analysis_notes/README.md']:
    path=root/rel
    text=path.read_text(encoding='utf-8-sig')
    if '## Current hypothesis comparison 23 October 2026' in text:
        continue
    path.write_text(entry+'## Earlier workflow details retained for reference\n\n'+text,encoding='utf-8')
path=root/'references/DECISIONS.md'
text=path.read_text(encoding='utf-8-sig')
decision='''## Weather hypothesis comparison decision 23 October 2026

- Compare the same eight biological hypotheses for each hybrid on the same 24 complete-weather years. Use original PAIC with a Gamma log link and hybrid-specific quadratic age. Do not use correlation strength to exclude predictors before model comparison.
- Summer rainfall plus temperature rank first for every hybrid; separation from the age-only model is weaker for Gibecq and Trichobel. AICc and single-year omission checks are exploratory under residual dependence and prior data inspection.
- Retain the verified 26-year summer model for the conditional absolute association plot and age shapes; clearly distinguish those 26 reporting years from the 24 common comparison years. Conditional coefficient intervals omit selection uncertainty. The selected grouped hypothesis does not establish both predictors are individually essential.
- Analysis 17 and scripts/update_weather_hypothesis_note.py are the current selection entry points. Preserve manual Word revisions and publication captions. Archive the retired correlation figure; keep earlier correlation tables as descriptive background. This decision supersedes earlier correlation-screen and four-candidate selection descriptions below.

'''
if '## Weather hypothesis comparison decision 23 October 2026' not in text:
    path.write_text(decision+text,encoding='utf-8')
archive=root/'archive/weather_selection_before_hypothesis_comparison_2026-10-23'
(archive/'README.md').write_text('''# Retired correlation figure

The three final_weather_raw_screen figure files were moved here on 23 October 2026 when direct hypothesis-model comparison replaced correlation filtering as the selection workflow. Raw correlations remain descriptive background; their tables were retained. The active selection figure is weather_hypothesis_comparison, while the 26-year conditional summer-weather association and age-shape figures remain current. Earlier Word versions were backed up before editing, including their manually revised publication captions.
''',encoding='utf-8')
print('Recorded current hypothesis comparison and reporting-sample distinction.')
