from pathlib import Path
import json, shutil
from datetime import datetime
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_COLOR_INDEX
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
root=Path(__file__).resolve().parents[1]
project=Path('C:/Users/sofia/Documents/poplar_paper')
dta=json.loads((root/'scenario_data.json').read_text())
old=project/'manuscript/analysis_notes/05_carbon_scenario_planning.docx'
(root/'history').mkdir(exist_ok=True)
shutil.copy2(old,root/'history'/('05_carbon_scenario_planning_before_uk_'+datetime.now().strftime('%Y%m%d_%H%M%S')+'.docx'))
d=Document();sec=d.sections[0];sec.top_margin=Inches(.65);sec.bottom_margin=Inches(.65);sec.left_margin=sec.right_margin=Inches(.7)
normal=d.styles['Normal'];normal.font.name='Arial';normal.font.size=Pt(10)
normal.paragraph_format.space_after=Pt(6)
for n in ['Title','Heading 1','Heading 2']:
 d.styles[n].font.name='Arial';d.styles[n].font.color.rgb=RGBColor(0,0,0)
for st in d.styles:
 if st.type==1:
  for border in st.element.xpath('./w:pPr/w:pBdr'):border.getparent().remove(border)
d.styles['Title'].font.size=Pt(21);d.styles['Heading 1'].font.size=Pt(15);d.styles['Heading 2'].font.size=Pt(11)
def p(t):return d.add_paragraph(t)
def h(t):d.add_heading(t,level=2)
def page(t):d.add_page_break();d.add_heading(t,level=1)
def table(headers,rows,widths):
 t=d.add_table(rows=1,cols=len(headers));t.alignment=WD_TABLE_ALIGNMENT.CENTER;t.autofit=False
 for i,v in enumerate(headers):t.rows[0].cells[i].text=v
 for row in rows:
  c=t.add_row().cells
  for i,v in enumerate(row):c[i].text=str(v)
 for ri,row in enumerate(t.rows):
  for i,c in enumerate(row.cells):
   c.width=Inches(widths[i]);c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
   tcpr=c._tc.get_or_add_tcPr();b=OxmlElement('w:tcBorders')
   for edge in ['top','left','bottom','right']:
    z=OxmlElement('w:'+edge);z.set(qn('w:val'),'single');z.set(qn('w:sz'),'4');z.set(qn('w:color'),'D9D9D9');b.append(z)
   tcpr.append(b);shade=OxmlElement('w:shd');shade.set(qn('w:fill'),'233F50' if ri==0 else ('F1F4F6' if ri%2==0 else 'FFFFFF'));tcpr.append(shade)
   for pa in c.paragraphs:
    pa.paragraph_format.space_after=Pt(4);pa.paragraph_format.space_before=Pt(4)
    for r in pa.runs:
     r.font.size=Pt(9)
     if ri==0:r.bold=True;r.font.color.rgb=RGBColor(255,255,255)
  row._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))
 t.rows[0]._tr.get_or_add_trPr().append(OxmlElement('w:tblHeader'))
 return t
def pic(stem,width=6.8):d.add_picture(str(root/'figures'/f'{stem}.png'),width=Inches(width))

d.add_heading('UK trees on farmland carbon scenarios',0)
p('Analysis note updated 26 October 2026. The croppable-area case is shown in one four-panel figure. The cropped-area alternative is retained in tables. Grassland tree rows and alleys receive no additional SOC credit. PAIC and MAIC comparisons concern AGB only.')
h('Methods and land definitions')
p('Permanent grassland is 5.985 million ha of grass over five years old, excluding rough grazing. The main croppable denominator is the Defra 2025 value of 6.125 million ha. Defra 2025 Table 2.1 reports 6.125 million ha: 4.089 million ha arable crops, 0.147 million ha horticultural crops, 0.576 million ha uncropped arable land and 1.313 million ha temporary grass under five years old. These rounded components sum to 6.125 million ha. The 4.089 million ha cropped alternative approximates arable crops only. Temporary grassland in the croppable denominator is distinct from the permanent-grassland denominator, so the two do not overlap.')
table(['Land baseline','Adoption','Target system ha','Constant ha/year'],[
 ['Permanent grassland 5.985m ha','14%','837,900','34,912.5'],
 ['Croppable area 6.125m ha','7%','428,750','17,864.6'],
 ['Cropped area 4.089m ha','7%','286,230','11,926.2']],[2.6,.7,1.1,1.4])
