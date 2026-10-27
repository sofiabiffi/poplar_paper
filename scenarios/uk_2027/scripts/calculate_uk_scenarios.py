"""Deterministic cohort scenarios; original measurements and preparation are unchanged."""
from pathlib import Path
import csv, json, math, statistics, hashlib
import numpy as np

PROJECT = Path('C:/Users/sofia/Documents/poplar_paper')
OUT = Path(__file__).resolve().parents[1]
def read(p):
    with open(p, encoding='utf-8-sig', newline='') as f: return list(csv.DictReader(f))
def write(name, rows):
    with open(OUT/'tables'/name, 'w', encoding='utf-8', newline='') as f:
        w=csv.DictWriter(f, fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

cfg=dict(start_year=2027, end_year=2056, target_year=2050, grassland_ha=5985000,
         croppable_ha=6125000, cropped_ha=4089000, grass_adoption=0.14,crop_adoption=0.07,
         crop_row_centres_m=30,crop_strip_width_m=2,crop_within_row_m=7,
         grass_density_ha=166,grass_row_centres_m=10,grass_strip_width_m=2,
         reference_density_ha=166,source_carbon_fraction=0.5,agb_carbon_fraction=0.4884,
         bgb_carbon_fraction=0.4690,root_shoot_dry=0.26,hybrid_code='T',hybrid='Trichobel',
         grass_soc_transfer=0,grass_geometry_provisional=False)
soc=next(r for r in read(PROJECT/'results/tables/soc_sequestration_ESM_summary.csv') if r['group_code']=='trees')
cfg['soc_tree_row_rate']=float(soc['annualised_SOC_excess_mg_ha_yr'])
cfg['bgb_agb_carbon_ratio']=cfg['root_shoot_dry']*cfg['bgb_carbon_fraction']/cfg['agb_carbon_fraction']
src=[r for r in read(PROJECT/'data/processed/annual_hybrid.csv') if r['hybrid_code']=='T' and r['metric']=='carbon_stock_mg_ha']
src.sort(key=lambda r:int(r['age_years']))
obs=[]
for r in src:
    obs.append(dict(measurement_year=int(r['measurement_year']),age=int(r['age_years']),
      n_trees=int(r['n_valid']),source_mean_AGB_C_Mg_ha=float(r['mean']),
      mean_dry_kg_tree=float(r['mean'])/cfg['source_carbon_fraction']/cfg['reference_density_ha']*1000))
assert obs[0]['age']==1 and obs[-1]['age']==31
assert len({o['n_trees'] for o in obs})==1 and obs[0]['n_trees']==45
ages=[0]+[o['age'] for o in obs]; masses=[0]+[o['mean_dry_kg_tree'] for o in obs]
curve=[]
for age in range(32):
    dry=float(np.interp(age,ages,masses)); agb=dry*cfg['agb_carbon_fraction']/1000
    bgb=dry*cfg['root_shoot_dry']*cfg['bgb_carbon_fraction']/1000
    curve.append(dict(age=age,mean_dry_kg_tree=dry,AGB_C_Mg_tree=agb,BGB_C_Mg_tree=bgb,
      annual_AGB_C_Mg_tree=agb-(curve[-1]['AGB_C_Mg_tree'] if age else 0),
      annual_BGB_C_Mg_tree=bgb-(curve[-1]['BGB_C_Mg_tree'] if age else 0),
      support='assumed zero at planting' if age==0 else ('observed mean' if age in ages[1:] else 'linear interpolation of stocks')))
write('uk_scenario_observed_Trichobel.csv',obs);write('uk_scenario_growth_curve.csv',curve)
lands=[]
for code,area,frac,density,strip in [
 ('Permanent grassland',cfg['grassland_ha'],cfg['grass_adoption'],166,0.2),
 ('Croppable area',cfg['croppable_ha'],cfg['crop_adoption'],10000/(30*7),2/30),
 ('Cropped area',cfg['cropped_ha'],cfg['crop_adoption'],10000/(30*7),2/30)]:
    target=area*frac
    lands.append(dict(land=code,baseline_ha=area,adoption_fraction=frac,target_system_ha=target,
      density_trees_ha=density,strip_fraction=strip,target_strip_ha=target*strip,
      target_trees=target*density,annual_system_ha=target/24,annual_trees=target*density/24,
      SOC_C_Mg_system_ha_yr=cfg['soc_tree_row_rate']*strip*(0 if code=='Permanent grassland' else 1)))
write('uk_scenario_land_targets.csv',lands)
rows=[];cohorts=[]
for definition in ['Croppable area','Cropped area']:
 for schedule in ['All planted in 2027','Constant planting to 2050']:
  code=('CB' if definition=='Croppable area' else 'CR')+('_FAST' if schedule.startswith('All') else '_STEADY')
  for land in [lands[0],next(l for l in lands if l['land']==definition)]:
   previous=dict(agb=0,bgb=0,soc=0)
   for year in range(2027,2057):
    new=land['target_system_ha'] if schedule.startswith('All') and year==2027 else (land['annual_system_ha'] if schedule.startswith('Constant') and year<=2050 else 0)
    agb=bgb=soc_c=area=0
    for planting in range(2027,min(year,2050)+1):
     ha=land['target_system_ha'] if schedule.startswith('All') and planting==2027 else (land['annual_system_ha'] if schedule.startswith('Constant') else 0)
     if not ha:continue
     age=year-planting+1;trees=ha*land['density_trees_ha']
     ca=trees*curve[age]['AGB_C_Mg_tree'];cb=trees*curve[age]['BGB_C_Mg_tree']
     cs=ha*land['strip_fraction']*cfg['soc_tree_row_rate']*age*(0 if land['land']=='Permanent grassland' else 1)
     area+=ha;agb+=ca;bgb+=cb;soc_c+=cs
     cohorts.append(dict(scenario_code=code,land=land['land'],year=year,planting_year=planting,age=age,system_ha=ha,trees=trees,AGB_C_Mg=ca,BGB_C_Mg=cb,SOC_excess_C_Mg=cs))
    a_agb=agb-previous['agb'];a_bgb=bgb-previous['bgb'];a_soc=soc_c-previous['soc']
    row=dict(scenario_code=code,cropland_definition=definition,schedule=schedule,land=land['land'],year=year,
      new_system_ha=new,established_system_ha=area,established_trees=area*land['density_trees_ha'],
      AGB_C_Mg=agb,BGB_C_Mg=bgb,SOC_excess_C_Mg=soc_c,total_additional_C_Mg=agb+bgb+soc_c,
      annual_AGB_C_Mg=a_agb,annual_BGB_C_Mg=a_bgb,annual_SOC_C_Mg=a_soc,
      annual_total_C_Mg=a_agb+a_bgb+a_soc,
      AGB_CO2_Mt=agb*44/12/1e6,total_CO2_Mt=(agb+bgb+soc_c)*44/12/1e6,
      annual_AGB_CO2_Mt=a_agb*44/12/1e6,annual_total_CO2_Mt=(a_agb+a_bgb+a_soc)*44/12/1e6,
      total_without_grassland_SOC_CO2_Mt=(agb+bgb+(soc_c if land['land']!='Permanent grassland' else 0))*44/12/1e6,
      annual_without_grassland_SOC_CO2_Mt=(a_agb+a_bgb+(a_soc if land['land']!='Permanent grassland' else 0))*44/12/1e6)
    rows.append(row);previous=dict(agb=agb,bgb=bgb,soc=soc_c)
  for year in range(2027,2057):
   parts=[r for r in rows if r['scenario_code']==code and r['year']==year and r['land']!='UK total']
   total={k:(sum(p[k] for p in parts) if isinstance(parts[0][k],(float,int)) and k!='year' else parts[0][k]) for k in parts[0]}
   total['land']='UK total';rows.append(total)

# Age-specific MAIC is defined for AGB only and calculated within cohorts.
for r in rows:
    members=[c for c in cohorts if c['scenario_code']==r['scenario_code'] and c['year']==r['year'] and (r['land']=='UK total' or c['land']==r['land'])]
    r['MAIC_AGB_CO2_Mt']=sum(c['AGB_C_Mg']/c['age'] for c in members)*44/12/1e6
write('uk_scenario_annual_results.csv',rows);write('uk_scenario_cohorts.csv',cohorts)
milestones=[r for r in rows if r['year'] in [2050,2056]]
write('uk_scenario_milestones.csv',milestones)
checks=[]
def check(label,condition,detail):
    checks.append(dict(check=label,passed=bool(condition),detail=str(detail)))
check('grassland SOC is zero',all(r['SOC_excess_C_Mg']==0 and r['annual_SOC_C_Mg']==0 for r in rows if r['land']=='Permanent grassland'),0)
check('four scenarios',len({r['scenario_code'] for r in rows})==4,4)
check('24 annual planting years',2050-2027+1==24,24)
check('30 projection periods',2056-2027+1==30,30)
check('BGB carbon ratio accounts for C fractions',abs(cfg['bgb_agb_carbon_ratio']-0.2496723996723997)<1e-12,cfg['bgb_agb_carbon_ratio'])
for code in sorted({r['scenario_code'] for r in rows}):
 for land in [r['land'] for r in rows if r['scenario_code']==code and r['year']==2050 and r['land']!='UK total']:
  lr=[r for r in rows if r['scenario_code']==code and r['land']==land]
  target=next(l['target_system_ha'] for l in lands if l['land']==land)
  final=lr[-1]
  check(code+' '+land+' reaches target',math.isclose(next(r['established_system_ha'] for r in lr if r['year']==2050),target),target)
  check(code+' '+land+' increments reconcile',math.isclose(sum(r['annual_total_C_Mg'] for r in lr),final['total_additional_C_Mg'],abs_tol=1e-6),final['total_additional_C_Mg'])
  check(code+' '+land+' no planting after 2050',sum(r['new_system_ha'] for r in lr if r['year']>2050)==0,0)
check('maximum cohort age within observations',max(c['age'] for c in cohorts)<=31,max(c['age'] for c in cohorts))
check('no negative annual accumulation',min(r['annual_total_C_Mg'] for r in rows)>=0,min(r['annual_total_C_Mg'] for r in rows))
write('uk_scenario_checks.csv',checks)
assert all(c['passed'] for c in checks),checks
sources=[dict(source=str(p.relative_to(PROJECT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in [PROJECT/'data/processed/annual_hybrid.csv',PROJECT/'results/tables/soc_sequestration_ESM_summary.csv']]
payload=dict(config=cfg,observations=obs,curve=curve,lands=lands,annual=rows,milestones=milestones,checks=checks,sources=sources)
(OUT/'scenario_data.json').write_text(json.dumps(payload,indent=2),encoding='utf-8')
for r in milestones:
 if r['land']=='UK total':print(r['scenario_code'],r['year'],round(r['AGB_CO2_Mt'],3),round(r['total_CO2_Mt'],3),round(r['annual_total_CO2_Mt'],3))
