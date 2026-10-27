from pathlib import Path
import csv,math,statistics,json
from collections import defaultdict
root=Path(__file__).resolve().parents[1]
def read(n):return list(csv.DictReader((root/n).open(encoding='utf-8-sig',newline='')))
raw=read('data/raw/study_site_soil_2024.csv');by=defaultdict(list)
for r in raw:by[r['profile_id']].append(r)
ref=[float(r['reference_cumulative_mass_mg_ha']) for r in read('results/tables/soc_ESM_arable_reference_masses.csv')]
profiles=read('results/tables/soc_stock_comparison_profiles.csv')
for p in profiles:
 layers=sorted(by[p['profile_id']],key=lambda r:float(r['depth_top_cm']))
 vals=[float(r['fine_bd_gcm3'])*float(r['depth_thickness_cm'])*float(r['SOC_perc']) for r in layers]
 complete=len(layers)==2;arable=p['location_code']=='3_arable'
 for idx,col in enumerate(('SOC_stock_upper_mg_ha','SOC_stock_total_mg_ha')):
  if idx==1 and not complete:assert p[col]=='NA';continue
  if arable:expected=vals[0] if idx==0 else sum(vals)
  else:
   remaining=ref[idx];expected=0
   for r in layers:
    mass=float(r['fine_bd_gcm3'])*float(r['depth_thickness_cm'])*100
    use=min(remaining,mass);expected+=use*float(r['SOC_perc'])/100;remaining-=use
   if remaining>0:expected+=remaining*float(layers[-1]['SOC_perc'])/100
  assert math.isclose(float(p[col]),expected,rel_tol=1e-12)
 if arable:
  assert p['upper_method']=='fixed_depth' and p['SOC_ESM_upper_mg_ha']=='NA' and p['SOC_ESM_total_mg_ha']=='NA'
 if complete:assert math.isclose(float(p['SOC_stock_upper_mg_ha'])+float(p['SOC_stock_lower_mg_ha']),float(p['SOC_stock_total_mg_ha']),rel_tol=1e-12)
# Independent Dunn/BH calculation using Python ranks, tie correction and normal tails.
for interval,col in [('Upper reference mass','SOC_stock_upper_mg_ha'),('Lower reference mass increment','SOC_stock_lower_mg_ha')]:
 dat=[p for p in profiles if p[col]!='NA'];groups=['Arable reference','Alley','Tree row'];ordered=sorted(range(len(dat)),key=lambda i:float(dat[i][col]));ranks={};tie_sum=0;i=0
 while i<len(ordered):
  j=i+1
  while j<len(ordered) and float(dat[ordered[j]][col])==float(dat[ordered[i]][col]):j+=1
  for k in range(i,j):ranks[ordered[k]]=(i+1+j)/2
  tie_sum+=(j-i)**3-(j-i);i=j
 N=len(dat);var=N*(N+1)/12-tie_sum/(12*(N-1));out=[]
 for a,b in [(groups[0],groups[1]),(groups[0],groups[2]),(groups[1],groups[2])]:
  ra=[ranks[i] for i,p in enumerate(dat) if p['location']==a];rb=[ranks[i] for i,p in enumerate(dat) if p['location']==b]
  z=(statistics.mean(ra)-statistics.mean(rb))/math.sqrt(var*(1/len(ra)+1/len(rb)))
  out.append(math.erfc(abs(z)/math.sqrt(2)))
 order=sorted(range(3),key=lambda i:out[i]);adj=[0]*3;running=1
 for k in reversed(range(3)):
  i=order[k];running=min(running,out[i]*3/(k+1));adj[i]=running
 published=[r for r in read('results/tables/soc_ESM_layer_dunn_BH.csv') if r['mass_interval']==interval]
 for i,r in enumerate(published):assert math.isclose(float(r['p_BH']),adj[i],rel_tol=1e-10,abs_tol=1e-14)
loo=read('results/checks/soc_comparison_leave_one_out.csv')
print('Validated all',len(profiles),'profiles: exact arable FD, independent agroforestry integration, no arable ESM values, and independent Dunn/BH tests.')
print('Leave-one-out decision changes:',sum(r['decision_changed']=='TRUE' for r in loo),'of',len(loo),'comparisons')

(root/"results/checks/soc_FD_reference_validation.json").write_text(json.dumps({"n_profiles":len(profiles),"arable_fixed_depth_identity":True,"agroforestry_integration":True,"independent_Dunn_BH":True,"downstream_sequestration_upscaling":"deferred pending inspection"},indent=2))
