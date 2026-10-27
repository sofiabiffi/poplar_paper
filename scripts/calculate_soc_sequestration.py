"""Annualised ESM agroforestry excess relative to measured FD arable stocks."""
from pathlib import Path
from collections import defaultdict
import csv,json,hashlib
import numpy as np
root=Path(__file__).resolve().parents[1];out=root/'results/tables'
raw=list(csv.DictReader((root/'data/raw/study_site_soil_2024.csv').open(encoding='utf-8-sig')))
by=defaultdict(list)
for r in raw:by[r['profile_id']].append(r)
refs=[]
for dep in ['0-15','15-30']:
 v=[float(r['fine_bd_gcm3'])*float(r['depth_thickness_cm'])*100 for r in raw if r['location_code']=='3_arable' and r['depth_interval_cm']==dep]
 refs.append(dict(depth_interval_cm=dep,n_samples=len(v),mean_layer_mass_mg_ha=float(np.mean(v))))
target=sum(r['mean_layer_mass_mg_ha'] for r in refs)
profiles=[];arrays={};arable=[]
for id,rs in by.items():
 rs.sort(key=lambda r:float(r['depth_top_cm']));r=rs[0];complete=len(rs)==2
 masses=[float(x['fine_bd_gcm3'])*float(x['depth_thickness_cm'])*100 for x in rs]
 conc=[float(x['SOC_perc'])/100 for x in rs];carbons=[m*c for m,c in zip(masses,conc)]
 arrays[id]=(masses[0],masses[1] if complete else np.nan,conc[0],conc[1] if complete else np.nan)
 group='arable' if r['location_code']=='3_arable' else 'trees' if r['location_code']=='1_tree' else {'F':'alley_F','C':'alley_C'}.get(r['former_treatment_code'],'excluded_alley_A')
 is_ref=group=='arable'
 stock=(sum(carbons) if is_ref else (target*conc[0] if target<=masses[0] else carbons[0]+(target-masses[0])*conc[1])) if complete else None
 ext=(0 if is_ref else max(0,target-sum(masses))) if complete else None
 depth=(30 if is_ref else (target/masses[0]*15 if target<=masses[0] else 15+(target-masses[0])/masses[1]*15)) if complete else None
 profiles.append(dict(profile_id=id,location_code=r['location_code'],location=r['location'],former_treatment_code=r['former_treatment_code'],former_treatment=r['former_treatment'],block=r['block'],tree_row=r['tree_row'],analysis_group=group,profile_complete=complete,stock_basis='Fixed depth' if is_ref else 'Equivalent soil mass',reference_mass_mg_ha=target,SOC_stock_mg_ha=stock,SOC_ESM_mg_ha=stock if not is_ref else None,total_method='excluded_incomplete_profile' if not complete else 'fixed_depth' if is_ref else 'extrapolated' if ext>0 else 'interpolated',extrapolated_mass_mg_ha=ext,extrapolated_SOC_mg_ha=ext*conc[-1] if complete else None,equivalent_depth_cm=depth,fixed_depth_SOC_0_30_mg_ha=sum(carbons) if complete else None))
 if is_ref:arable.append(arrays[id])
baseline=float(np.mean([p['SOC_stock_mg_ha'] for p in profiles if p['analysis_group']=='arable' and p['profile_complete']]))
labels={'arable':'Arable reference','alley_C':'Alley fallow, 19 years','alley_F':'Alley fallow, 32 years','trees':'Tree rows, 32 years'}
years={'arable':None,'alley_C':19,'alley_F':32,'trees':32}
for p in profiles:
 yr=years.get(p['analysis_group']);p['duration_years']=yr
 p['SOC_excess_over_arable_mg_ha']=p['SOC_stock_mg_ha']-baseline if p['profile_complete'] else None
 p['annualised_SOC_excess_mg_ha_yr']=p['SOC_excess_over_arable_mg_ha']/yr if p['profile_complete'] and yr else None
