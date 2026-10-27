from pathlib import Path
import json,sys,shutil
from datetime import datetime
from docx import Document
root=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1]) if len(sys.argv)>1 else Path('C:/Users/sofia/Documents/poplar_paper/manuscript/analysis_notes/05_carbon_scenario_planning.docx')
d=Document(source);data=json.loads((root/'scenario_data.json').read_text());old=json.loads((root/'previous_scenario_data.json').read_text()) if (root/'previous_scenario_data.json').exists() else None
totals=[r for r in data['milestones'] if r['land']=='UK total']
def result(code,year):return next(r for r in totals if r['scenario_code']==code and r['year']==year)
for p in d.paragraphs:
 if p.text.startswith('Permanent grassland is 5.985'):
  p.text=('Permanent grassland comprises 5.985 million ha of grass over five years old, excluding rough grazing. '
   'The croppable denominator is 6.125 million ha, following Defra 2025 Table 2.1: 4.089 million ha arable crops, '
   '0.147 million ha horticultural crops, 0.576 million ha uncropped arable land and 1.313 million ha temporary grass '
   'under five years old. The alternative arable cropped denominator is 4.089 million ha and excludes horticulture. '
   'Temporary grassland is included only in croppable land and does not overlap with permanent grassland. '
   'The cropped alternative supports comparison with Burgess and Graves (2022), but does not reproduce their broader '
   'cropland category, reference year or net greenhouse-gas accounting.')
 elif p.text.startswith('Both measures describe the same AGB stock trajectory.'):
  a,b=result('CB_STEADY',2050),result('CB_STEADY',2056)
  p.text=(f"Both measures describe the same AGB stock trajectory. PAIC represents recent annual accumulation; MAIC averages accumulation since planting. For constant planting in the croppable case, 2050 PAIC is {a['annual_AGB_CO2_Mt']:.2f} Mt CO2/year and summed cohort MAIC is {a['MAIC_AGB_CO2_Mt']:.2f} Mt CO2/year. The corresponding 2056 values are {b['annual_AGB_CO2_Mt']:.2f} and {b['MAIC_AGB_CO2_Mt']:.2f}. Summing MAIC over calendar years does not reconstruct stocks; use annual stock changes for that purpose.")
 elif p.text.startswith('The corrected fixed-depth arable baseline gives') or p.text.startswith('Removing grassland SOC reduces'):
  a,b,c,e=result('CB_STEADY',2050),result('CB_STEADY',2056),result('CR_STEADY',2050),result('CR_STEADY',2056)
  p.text=(f"Using the exact Defra land areas gives constant-planting croppable combined stocks of {a['total_CO2_Mt']:.2f} Mt CO2 in 2050 and {b['total_CO2_Mt']:.2f} in 2056. The arable cropped alternative gives {c['total_CO2_Mt']:.2f} and {e['total_CO2_Mt']:.2f} Mt CO2. This rerun changes only the croppable and arable cropped baseline areas. The observed growth curve, planting schedules, densities, carbon fractions, root allocation, existing SOC input and age conventions are unchanged. Previous runs are archived.")
 elif p.text.startswith('For publication, confirm comparable whole-system'):
  p.text=('For publication, confirm comparable whole-system land accounting when discussing CCC targets and the transfer of per-tree growth across layouts. The current calculation uses Defra 2025 values of 6.125 million ha croppable and 4.089 million ha arable cropped land. The historical carbon-conversion reversal remains internal calculation bookkeeping and should be omitted from paper methods. Previous notes, figures and results are preserved.')
 else:
  for run in p.runs:
   if run._r.xpath('.//w:drawing'):continue
   run.text=run.text.replace('6.1 million ha','6.125 million ha').replace('4.1 million ha','4.089 million ha')
 if p.text.startswith('Figure 2 '):
  p.text += (' This user-authored schematic is retained unchanged; its rounded croppable/cropped land labels are superseded by the exact Defra areas and targets in the current methods and tables.')
for row,l in zip(d.tables[0].rows[1:],data['lands']):
 vals=[{'Permanent grassland':'Permanent grassland 5.985m ha','Croppable area':'Croppable area 6.125m ha','Cropped area':'Arable cropped 4.089m ha'}[l['land']],f"{l['adoption_fraction']:.0%}",f"{l['target_system_ha']:,.0f}",f"{l['annual_system_ha']:,.1f}"]
 for cell,v in zip(row.cells,vals):cell.text=v
for row,r in zip(d.tables[1].rows[1:],totals):
 vals=['6.125m ha' if r['scenario_code'].startswith('CB') else '4.089m ha','All 2027' if r['scenario_code'].endswith('FAST') else 'Constant',str(r['year'])]+[f"{r[k]:.2f}" for k in ['AGB_CO2_Mt','total_CO2_Mt','annual_AGB_CO2_Mt','MAIC_AGB_CO2_Mt']]
 for cell,v in zip(row.cells,vals):cell.text=v
shape=d.inline_shapes[0];rid=shape._inline.graphic.graphicData.pic.blipFill.blip.embed
d.part.related_parts[rid]._blob=(root/'figures/uk_scenarios_summary.png').read_bytes()
d.save(root/'outputs/05_carbon_scenario_planning.docx')
print('Updated note values and Figure 1; manual content and the embedded user scheme preserved.')
