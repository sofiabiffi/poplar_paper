from pathlib import Path
from datetime import datetime
import csv,shutil,json
root=Path(__file__).resolve().parents[1]
ns={'__file__':str(root/'scripts/build_analysis_notes.py')};exec((root/'scripts/build_analysis_notes.py').read_text().split('# Growth')[0],ns)
make,h,p,table,picture,save=[ns[k] for k in ('make','h','p','table','picture','save')]
read=lambda name:list(csv.DictReader((root/'results/tables'/name).open(encoding='utf-8-sig')))
s=read('soc_sequestration_ESM_summary.csv');t=next(r for r in s if r['group_code']=='trees');base=float(t['arable_reference_mean_mg_ha'])
rate=float(t['annualised_SOC_excess_mg_ha_yr']);sd_rate=float(t['sd_annualised_SOC_excess_mg_ha_yr'])
path=root/'manuscript/analysis_notes/06_soc_sequestration.docx'
if path.exists():(path.parent/'_history').mkdir(parents=True, exist_ok=True); shutil.copy2(path,path.parent/'_history'/('06_soc_sequestration_before_uncertainty_'+datetime.now().strftime('%Y%m%d_%H%M%S')+'.docx'))
d=make('SOC accumulation relative to the arable reference',f'The mean annualised tree-row SOC accumulation estimate is {rate:.3f} Mg C per hectare per year, with SD {sd_rate:.3f}. It is the 2024 tree-row ESM stock excess over the measured fixed-depth arable reference, divided by 32 years. The table below provides the result intended for manuscript reporting.')
d.paragraphs[1].text='Analysis notes for paper drafting   |   Updated 27 October 2026'
h(d,'Methods')
p(d,'The fields formed one arable field before silvoarable establishment in 1992. Soil sampling took place in 2024. The adjacent reference remained arable. Agreed durations are 32 years for tree rows and Continuous fallow alleys, and 19 years for Continuous cropping alleys following the final August 2004 harvest. These are fixed analysis conventions. Tree rows pool all former cropping treatments by available complete core; Alternate cropping alleys are excluded from the rate comparison.')
p(d,'Measurements are from data/raw/study_site_soil_2024.csv. Arable profiles retain their measured fixed-depth 0 to 30 cm stocks. Only alley and tree-row profiles are ESM corrected using straight segments through cumulative soil-mass and SOC endpoints, with arable mean layer masses defining the reference (1775.33 and 3733.24 Mg soil per hectare). Complete agroforestry profiles can extend their final segment using measured lower-layer SOC concentration. Upper-only profiles receive no total or annualised total-stock rate. Supplied fine BD is retained; the fine-BD volume denominator and any required coarse-fragment adjustment remain an open measurement-basis check.')
p(d,f'For each complete agroforestry core j, calculate delta SOC_j = total ESM stock_j minus the mean arable fixed-depth stock ({base:.6f} Mg C per hectare), then divide by its agreed duration. Average the core-level rates. All 21 complete tree-row and 47 complete arable profiles contribute to the primary contrast. The arable zero in figures is a defined comparison reference, not an estimate of zero change in the field.')
p(d,'Uncertainty is reported as SD among the complete profile-level annualised rates. The shared mean fixed-depth arable reference is held constant for every profile. Therefore rate SD equals tree-row stock SD divided by 32 years. SD describes variation among sampled profiles, not a confidence interval for the mean; uncertainty in the arable mean, reference masses and the ESM extrapolation model is not propagated.')
h(d,'Tree row result for the manuscript')
table(d,['Land cover','Tree cores','Arable cores','Years','Rate mean and SD'],[['Tree row','21','47','32',f'{rate:.3f} +/- {sd_rate:.3f}']],[1.15,.8,.85,.6,2.7])
p(d,'Rate units are Mg C per hectare of tree-row area per year. The reported mean and SD are conditional on the shared arable baseline and agreed duration. They do not quantify field-level replication, historical baseline differences, measurement-basis uncertainty, the extrapolation model or national transfer. The estimate is not a directly observed annual flux. The machine-readable manuscript table is results/tables/soc_tree_row_rate_manuscript.csv.')
d.add_page_break();h(d,'Supplementary tabular results')
body=[]
for r in s:
 sd=f"{float(r['sd_annualised_SOC_excess_mg_ha_yr']):.3f}" if r['duration_years'] else 'Not applicable'
 body.append([r['group'],r['n_complete_profiles'],f"{float(r['mean_SOC_stock_mg_ha']):.2f}",f"{float(r['mean_SOC_excess_mg_ha']):.2f}",f"{float(r['annualised_SOC_excess_mg_ha_yr']):.3f}" if r['duration_years'] else '0 reference',sd])
table(d,['Group','n','Stock','Excess','Rate','Rate SD'],body,[1.9,.35,.7,.7,.7,1.5])
p(d,'Stocks and excesses are Mg C per hectare; rates and their SDs are Mg C per hectare per year. Arable stocks are fixed depth; other stocks are ESM corrected. Alley fallow of 19 years corresponds to former Continuous cropping; alley fallow of 32 years corresponds to Continuous fallow. No rate is estimated for Alternate cropping alleys.')
table(d,['Group','Stock SD','Rate SD','Extended / n','Excluded'],[[r['group'],f"{float(r['sd_SOC_stock_mg_ha']):.2f}",f"{float(r['sd_annualised_SOC_excess_mg_ha_yr']):.3f}" if r['duration_years'] else '-',r['n_extrapolated']+' / '+r['n_complete_profiles'],r['n_excluded_profiles']] for r in s],[2.3,.8,.8,1.1,.85])
p(d,'SD is variation among cores. Rate SD is stock SD divided by duration and holds the shared arable mean fixed; it is not the uncertainty of the mean. Reference-mean and reference-mass uncertainty are not propagated. Seventeen of 21 complete tree cores require extension beyond measured 30 cm, reaching at most 44.9 cm equivalent depth. Three upper-only tree cores and one upper-only arable core are excluded from totals. Source and profile tables retain permanent company IDs.')
h(d,'Discussion hypotheses')
p(d,'These estimates are retrospective space-for-time stock contrasts. The arable reference is a counterfactual rather than a measured initial stock; excess may include avoided loss as well as accumulation. The 19-year alley contrast may retain tree effects preceding cessation in 2004 and cannot isolate subsequent grassland accumulation. Each alley former treatment occupies one sampled block and band. Tree cores span three bands but do not constitute replicated conversions. No treatment significance tests are performed for these rates.')
h(d,'Open decisions')
p(d,'Review the fine-BD definition, spatial dependence, baseline comparability, management history and sensitivity to lower-layer extension before final inferential wording. Profile SD does not establish independent field replication. Applying historical rates unchanged through a future programme assumes a trajectory, and requires an explicit area basis. Only tree-row rates are transferred into the current upscaling; grassland and alleys receive zero additional SOC credit there.')
d.add_page_break();h(d,'Stocks and annualised accumulation')
picture(d,'soc_sequestration_ESM_stocks.png','Figure 1 Mean measured fixed-depth arable stock and ESM-corrected alley/tree-row stocks at the arable 0 to 30 cm reference mass. Error bars show profile SD, not confidence intervals. The dashed line marks the fixed-depth arable mean.',6.1)
picture(d,'soc_sequestration_ESM_rates.png','Figure 2 Annualised agroforestry ESM excess over the mean arable fixed-depth stock. Bars show SD among profile-level annualised rates, holding the shared arable mean fixed. They are not confidence intervals. Arable zero is the comparison reference. Rates are per hectare of sampled land cover.',6.1)
save(d,'06_soc_sequestration.docx')
