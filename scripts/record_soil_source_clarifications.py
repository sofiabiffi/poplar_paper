from pathlib import Path
from datetime import datetime
import shutil,json
from docx import Document
root=Path(__file__).resolve().parents[1]
out=root/'results/checks/soil_provenance'
facts={'confirmed_by':'User in conversation on 22 October 2026','sampling_year':2024,'reference_field_id':'UOL001-A01-001.0','reference_management':'Arable reference','field_plan_open_grassland_label':'Agricarbon error, corrected by user','measurement_source':'AGRICARBON UOL001-A01 Results v3.3 PUBLISH 2024-03-14 CSV.xlsx','scenario_workbook_role':'Derived workbook for reconciliation; not authoritative for sample location labels or measurements','row_orientation':'Approximately north to south; row 6 furthest west','analysis_status':'Existing numerical outputs retain derived workbook inputs; raw-source rebuild still required'}
(out/'confirmed_site_metadata.json').write_text(json.dumps(facts,indent=2)+'\n')
p=out/'README.md';s=p.read_text()
s=s.replace("- Page 4 of `UOL001 Field Plan.pdf`, Agroforestry field - part A01, calls Field 1 open grassland. The workbook's Arable reference label therefore needs management-history confirmation.","- The user confirms Field 1 was arable. The open grassland description on page 4 of the field plan is an Agricarbon error; use Arable reference in methods and scenarios.")
s=s.replace('- The plan is labelled Spring 2024; matched company `Date extracted` values are 24-25 January 2024. These do not substantiate a 2023 sampling date. The exact meaning of the extraction date needs confirmation.','- The user confirms sampling occurred in 2024; the earlier 2023 statement was mistaken. Use 2024 as the SOC observation year in methods and scenarios. The company Date extracted values are 24-25 January 2024; exact dates should retain their source column label.')
s=s.replace('need revision after source interpretation is settled.','need rebuilding from the raw company results with corrected location membership.')
s += '\n## Source authority and remaining scenario inputs\n\nThe user confirms the scenario workbook may contain Excel handling errors. Treat company IDs, coordinates and measurements as the primary data; use the scenario workbook only to audit previous transformations. The tree-profile-25 finding means that the two rows labelled Tree row 25 reproduce an arable core, not that the company physically sampled an arable core in a tree row. Keep the original location label as an audit field. Record confirmed site facts in confirmed_site_metadata.json.\n\nBefore deriving annual sequestration scenarios, establish management after the original cropping-treatment period and whether the arable reference is a defensible counterfactual (management and comparability). Scenario upscaling also needs actual tree-row/alley area fractions and an explicit stock-to-time trajectory. These do not prevent use of the recovered sample identities.\n'
p.write_text(s)
path=root/'manuscript/analysis_notes/04_soil_carbon_stocks.docx'
shutil.copy2(path,path.parent/'_history'/('04_soil_carbon_stocks_before_source_clarifications_'+datetime.now().strftime('%Y%m%d_%H%M%S')+'.docx'))
d=Document(path)
for p in d.paragraphs:
    if p.text.startswith('The western, middle and eastern sampled bands are now confirmed'):
        p.text='The user confirms that the reference field was arable and the field plan description as open grassland is an Agricarbon error. Soil sampling took place in 2024; the earlier 2023 statement was mistaken. Use 2024 as the SOC observation year in methods and scenarios. The company Date extracted column records 24-25 January 2024. Rows run approximately north to south, with row 6 furthest west; former-treatment assignments to rows 6, 10 and 14 are confirmed.'
    if p.text.startswith('Before SOC scenario calculations, resolve the reference-field label'):
        p.text='Treat the AgricARBON results as the primary measurement and sample-identity source. The scenario workbook is a derived file with potentially unreliable Excel handling. Tree row profile 25 means two workbook records reproduce an arable core under a Tree row label; it does not imply that the field crew sampled an arable location as a tree row. Rebuild analysis inputs from the company results, preserving original workbook labels as audit fields, then rerun fixed-depth stocks, ESM reference masses, summaries and tests. Existing numerical outputs remain unchanged. Remaining scenario inputs include post-trial management history, reference-field comparability, tree-row/alley area fractions and an explicit stock-to-time trajectory. A cross-sectional stock contrast alone does not establish sequestration through time.'
d.save(path)
print('Confirmed site metadata, audit explanation and Word note updated.')
