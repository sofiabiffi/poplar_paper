from pathlib import Path
import csv,shutil
from datetime import datetime
root=Path(__file__).resolve().parents[1]
ns={'__file__':str(root/'scripts/build_analysis_notes.py')}
exec((root/'scripts/build_analysis_notes.py').read_text().split('# Growth')[0],ns)
make,h,p,table,save=[ns[k] for k in ('make','h','p','table','save')]
name='06_soc_sequestration.docx';target=root/'manuscript/analysis_notes'/name
if target.exists():
    (target.parent/'_history').mkdir(parents=True, exist_ok=True); shutil.copy2(target,target.parent/'_history'/('05_soc_sequestration_before_'+datetime.now().strftime('%Y%m%d_%H%M%S')+'.docx'))
data=list(csv.DictReader((root/'data/raw/study_site_soil_2024.csv').open(encoding='utf-8-sig')))
group=lambda loc,t=None:[r for r in data if r['location_code']==loc and (t is None or r['former_treatment_code']==t)]
f=group('2_alley','F');c=group('2_alley','C');a=group('3_arable')
assert len(f)==16 and len(c)==16 and len(a)==95
d=make('SOC sequestration following arable conversion','This separate note develops annualised SOC stock contrasts for selected alley samples relative to the neighbouring arable reference. The 2024 observations support a comparison of former Continuous fallow and Continuous cropping histories, conditional on conversion dates and management continuity. They do not directly measure SOC change through repeated sampling.')
d.paragraphs[1].text='Analysis notes for paper drafting   |   Updated 22 October 2026'
h(d,'Site history and working chronology')
p(d,'The user confirms that the two sampled fields formed one arable field before the experiment began in 1992. One half became a silvoarable experiment with Alternate cropping (A), Continuous fallow (F) and Continuous cropping (C). The final crop was planted in autumn 2003 and harvested in August 2004, as confirmed by the user after consulting a colleague. Soil sampling took place in 2024, and the other field remained the arable reference. The shared former field makes the reference useful, but does not establish identical starting SOC or unchanged arable SOC through time.')
p(d,'The user confirms Continuous fallow alleys have remained grassland continuously since the experiment started in 1992. Continuous cropping alleys have remained grassland continuously since cropping ended after the August 2004 harvest. The final crop was sown in autumn 2003. Thus the nominal calendar-year durations to 2024 are 32 and 20 years. The earlier 1994 start date was mistaken; the 1992-1998 period in the historic report describes an earlier reporting window, not the final cessation date. Exact fractional durations require the conversion date and a verified sampling date: if Date extracted on 24-25 January 2024 records field sampling, August 2004 to sampling is approximately 19.4 years. The harvest day and exact onset of grass cover were not supplied.')
h(d,'Methods and selected data')
p(d,'Use outputs/soil_provenance_20261022/study_site_soil_2024.xlsx, sheet soil_0_30, or its identical CSV companion data/raw/study_site_soil_2024.csv. Measurements come from the full-precision AgricARBON results. The source retains permanent core/sample IDs, corrected location membership, former treatment, block and row. Do not use the scenario workbook as the measurement source.')
table(d,['Subset','Selection','Cores','Layers'],[
['Continuous fallow alley','2_alley and F; row 6 / Block 1','8','16'],
['Continuous cropping alley','2_alley and C; row 10 / Block 2','8','16'],
['Arable reference','3_arable; company Field 1','48','95']],[1.75,2.65,.65,.65])
p(d,'Both selected alley subsets have two layers per core. The reference has 47 complete profiles and one upper-only profile. Exclude Tree row samples and Alternate cropping alleys from this initial calculation. Retain Alternate cropping for a later analysis once its conversion chronology is defined. No additional measurements are created or missing layers imputed.')
p(d,'Derive profile stocks before averaging cores. Compare common equivalent soil masses using the corrected arable membership; retain fixed-depth 0-30 cm contrasts as a sensitivity analysis. Recalculate the reference masses and profile estimates from the new input before estimating annualised contrasts. Document every extrapolation below measured depth. ESM does not resolve initial SOC differences or management confounding.')
d.add_page_break()
h(d,'Proposed annualised stock contrasts')
p(d,'Let S_F and S_C be mean 2024 alley SOC stocks for the former Continuous fallow and Continuous cropping subsets, and S_R the 2024 mean arable reference stock, all on the same depth or equivalent-mass basis in Mg C per hectare. The proposed estimates are:')
p(d,'r_F = (S_F - S_R) / (2024 - 1992) = (S_F - S_R) / 32')
p(d,'r_C = (S_C - S_R) / (2024 - 2004) = (S_C - S_R) / 20')
p(d,'Units are Mg C per hectare of sampled alley per year. Subtract the arable reference before dividing by elapsed time: total SOC includes inherited carbon. Retain negative contrasts if present. These are retrospective annualised excess-stock estimates under an assumed reference trajectory, not the instantaneous sequestration rate in 2024. Calendar-year differences are approximate exposure periods until conversion timing is established.')
h(d,'Calculated results')
p(d,'The available subset sizes above and nominal 32-year and 20-year durations are established for planning. No new SOC stocks, annualised rates, statistical tests or scenario projections have been calculated. Existing SOC-stock outputs retain older inputs and must not supply the new numerators without recalculation.')
h(d,'Discussion hypotheses and inferential limits')
p(d,'The arable reference is a space-for-time counterfactual, not an observed 1992 or 2004 baseline. For a contrast to represent additional accumulation, starting SOC differences must be negligible and the reference must plausibly represent what would have happened without conversion. A change in the reference field can make avoided SOC loss part of the contrast; it is not necessarily all new carbon accumulated in the alleys.')
p(d,'The Continuous cropping alleys were already beside trees before 2004. Their 2024 excess over the arable field may therefore include pre-2004 tree effects. Dividing that whole excess by 20 years cannot isolate post-2004 conversion to grassland without a justified 2004 stock baseline. Both alley subsets remain influenced by trees, so the interpretation is conversion within this silvoarable system rather than a general open-field arable-to-grassland effect.')
p(d,'Each former treatment occurs in one sampled block and row band. Eight cores describe within-band variation, not eight independent replicated conversions. The two annualised contrasts cannot identify a temporal response curve or prove that one conversion age has a higher sequestration rate. SOC accumulation need not be linear or continue indefinitely; do not extend these historical averages unchanged into future scenarios. Area upscaling requires alley fractions, and combined tree/soil accounting must avoid double counting.')
h(d,'Open decisions')
p(d,'The start year, final crop season and continuity of grassland are now confirmed. Remaining decisions are the duration convention (nominal calendar years versus verified elapsed dates), grassland management details (mowing, grazing and organic inputs), availability of baseline soil measurements especially around 2004, and arable management comparability. Specify the ESM extrapolation policy and scenario trajectory. Prior accumulation beside trees remains a limitation for interpreting the Continuous cropping contrast as solely post-2004 sequestration.')
h(d,'Methodological reference')
p(d,'IPCC 2019 Refinement, Volume 4, Chapter 5, mineral-soil stock-change methods: https://www.ipcc-tfi.iges.or.jp/public/2019rf/pdf/4_Volume4/19R_V4_Ch05_Cropland.pdf. Dividing a stock change by a period requires an explicit initial or counterfactual stock and time assumption; IPCC default transition periods do not validate a site-specific time trajectory.')
save(d,name)


