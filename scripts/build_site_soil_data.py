"""Extract authoritative company measurements; prepare typed workbook payload and CSV."""
from pathlib import Path
import csv,json,collections,hashlib
import openpyxl
root=Path(__file__).resolve().parents[1]
raw=root/'data/raw'; out=root/'data/processed';out.mkdir(exist_ok=True)
source=next(raw.glob('AGRICARBON*.xlsx'))
cross=list(csv.DictReader((root/'results/checks/soil_provenance/soil_profile_crosswalk.csv').open(encoding='utf-8-sig')))
bycore={r['ac_core_id']:r for r in cross}
w=openpyxl.load_workbook(source,data_only=True)
source_rows=[(i,r) for i,r in enumerate(w.active.values,1) if i>=4 and r[6] and r[3] in ('UOL001-A01-001.0','UOL001-A01-002.0')]
assert len(bycore)==96
fields=['profile_id','sample_id','location_code','location','former_treatment_code','former_treatment','block','tree_row','spatial_band','sampling_year','depth_interval_cm','depth_top_cm','depth_bottom_cm','depth_thickness_cm','fine_bd_gcm3','SOC_perc','total_bd_gcm3','company_carbon_stock_t_ha','latitude','longitude','date_extracted','core_depth_mm','total_dry_mass_g','fine_fraction_mass_g','field_id','strata_id','company_core_number','legacy_profile_id','legacy_potential_samplingID','legacy_location_code','location_correction','source_excel_row']
records=[];source_data=[]
for i,r in source_rows:
    c=bycore[r[5]]; layer=int(r[6].rsplit('.',1)[1])
    arable=r[3]=='UOL001-A01-001.0'
    loc='3_arable' if arable else c['location_code']
    code='' if arable else {6:'F',10:'C',14:'A'}[int(c['tree_row'])]
    label={'1_tree':'Tree row','2_alley':'Alley','3_arable':'Arable reference'}[loc]
    source_data.append([i]+[x.isoformat() if hasattr(x,'isoformat') else x for x in r[1:17]])
    if layer>2:continue
    vals=[r[5],r[6],loc,label,code,{'':'Not applicable (arable reference)','F':'Continuous fallow','C':'Continuous cropping','A':'Alternate cropping'}[code],None if arable else int(c['block']),None if arable else int(c['tree_row']),c['spatial_band'],2024,'0-15' if layer==1 else '15-30',0 if layer==1 else 15,15 if layer==1 else 30,15,r[14],r[15],r[12],r[16],r[7],r[8],r[9].date().isoformat(),r[10],r[11],r[13],r[3],r[4],int(r[5].rsplit('-',1)[1]),c['profile_id'],int(c['potential_samplingID']),c['location_code'],'Reclassified from Tree row to Arable reference' if c['location_code']!=loc else '',i]
    records.append(dict(zip(fields,vals)))
records.sort(key=lambda r:(r['location_code'],r['company_core_number'],r['depth_top_cm']))
assert len(records)==188 and len({r['sample_id'] for r in records})==188
counts=collections.Counter(r['location_code'] for r in records)
assert counts=={'1_tree':45,'2_alley':48,'3_arable':95},counts
assert all(r['former_treatment_code'] in ('F','C','A') for r in records if r['location_code']!='3_arable')
assert len({r['profile_id'] for r in records if r['location_code']=='3_arable'})==48
csvpath=out/'study_site_soil_2024.csv'
with csvpath.open('w',newline='',encoding='utf-8-sig') as f:
    cw=csv.DictWriter(f,fieldnames=fields);cw.writeheader();cw.writerows(records)
