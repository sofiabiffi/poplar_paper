from pathlib import Path
from datetime import datetime
import csv,shutil
from docx import Document
from docx.shared import Inches
root=Path(__file__).resolve().parents[1]
path=root/'manuscript/analysis_notes/02_weather_and_PAIC.docx'
d=Document(path);title='Weather associations in absolute carbon increment units'
if any(p.text==title for p in d.paragraphs):raise RuntimeError('Already updated.')
def read(n):
    with (root/f'results/tables/absolute_weather_{n}.csv').open(newline='') as f:return list(csv.DictReader(f))
rows=read('adjusted_differences');contrasts=read('paired_differences');linear=read('linear_age_sensitivity')
history=path.parent/'_history';history.mkdir(exist_ok=True)
shutil.copy2(path,history/f'{path.stem}_before_absolute_weather_{datetime.now():%Y%m%d_%H%M%S}.docx')
d.add_page_break();d.add_heading(title,1)
d.add_paragraph('Update 20 October 2026. Retain the same June to August mean air temperature and rainfall predictors, without further screening. This analysis expresses adjusted associations directly in Mg C per hectare per year and in percentages, complementing the standardised departure analysis.')
d.add_heading('Methods',2)
d.add_paragraph('Fit original positive PAIC with Gamma log-link models, allowing each hybrid its own intercept, quadratic age trajectory and rainfall and temperature slopes. This is equivalent in fitted means to a fully interacting joint model, verified numerically. No response standardisation or preliminary detrending is used. Use the same 26 years and tree-level hybrid medians. Retain the confirmed measurement-year t to growth-year t minus 1 alignment, including annualised multi-year increments.')
t=next(x for x in rows if x['term']=='temperature');r=next(x for x in rows if x['term']=='rainfall')
d.add_paragraph(f"Average adjusted predictions over the same 26 observed ages for all hybrids. Temperature contrasts compare {float(t['lower_weather']):.2f} with {float(t['upper_weather']):.2f} degrees C, holding rainfall at its observed mean. Rainfall contrasts compare {float(r['lower_weather']):.1f} with {float(r['upper_weather']):.1f} mm, holding temperature at its mean. These are 1 degree C and 100 mm differences centred within the observed range, not extrapolated warming scenarios. They are model-adjusted comparisons across a common age distribution, not changes observed in a particular pair of years.")
d.add_paragraph('Use 1000 paired circular block-bootstrap samples of three observed visits, retaining all hybrids within each visit and refitting the full models. Report pointwise percentile intervals for effects and direct pairwise differences. These are exploratory intervals without multiplicity adjustment; none of the pairwise intervals exclude zero. Rare bootstrap fits give extreme absolute contrasts when age ranges are poorly represented; tail diagnostics are exported and no replicates are discarded. Percentile intervals avoid treating those tails as approximately normal, but do not resolve age-extrapolation instability. Blocks may span sampling gaps. Percent differences need not rank hybrids like absolute differences.')
d.add_heading('Calculated results',2)
for h in ['Beaupre','Gibecq','Robusta','Trichobel']:
    t=next(x for x in rows if x['hybrid']==h and x['term']=='temperature');r=next(x for x in rows if x['hybrid']==h and x['term']=='rainfall')
    d.add_paragraph(f"{h}: temperature contrast {float(t['absolute_difference']):+.2f} Mg C per hectare per year ({float(t['percent_difference']):+.1f} percent); rainfall contrast {float(r['absolute_difference']):+.2f} ({float(r['percent_difference']):+.1f} percent). The exported figure and tables include uncertainty intervals.")
n=sum(x['interval_excludes_zero']=='TRUE' for x in contrasts)
d.add_paragraph(f'Of the 12 direct pairwise absolute-effect comparisons, {n} have pointwise paired bootstrap intervals excluding zero. This is an exploratory post-screen comparison, not confirmation of causal differences. Linear age-trend results are exported as a separate sensitivity and should be considered before selecting a final specification.')
d.add_heading('Discussion and open decisions',2)
d.add_paragraph('Absolute responses combine baseline carbon increment with the proportional weather association. A faster-growing hybrid can therefore have a larger absolute response without a larger percentage or standardised response. Neither metric establishes heat tolerance. Associations are adjusted for the chosen age trajectory; this cannot separate age from calendar-time trends or cultivation history in one planting cohort. Previously detected residual temporal structure remains relevant. Variable selection uncertainty, block length, age specification, weather coverage and sampling-gap limitations remain open; the response now matches original PAIC units, not a forecasting objective.')
d.add_page_break();d.add_heading('Adjusted carbon increment differences',1)
d.add_picture(str(root/'results/figures/absolute_weather_differences_preview.png'),width=Inches(6.65))
d.add_paragraph('Pointwise block-bootstrap intervals for absolute contrasts averaged over the same observed age distribution. Direct hybrid comparisons use paired percentile intervals in the accompanying table. Curves in original PAIC units are saved separately.',style='Caption')
d.add_heading('Reproducible sources',2)
d.add_paragraph('analysis/13_absolute_weather_paic.R; results/tables/absolute_weather_adjusted_differences.csv; absolute_weather_paired_differences.csv; absolute_weather_linear_age_sensitivity.csv; absolute_weather_coefficients.csv; absolute_weather_diagnostics.csv; results/models/absolute_weather_paic.rds. Figures: absolute_weather_curves and absolute_weather_differences, PNG and PDF.')
d.save(path);print(path)
