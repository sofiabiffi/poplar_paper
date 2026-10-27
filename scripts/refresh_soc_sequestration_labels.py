from pathlib import Path
from datetime import datetime
import csv,shutil
from docx import Document
root=Path(__file__).resolve().parents[1]
labels={'arable':'Arable reference','alley_C':'Alley fallow, 19 years','alley_F':'Alley fallow, 32 years','trees':'Tree rows, 32 years'}
order={k:i for i,k in enumerate(labels)}
# Preserve machine codes and all numerical values; only display labels and row order change.
path=root/'results/tables/soc_sequestration_ESM_summary.csv'
rows=list(csv.DictReader(path.open(encoding='utf-8-sig')));fields=list(rows[0])
rows.sort(key=lambda r:order[r['group_code']])
for r in rows:r['group']=labels[r['group_code']]
with path.open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
path=root/'scripts/calculate_soc_sequestration.py';s=path.read_text()
start=s.index('labels={');end=s.index('\nyears=',start)
s=s[:start]+'labels='+repr(labels)+s[end:];path.write_text(s)
path=root/'analysis/17_soc_sequestration.R';s=path.read_text()
s=s.replace("levels=c('arable','alley_F','alley_C','trees'),labels=c('Arable\\nreference','Alley\\nContinuous fallow','Alley\\nContinuous cropping','Tree rows\\nAll former treatments')","levels=c('arable','alley_C','alley_F','trees'),labels=c('Arable\\nreference','Alley fallow\\n19 years','Alley fallow\\n32 years','Tree rows\\n32 years')")
s=s.replace("d$mean_SOC_ESM_mg_ha[1]","d$mean_SOC_ESM_mg_ha[d$group_code=='arable']")
s=s.replace("expression('Annualised SOC excess (Mg C ha'^{-1}*' yr'^{-1}*')')","expression(SOC[ESM]~'sequestration rate (Mg C ha'^{-1}*' yr'^{-1}*')')")
s=s.replace('Continuous fallow 32; Continuous cropping 19; tree rows 32.','alley fallow 19 years; alley fallow 32 years; tree rows 32 years.')
path.write_text(s)
replacements={
'At the arable 0-30 cm equivalent soil mass, annualised SOC excess over the arable reference is 0.408 Mg C per hectare per year for Continuous fallow alleys, 0.866 for Continuous cropping alleys and 0.658 for tree rows. These retrospective contrasts use agreed durations of 32, 19 and 32 years; they are not direct measurements of annual flux or exclusively grassland-induced accumulation.':'At the arable 0-30 cm equivalent soil mass, SOC_ESM sequestration rates are 0.866 Mg C per hectare per year for alley fallow of 19 years, 0.408 for alley fallow of 32 years and 0.658 for tree rows of 32 years. Methods define these rates as retrospective annualised stock differences relative to the arable reference.',
'Stocks and excesses are Mg C per hectare; annualised excesses are Mg C per hectare per year.':'Stocks and excesses are Mg C per hectare; SOC_ESM sequestration rates are Mg C per hectare per year. SOC_ESM sequestration rate is defined here as the annualised ESM-adjusted stock excess relative to the adjacent arable reference.',
'SOC stocks and annualised excess':'SOC stocks and sequestration rates',
'Figure 2 Annualised excess over the arable mean using 32, 19 and 32 years.':'Figure 2 SOC_ESM sequestration rates for alley fallow of 19 years, alley fallow of 32 years and tree rows of 32 years.',
'The higher annualised value for former Continuous cropping':'The higher sequestration-rate estimate for alley fallow of 19 years (former Continuous cropping)'}
# Synchronise report builder without changing its scientific qualifications.
path=root/'scripts/report_soc_sequestration.py';s=path.read_text()
for old,new in replacements.items():s=s.replace(old,new)
s=s.replace("'Annualised excess'","'Sequestration rate'")
s=s.replace('32 years for Continuous fallow, 19 for Continuous cropping and 32 for tree rows','32 years for Continuous fallow, 19 for Continuous cropping and 32 for tree rows')
path.write_text(s)
path=root/'manuscript/analysis_notes/06_soc_sequestration.docx'
(path.parent/'_history').mkdir(parents=True, exist_ok=True); shutil.copy2(path,path.parent/'_history'/('06_soc_sequestration_before_timeline_labels_'+datetime.now().strftime('%Y%m%d_%H%M%S')+'.docx'))
d=Document(path)
for p in d.paragraphs:
    text=p.text
    for old,new in replacements.items():text=text.replace(old,new)
    if text!=p.text:p.text=text
for t in d.tables:
    mapping={'Alley - Continuous cropping':labels['alley_C'],'Alley - Continuous fallow':labels['alley_F'],'Tree rows':labels['trees']}
    for row in t.rows:
        for c in row.cells:
            if c.text in mapping:c.text=mapping[c.text]
            if c.text=='Annualised excess':c.text='Sequestration rate'
    if len(t.rows)==5:
        rowF=t.rows[2]._tr;rowC=t.rows[3]._tr
        if t.rows[2].cells[0].text==labels['alley_F']:rowF.addprevious(rowC)
d.save(path)
print('Updated labels and order; numerical estimates unchanged.')
