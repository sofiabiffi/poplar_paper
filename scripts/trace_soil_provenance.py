from pathlib import Path
import openpyxl,csv,json
from decimal import Decimal,ROUND_HALF_UP
root=Path(__file__).resolve().parents[1]
raw=root/'data/raw'; out=root/'results/checks/soil_provenance';out.mkdir(exist_ok=True)
rows=[r for r in list(openpyxl.load_workbook(next(raw.glob('AGRICARBON*.xlsx')),data_only=True).active.values)[3:] if r[6]]
old=list(openpyxl.load_workbook(raw/'soil_and_legacy_scenarios.xlsx',data_only=True)['rawdataSofia'].values)[1:]
round2=lambda x:float(Decimal(str(x)).quantize(Decimal('.01'),rounding=ROUND_HALF_UP))
matched=[]
for i,r in enumerate(old,2):
    layer='1' if r[1]=='0-15' else '2'
    candidates=[x for x in rows if x[6].endswith('.'+layer) and abs(x[14]-r[3])<=.005001 and abs(x[15]-r[4])<=.005001]
    matched.append(dict(workbook_row=i,location_code=r[0],potential_samplingID=r[2],depth_interval_cm=r[1],old_bd=r[3],old_soc=r[4],n_exact_candidates=len(candidates),candidates=';'.join(x[6] for x in candidates)))
profiles={}
for m in matched:profiles.setdefault((m['location_code'],m['potential_samplingID']),[]).append(m)
cross=[];audit=[]
for key,ms in profiles.items():
    top=ms[0];ids=top['candidates'].split(';') if top['candidates'] else []
    cores=[s.rsplit('.',1)[0] for s in ids]
    if len(cores)>1:
        cores=[c for c in cores if all(not m['candidates'] or any(s.startswith(c+'.') for s in m['candidates'].split(';')) for m in ms)]
    if len(cores)!=1: print('UNRESOLVED',key,cores);continue
    c=cores[0]; x=next(x for x in rows if x[6]==c+'.1')
    num=int(c.rsplit('-',1)[1]);band=0
    if x[3]=='UOL001-A01-002.0':
        band=1 if num in list(range(1,9))+list(range(24,32)) else 2 if num in list(range(9,16))+list(range(32,41)) else 3
    label={0:'Reference field',1:'Western band',2:'Middle band',3:'Eastern band'}[band]
    cross.append(dict(location_code=key[0],potential_samplingID=key[1],profile_id=key[0]+'_'+str(key[1]),ac_core_id=c,field_id=x[3],latitude=x[7],longitude=x[8],date_extracted=str(x[9].date()),top_match='rounded BD and SOC',n_old_layers=len(ms),spatial_band=label,tree_row={0:'',1:6,2:10,3:14}[band],block=band or '',former_treatment={0:'Unassigned reference management',1:'Continuous fallow',2:'Continuous cropping',3:'Alternate cropping'}[band],assignment_status='Reference field verified' if band==0 else 'Confirmed from coordinates, original design and user orientation 2026-10-22',location_flag='Workbook Tree row label conflicts with reference field' if key==('1_tree',25) else ''))
    for m in ms:
        layer='1' if m['depth_interval_cm']=='0-15' else '2'; rr=next((x for x in rows if x[6]==c+'.'+layer),None)
        audit.append({**m,'assigned_sample_id':c+'.'+layer,'new_bd':rr[14] if rr else '', 'new_soc':rr[15] if rr else '', 'bd_difference':rr[14]-m['old_bd'] if rr else '', 'soc_difference':rr[15]-m['old_soc'] if rr else '', 'both_match_rounding':bool(rr and abs(rr[14]-m['old_bd'])<=.005001 and abs(rr[15]-m['old_soc'])<=.005001)})
for name,data in [('soil_profile_crosswalk.csv',cross),('soil_value_match_audit.csv',audit),('soil_exact_match_candidates.csv',matched)]:
    with (out/name).open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
print('profiles',len(cross),'layers',len(audit),'match',sum(r['both_match_rounding'] for r in audit))
print('MISMATCHES');[print(r) for r in audit if not r['both_match_rounding']]
print('CROSS');[print(r) for r in cross if r['location_code']!='3_arable']
assert len(cross)==96 and len(audit)==188 and all(r['both_match_rounding'] for r in audit)
assert len({r['ac_core_id'] for r in cross})==96
assert all(m['n_exact_candidates']>=1 for m in matched)