p('Targets describe whole-system hectares containing trees and alleys. Croppable and cropped are alternatives, not additive. Planting begins at the start of 2027. The optimistic scenario plants the entire target in 2027. Constant planting uses 24 equal cohorts in 2027-2050 inclusive, then stops. Outputs are end of 2050 and end of 2056, covering 24 and 30 annual growing periods respectively. The latter ends at the boundary of 1 January 2057.')
h('Layout and carbon accounting')
p('Cropland uses 2m strips, 30m between row centres and 7m between trees: 47.619 trees/ha and 6.667% tree-strip area. Permanent grassland uses 166 trees/ha, 2m strips and 10m row centres: 20% tree-strip area and approximately 6m between trees. The 30m spacing is interpreted as row centres, leaving a 28m cropped alley. Alleys retain their previous land use.')
p('AGB C = dry AGB x 0.4884. BGB C = dry AGB x 0.26 x 0.4690, so BGB C / AGB C = 0.2496724. Additional SOC is credited only on cropland tree strips at 0.651012993 Mg C per strip hectare per year, equivalent to 0.043400866 Mg C per whole-system hectare per year. There is no SOC gain on permanent grassland, including its tree strips, and none on any alley. Combined additional stock = AGB C + BGB C + cropland tree-strip SOC excess. Pre-existing SOC is excluded. Convert C to CO2 using 44/12.')

h('Observed tree trajectory')
p('Dry biomass was estimated for each individual tree from its measured diameter using the allometric relationship, then averaged across the 45 Trichobel trees at each measurement age. The scenarios recover this mean dry biomass from the stored mean historical carbon stock: divide Mg C/ha by 0.50 and 166 trees/ha and multiply by 1000 to obtain kg dry biomass/tree. This is equivalent to averaging individual dry masses because the conversion is linear. The 0.50 fraction only reverses the old carbon conversion; final scenario fractions are 0.4884 for AGB and 0.4690 for BGB. Linearly interpolate mean tree dry biomass between measured ages, assuming zero biomass at age zero. Recorded ages 1-30 (1993-2022) supply the projection; the 2023 age-31 observation is retained for context. No growth beyond observed ages is extrapolated.')
d.add_heading('Carbon stocks and tree growth',level=1).paragraph_format.page_break_before=True
pic('uk_scenarios_summary',6.4)
p('Figure 1 UK scenarios using 14% of permanent grassland and 7% of the 6.125 million ha croppable area. Panel A shows additional AGB stock and combined AGB + BGB + cropland tree-strip SOC. Panel B compares AGB PAIC, the difference between consecutive projected stocks, with AGB MAIC, stock divided by age within each planting cohort and then summed across cohorts. Each panel compares the two planting schedules and has its own legend. All curves are solid. Each panel uses different Okabe-Ito colours and endpoint shapes, with enlarged symbols at 2056. MAIC is a lifetime-average measure, not removal in that calendar year. The dotted line marks 2050; symbols mark only 2056. No statistical uncertainty bands are estimated.')
p('Only the croppable definition is plotted. Cropped-area outcomes remain in the tables and workbook. The main figure replaces the earlier separate stock, annual-increment and MAIC figures. There is no MAIC or PAIC comparison for BGB or SOC.')

d.add_heading('Calculated results',level=1).paragraph_format.page_break_before=True
p('UK totals include permanent grassland plus the selected alternative cropland denominator. Stocks are Mt CO2; AGB PAIC and MAIC are Mt CO2/year. Combined stock includes BGB and cropland tree-strip SOC, with zero grassland SOC credit.')
rs=[r for r in dta['milestones'] if r['land']=='UK total']
table(['Cropland','Planting','Year','AGB stock','Combined stock','AGB PAIC','AGB MAIC'],[
 [('6.125m ha' if r['scenario_code'].startswith('CB') else '4.089m ha'),('All 2027' if r['scenario_code'].endswith('FAST') else 'Constant'),r['year'],f"{r['AGB_CO2_Mt']:.2f}",f"{r['total_CO2_Mt']:.2f}",f"{r['annual_AGB_CO2_Mt']:.2f}",f"{r['MAIC_AGB_CO2_Mt']:.2f}"] for r in rs],[.85,.95,.55,.95,1.1,.95,.95])
h('Interpretation of PAIC and MAIC')
p('Both measures describe the same AGB stock trajectory. PAIC represents recent annual accumulation; MAIC averages accumulation since planting. For constant planting in the croppable case, 2050 PAIC is 7.00 Mt CO2/year and summed cohort MAIC is 4.69 Mt CO2/year. The corresponding 2056 values are 8.18 and 6.06. MAIC is smoother because it retains earlier growth in the average. Summing MAIC over calendar years does not reconstruct the carbon stock; use annual stock changes for that purpose.')
p('For a single planting cohort, MAIC multiplied by its age reconstructs its AGB stock. With multiple cohorts, calculate stock divided by age separately for each cohort before summation; dividing the national stock by programme duration is a different measure. The changing historical growth pattern is an age-profile analogue, not a prediction of future weather.')
h('Calculated effects of the revision')
p('The corrected fixed-depth arable baseline gives constant-planting croppable combined stocks of 91.69 Mt CO2 in 2050 and 151.03 in 2056. The cropped alternative gives 87.61 and 144.36 Mt CO2. AGB and BGB stocks and zero grassland SOC credit are unchanged. Previous parameter runs are archived.')