definitions={
'profile_id':'Permanent company core ID; stable profile join key. Replaces location-dependent legacy profile_id.',
'sample_id':'Permanent company sample ID; unique depth-record key.',
'location_code':'Sampling location retained as 1_tree, 2_alley, 3_arable. Separate from cropping treatment.',
'location':'Readable sampling location: Tree row, Alley or Arable reference.',
'former_treatment_code':'F = Continuous fallow; C = Continuous cropping; A = Alternate cropping. Blank for arable reference.',
'former_treatment':'Historical cropping treatment associated with the sampled row/alleys, not necessarily management in 2024.',
'block':'Original experimental block. Blank for arable reference.',
'tree_row':'Original tree-row number 6, 10 or 14, also identifies adjacent alley band. Blank for arable reference.',
'spatial_band':'Western, middle, eastern sampled band, or Reference field.',
'sampling_year':'2024, confirmed by user. SOC observation year for methodology and scenarios.',
'depth_interval_cm':'0-15 or 15-30 cm. Company suffix .1 and .2 respectively, corroborated by original layer records.',
'depth_top_cm':'Upper nominal layer boundary in cm.', 'depth_bottom_cm':'Lower nominal layer boundary in cm.',
'depth_thickness_cm':'Nominal measured layer thickness in cm, 15 for the retained .1/.2 layers.',
'fine_bd_gcm3':'Company Fine Dry BD (g/cm3), full supplied precision; no further correction applied.',
'SOC_perc':'Company SOC%, full supplied precision; numeric percentage points, e.g. 2.602 means 2.602%.',
'total_bd_gcm3':'Company Total Dry BD (g/cm3). Retained separately from fine BD.',
'company_carbon_stock_t_ha':'Unchanged company Carbon Stock (t/ha), not a newly calculated fine-BD stock or ESM result.',
'latitude':'Company latitude in decimal degrees; coordinate reference system not specified in source.',
'longitude':'Company longitude in decimal degrees; coordinate reference system not specified in source.',
'date_extracted':'Unchanged company Date extracted column; do not relabel as a separately verified event.',
'core_depth_mm':'Company total core depth (mm), not the depth interval of this record.',
'total_dry_mass_g':'Company Total dry mass (g).', 'fine_fraction_mass_g':'Company Total Fine Fraction mass (g).',
'field_id':'Permanent company field ID; 001.0 = arable reference; 002.0 = agroforestry.',
'strata_id':'Unchanged company Strata ID.', 'company_core_number':'Numeric final component of core ID; not a treatment or sampling-location code.',
'legacy_profile_id':'Previous analysis profile_id, retained only for reconciliation. Do not use as new primary key.',
'legacy_potential_samplingID':'Previous within-location workbook sampling ID, retained only for reconciliation.',
'legacy_location_code':'Original workbook location label, retained unchanged as an audit field.',
'location_correction':'Explicit classification correction, blank where original location agrees.',
'source_excel_row':'One-based Excel row in original CSV - Samples sheet.'}
notes=[
['Measurement source',source.name+'; sheet CSV - Samples. Original file remains unchanged.'],
['Source SHA256',hashlib.sha256(source.read_bytes()).hexdigest()],
['Main dataset','188 depth records from 96 cores: 24 tree-row, 24 alley, 48 arable-reference cores. Missing lower layers are not filled.'],
['Full source subset',f'{len(source_data)} company rows from study Fields 1 and 2, including deeper samples. No depth boundaries are invented for suffixes .3 and later.'],
['Classification evidence','Company field IDs and coordinates; matched profile audit; original design screenshot; colleague row/block account; user orientation confirmation on 22 October 2026.'],
['Orientation','Rows run approximately north to south. West to east: row 6 / Block 1 / F, row 10 / Block 2 / C, row 14 / Block 3 / A.'],
['Reference management','User confirms Field 1 was arable. Open grassland on field-plan page 4 is an Agricarbon labelling error.'],
['Location correction','Legacy 1_tree_25 matches arable core UOL001-A01-001.0-A-016. Both layers now belong to 3_arable; original identifiers remain in legacy columns.'],
['Precision','BD and SOC values come directly from company results without two-decimal rounding. They may differ slightly from prior analysis inputs.'],
['Treatment scope','Former treatment is the historical cropping regime associated with a row and adjacent alleys. A does not identify a permanently cropped/fallow side.'],
['Replication','Each former treatment occurs in one sampled block/row band. Cores are spatial subsamples, not independent treatment blocks.'],
['Unassigned information','Hybrid and annual crop-side assignments are not inferred. Post-trial management history remains to be documented.'],
['Analysis use','Use soil_0_30 as replacement input; fine_bd_gcm3 and SOC_perc retain familiar measurement names. Stable IDs are company IDs; treatment is explicitly former_treatment_code.'],
['Existing results','Existing SOC outputs and analysis scripts have not been rerun or switched to this input as part of dataset creation.'],
['CSV companion','poplar_paper/data/processed/study_site_soil_2024.csv contains identical main-sheet values, with ISO text dates.']]
payload={'headers':fields,'rows':[[r[f] for f in fields] for r in records],'raw_headers':['source_excel_row']+list(list(w.active.values)[1][1:17]),'raw_rows':source_data,'notes':notes,'dictionary':[[f,definitions[f]] for f in fields]}
(out/'study_site_soil_2024_payload.json').write_text(json.dumps(payload,indent=2))
print(json.dumps({'main_rows':len(records),'raw_site_rows':len(source_data),'layer_counts':dict(counts),'csv':str(csvpath)}))
