from pathlib import Path
import csv,collections,math
import numpy as np
root=Path(__file__).resolve().parents[1]
src=root/'data/raw/study_site_soil_2024.csv';out=root/'results/tables'
rows=list(csv.DictReader(src.open(encoding='utf-8-sig')))
for r in rows:
    for k in ['fine_bd_gcm3','SOC_perc','depth_top_cm','depth_bottom_cm','depth_thickness_cm']:r[k]=float(r[k])
    r['mass']=r['fine_bd_gcm3']*r['depth_thickness_cm']*100
    r['carbon']=r['mass']*r['SOC_perc']/100
ref=[]
for layer in ['0-15','15-30']:
    a=[r['mass'] for r in rows if r['location_code']=='3_arable' and r['depth_interval_cm']==layer]
    ref.append(dict(depth_interval_cm=layer,n_samples=len(a),mean_layer_mass_mg_ha=np.mean(a)))
target=sum(r['mean_layer_mass_mg_ha'] for r in ref)
by=collections.defaultdict(list)
for r in rows:by[r['profile_id']].append(r)
profiles=[]
for id,rs in by.items():
    rs.sort(key=lambda r:r['depth_top_cm']);r=rs[0];complete=len(rs)==2
    mass=np.cumsum([0]+[x['mass'] for x in rs]);carbon=np.cumsum([0]+[x['carbon'] for x in rs])
    stock= float(np.interp(target,mass,carbon) if target<=mass[-1] else carbon[-1]+(target-mass[-1])*rs[-1]['SOC_perc']/100) if complete else None
    extension=max(0,target-mass[-1]) if complete else None
    depth=(target/rs[0]['mass']*15 if target<=mass[1] else 15+(target-mass[1])/rs[1]['mass']*15) if complete else None
    group='arable' if r['location_code']=='3_arable' else 'trees' if r['location_code']=='1_tree' else {'F':'alley_F','C':'alley_C'}.get(r['former_treatment_code'],'excluded_alley_A')
    profiles.append(dict(profile_id=id,location_code=r['location_code'],location=r['location'],former_treatment_code=r['former_treatment_code'],former_treatment=r['former_treatment'],block=r['block'],tree_row=r['tree_row'],analysis_group=group,profile_complete=complete,reference_mass_mg_ha=target,SOC_ESM_mg_ha=stock,total_method='excluded_incomplete_profile' if not complete else 'extrapolated' if extension>0 else 'interpolated',extrapolated_mass_mg_ha=extension,extrapolated_SOC_mg_ha=extension*rs[-1]['SOC_perc']/100 if complete else None,equivalent_depth_cm=depth,fixed_depth_SOC_0_30_mg_ha=sum(x['carbon'] for x in rs) if complete else None))
baseline=np.mean([r['SOC_ESM_mg_ha'] for r in profiles if r['analysis_group']=='arable' and r['profile_complete']])
labels={'arable': 'Arable reference', 'alley_C': 'Alley fallow, 19 years', 'alley_F': 'Alley fallow, 32 years', 'trees': 'Tree rows, 32 years'}
years={'arable':None,'alley_F':32,'alley_C':19,'trees':32}
for r in profiles:
    yr=years.get(r['analysis_group']);r['duration_years']=yr
    r['SOC_excess_over_arable_mg_ha']=r['SOC_ESM_mg_ha']-baseline if r['profile_complete'] else None
    r['annualised_SOC_excess_mg_ha_yr']=r['SOC_excess_over_arable_mg_ha']/yr if r['profile_complete'] and yr else None
summary=[]
for group,label in labels.items():
    allrs=[r for r in profiles if r['analysis_group']==group];rs=[r for r in allrs if r['profile_complete']]
    vals=np.array([r['SOC_ESM_mg_ha'] for r in rs]);mean=np.mean(vals);sd=np.std(vals,ddof=1);yr=years[group]
    summary.append(dict(group_code=group,group=label,n_sampled_profiles=len(allrs),n_complete_profiles=len(rs),n_excluded_profiles=len(allrs)-len(rs),reference_mass_mg_ha=target,mean_SOC_ESM_mg_ha=mean,sd_SOC_ESM_mg_ha=sd,arable_reference_mean_mg_ha=baseline,mean_SOC_excess_mg_ha=mean-baseline,duration_years=yr,annualised_SOC_excess_mg_ha_yr=(mean-baseline)/yr if yr else 0,sd_annualised_SOC_excess_mg_ha_yr=sd/yr if yr else None,n_extrapolated=sum(r['total_method']=='extrapolated' for r in rs),max_equivalent_depth_cm=max(r['equivalent_depth_cm'] for r in rs)))
def write(name,rs):
    with (out/name).open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=list(rs[0]));w.writeheader();w.writerows(rs)
write('soc_sequestration_ESM_profiles.csv',profiles);write('soc_sequestration_ESM_summary.csv',summary);write('soc_sequestration_reference_masses.csv',ref)
# Independent reconciliation to the existing ESM calculation; do not overwrite its results.
existing={r['profile_id']:r for r in csv.DictReader((out/'soc_ESM_profile_estimates.csv').open(encoding='utf-8-sig'))}
for r in profiles:
    if r['profile_complete']:assert math.isclose(r['SOC_ESM_mg_ha'],float(existing[r['profile_id']]['SOC_ESM_total_mg_ha']),abs_tol=1e-9)
assert len(profiles)==96 and len([r for r in profiles if r['profile_complete']])==92
assert math.isclose(target,3733.2437062687,abs_tol=1e-8)
for s in summary:print(s)