summary=[]
for group,label in labels.items():
 allp=[p for p in profiles if p['analysis_group']==group];p=[p for p in allp if p['profile_complete']]
 vals=np.array([x['SOC_stock_mg_ha'] for x in p]);mean=float(np.mean(vals));sd=float(np.std(vals,ddof=1));yr=years[group]
 summary.append(dict(group_code=group,group=label,stock_basis='Fixed depth' if group=='arable' else 'Equivalent soil mass',n_sampled_profiles=len(allp),n_complete_profiles=len(p),n_excluded_profiles=len(allp)-len(p),reference_mass_mg_ha=target,mean_SOC_stock_mg_ha=mean,sd_SOC_stock_mg_ha=sd,arable_reference_mean_mg_ha=baseline,n_arable_complete=47,mean_SOC_excess_mg_ha=mean-baseline,duration_years=yr,annualised_SOC_excess_mg_ha_yr=(mean-baseline)/yr if yr else 0,sd_annualised_SOC_excess_mg_ha_yr=sd/yr if yr else None,n_extrapolated=sum(x['total_method']=='extrapolated' for x in p),max_equivalent_depth_cm=max(x['equivalent_depth_cm'] for x in p)))
def write(name,rs):
 with (out/name).open('w',newline='',encoding='utf-8-sig') as f:
  w=csv.DictWriter(f,fieldnames=list(rs[0]));w.writeheader();w.writerows(rs)
write('soc_sequestration_ESM_profiles.csv',profiles);write('soc_sequestration_ESM_summary.csv',summary);write('soc_sequestration_reference_masses.csv',refs)
tr=next(r for r in summary if r['group_code']=='trees')
write('soc_tree_row_rate_manuscript.csv',[dict(land_cover='Tree row',n_tree_profiles=tr['n_complete_profiles'],n_arable_profiles=47,duration_years=32,tree_ESM_stock_mean_mg_C_ha=tr['mean_SOC_stock_mg_ha'],arable_FD_stock_mean_mg_C_ha=baseline,mean_delta_SOC_mg_C_ha=tr['mean_SOC_excess_mg_ha'],mean_annual_SOC_accumulation_mg_C_ha_yr=tr['annualised_SOC_excess_mg_ha_yr'],profile_SD_rate_mg_C_ha_yr=tr['sd_annualised_SOC_excess_mg_ha_yr'],uncertainty='SD among complete tree-row profile rates; shared arable mean, reference masses and duration held fixed; not a confidence interval')])
# Reconcile each profile to the inspected stock correction, including FD reference.
existing={r['profile_id']:r for r in csv.DictReader((out/'soc_stock_comparison_profiles.csv').open(encoding='utf-8-sig'))}
for p in profiles:
 if p['profile_complete']:assert np.isclose(p['SOC_stock_mg_ha'],float(existing[p['profile_id']]['SOC_stock_total_mg_ha']),atol=1e-9,rtol=0)
assert np.isclose(baseline,59.3587645550793,atol=1e-10) and len(profiles)==96
checks=dict(n_profiles=96,n_complete=92,baseline_is_fixed_depth=True,profile_reconciliation=True,tree_rate=tr['annualised_SOC_excess_mg_ha_yr'],tree_rate_SD=tr['sd_annualised_SOC_excess_mg_ha_yr'],SD_identity=bool(np.isclose(tr['sd_annualised_SOC_excess_mg_ha_yr'],tr['sd_SOC_stock_mg_ha']/32)),source_sha256=hashlib.sha256((root/'data/raw/study_site_soil_2024.csv').read_bytes()).hexdigest(),limits='Profile SD is descriptive and conditional on the shared arable mean. Reference mean/mass, spatial clustering, baseline-history, density-definition, extrapolation-model and national transfer uncertainty are not propagated.')
(root/'results/checks/soc_rate_validation.json').write_text(json.dumps(checks,indent=2))
write('soc_rate_design_diagnostics.csv',[dict(land_cover=loc,block=b,n_complete=sum(p['profile_complete'] for p in profiles if p['location']==loc and p['block']==b)) for loc,b in sorted(set((p['location'],p['block']) for p in profiles))])
print(json.dumps(tr,indent=2))