h('Verification')
p('Independent Python cohort sums and workbook formulas agree for the eight UK milestones, including AGB PAIC and cohort MAIC. All grassland SOC stocks and annual gains are zero. Areas reach their target by 2050 and planting stops thereafter. Annual increments reconcile to final stocks and cohort ages remain within observed support. The four-panel figure uses only the croppable case, and each line has exactly one marker, at 2056. These are deterministic scenario calculations, not inferential results.')

d.add_heading('Discussion and sources',level=1).paragraph_format.page_break_before=True
h('Discussion hypotheses and limitations')
p('The older observed trees extend age coverage but do not remove allometric or site-transfer uncertainty. Growth per tree is assumed unchanged when density changes. The source trees experienced differing cropping histories and subsequent cessation; this does not establish identical future growth under continued cropping or grazing. Trichobel is a modelling exemplar, not a recommendation for planting one species or clone across the UK. Diversity and maintenance matter. Mortality and harvest remain discussion considerations; all projected trees remain standing.')
p('The cropland SOC rate is the annualised ESM tree-row excess over fixed-depth arable stock (80.191180 - 59.358765) / 32. Applying it as a constant rate from establishment assumes a trajectory that was not measured annually. It describes the arable 0-30cm equivalent soil mass rather than the full soil profile; extrapolation below measured depth remains part of the SOC analysis. Applying a common rate across the croppable category also simplifies different prior land covers, including temporary grassland. No positive SOC response is transferred to existing permanent grassland.')
p('These outcomes are gross additional stocks and changes, not net GHG balances. Management emissions, changes in crop or livestock production, displaced production and harvested products are outside the calculation. No national net-zero date is inferred. CCC yield-class and species assumptions differ, so its reported 2.3 Mt CO2e/year in 2050 is contextual rather than a like-for-like benchmark. Burgess and Graves (2022) provides the earlier framework for integrating stocks with baseline emissions and land-use consequences.')
h('Policy context')
p('England SFI AGF1 lists 30-50 trees/ha at GBP248/ha/year and AGF2 lists 51-130 trees/ha at GBP385/ha/year, checked 26 October 2026. Cropland density is within the first numerical band; 166 trees/ha exceeds both. These English payments are context, not UK-wide projected revenues. Density alone does not establish eligibility or canopy-cover requirements.')
h('Publication retained for review')
r=p('Schulz-Nielsen et al. (2026), Management Effects on Biomass Partitioning in Fast-Growing Poplar in Brandenburg, Forests 17, 395. https://doi.org/10.3390/f17030395. Check against the thesis bibliography. Six- to seven-year-old root systems and much denser stands limit transfer to older trees. The C fractions 0.4884 and 0.4690 are calculated unweighted summaries of Table 2. The dry-biomass root:shoot ratio 0.26 remains a separate generic assumption.').runs[0];r.font.highlight_color=WD_COLOR_INDEX.YELLOW
h('Sources and open decisions')
p('Thillainathan I (2021), Role of agroforestry and hedges in UK climate targets, CCC, supplied PDF slide 7. Defra (2025 data), Agriculture in the United Kingdom, Chapter 2 Table 2.1: https://www.gov.uk/government/statistics/agriculture-in-the-united-kingdom-2025/chapter-2-structure-of-industry. Burgess PJ and Graves A (2022), The Potential Contribution of Agroforestry to Net Zero Objectives, Cranfield University, 48 pp. Full source links and input-file hashes accompany the workbook and scenario data.')
p('For publication, confirm comparable whole-system land accounting when discussing CCC targets, the interpretation of 30m row spacing, and the transfer of per-tree growth across layouts. Croppable composition is described above while the requested 6.125m and 4.089m denominators are retained. Previous notes, figures and scenario results are preserved before regeneration.')

if (root/'figures/uk_scenarios_method_schematic.png').exists():
    d.add_heading('Upscaling method schematic',level=1).paragraph_format.page_break_before=True
    pic('uk_scenarios_method_schematic',6.7)
    d.paragraphs[-1].alignment=1
    p('Figure 2 Overview of the cohort-based upscaling method for discussion. Alternative croppable and cropped land targets and the observed Trichobel age trajectory determine annual planting-cohort area, age and biomass. AGB, BGB and additional cropland tree-strip SOC are calculated separately. Grassland and alleys receive no additional SOC credit. AGB stock is reported separately from combined stock; PAIC and MAIC concern AGB only. The cropped-area alternative is retained in tables.')
d.save(root/'outputs/05_carbon_scenario_planning.docx')
print('Saved current scenario note')
