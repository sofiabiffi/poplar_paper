"""Independently verify soil outputs against the raw study-site CSV."""
from pathlib import Path
from collections import defaultdict
import csv,math,statistics,json
root=Path(__file__).resolve().parents[1]
def read(p):return list(csv.DictReader((root/p).open(encoding='utf-8-sig',newline='')))
raw=read('data/raw/study_site_soil_2024.csv');depth=read('data/processed/soil_depth.csv')
by_sample={r['sample_id']:r for r in raw};profiles=defaultdict(list)
for r in raw:profiles[r['profile_id']].append(r)
assert len(by_sample)==len(raw)==len(depth)
for r in depth:
 s=by_sample[r['sample_id']]
 assert r['profile_id']==s['profile_id'] and r['location_code']==s['location_code']
 assert float(r['bulk_density_g_cm3'])==float(s['fine_bd_gcm3']) or math.isclose(float(r['bulk_density_g_cm3']),float(s['fine_bd_gcm3']),rel_tol=1e-14)
 assert math.isclose(float(r['SOC_percent']),float(s['SOC_perc']),rel_tol=1e-14)
 assert math.isclose(float(r['SOC_stock_mg_ha']),float(s['fine_bd_gcm3'])*float(s['depth_thickness_cm'])*float(s['SOC_perc']),rel_tol=1e-12)
refs=[]
for dep in ('0-15','15-30'):
 vals=[float(r['fine_bd_gcm3'])*float(r['depth_thickness_cm'])*100 for r in raw if r['location_code']=='3_arable' and r['depth_interval_cm']==dep]
 refs.append(statistics.mean(vals))
refs[1]+=refs[0]
for i,r in enumerate(read('results/tables/soc_ESM_arable_reference_masses.csv')):assert math.isclose(refs[i],float(r['reference_cumulative_mass_mg_ha']),rel_tol=1e-12)
checks=[];properties={}
for p in read('results/tables/soc_ESM_profile_estimates.csv'):
 layers=sorted(profiles[p['profile_id']],key=lambda x:float(x['depth_top_cm']));complete=len(layers)==2
 for idx,col in enumerate(('SOC_ESM_upper_mg_ha','SOC_ESM_total_mg_ha')):
  remaining=refs[idx];value=0
  for layer in layers:
   mass=float(layer['fine_bd_gcm3'])*float(layer['depth_thickness_cm'])*100
   used=min(remaining,mass);value+=used*float(layer['SOC_perc'])/100;remaining-=used
  if remaining>1e-10 and (complete or idx==0):value+=remaining*float(layers[-1]['SOC_perc'])/100
  excluded=(not complete) and idx==1
  assert (p[col]=='NA')==excluded
  if not excluded:assert math.isclose(value,float(p[col]),rel_tol=1e-12)
 if complete:
  assert math.isclose(float(p['SOC_ESM_upper_mg_ha'])+float(p['SOC_ESM_lower_mg_ha']),float(p['SOC_ESM_total_mg_ha']),rel_tol=1e-12)
  bd=[float(x['fine_bd_gcm3']) for x in layers];th=[float(x['depth_thickness_cm']) for x in layers]
  properties[p['profile_id']]={'BD_mass_weighted_g_cm3':sum(b*b*t for b,t in zip(bd,th))/sum(b*t for b,t in zip(bd,th)),
   'SOC_content_mean_percent':statistics.mean(float(x['SOC_perc']) for x in layers)}
 checks.append({'profile_id':p['profile_id'],'raw_source_and_independent_integration':'passed','bedrock_exclusion':'passed','mass_balance':'passed'})
for r in read('results/tables/soil_profile_properties_0_30.csv'):
 for k,val in properties[r['profile_id']].items():assert math.isclose(float(r[k]),val,rel_tol=1e-12)
# Check every compact-letter pair against its adjusted comparison.
for tests_file,letters_file,key,letter_key in [('soc_ESM_layer_dunn_BH.csv','soc_ESM_layer_letters.csv','mass_interval','depth_interval_cm'),('soc_stock_depth_dunn_BH.csv','soc_stock_depth_letters.csv','depth_interval_cm','depth_interval_cm'),('supplement_soil_properties_dunn_BH.csv','supplement_soil_properties_0_30.csv','variable','variable')]:
 tests=read('results/tables/'+tests_file);letters=read('results/tables/'+letters_file)
 for t in tests:
  labels={r['location']:r.get('letter',r.get('significance_letter')) for r in letters if r[letter_key]==t[key]}
  shared=bool(set(labels[t['group1']])&set(labels[t['group2']]))
  assert shared==(float(t['p_BH'])>=.05)
with (root/'results/checks/soc_ESM_validation.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=checks[0]);w.writeheader();w.writerows(checks)
print('Verified raw measurements, corrected memberships, reference masses, ESM integration, BD weighting, SOC averaging and significance-letter consistency for',len(profiles),'profiles.')
