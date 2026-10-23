from pathlib import Path
import json
from docx import Document
root=Path(__file__).resolve().parents[1]
notes=root/'manuscript/analysis_notes'
# Remove redundant empty manual-break paragraphs before an explicit page start.
for stem in ['01_tree_growth','02_weather_and_PAIC','03_cropping_treatment_and_legacy','04_soil_carbon_stocks','06_soc_sequestration']:
    path=notes/f'{stem}.docx';d=Document(path)
    for p in list(d.paragraphs):
        if stem=='03_cropping_treatment_and_legacy' and p.text=='Main results':
            p.paragraph_format.page_break_before=True
        ptext=p.text.replace('Active cropping Equal','Active cropping. Equal').replace('After cropping ceased Equal','After cropping ceased. Equal').replace('including boundary interval Model-adjusted','including the boundary interval. Model-adjusted').replace('including boundary interval Equal','including the boundary interval. Equal')
        if ptext!=p.text:p.text=ptext
        if not p.text.strip() and p._p.xpath('.//w:br') and not p._p.xpath('.//w:drawing'):
            nxt=p._p.getnext()
            if nxt is not None:
                p._element.getparent().remove(p._element)
    if stem=='06_soc_sequestration':
        images=[p for p in d.paragraphs if p._p.xpath('.//w:drawing')]
        images[1].paragraph_format.page_break_before=True
    d.save(path)
mapping={
 '01_tree_growth':['paic_maic_descriptive'],
 '02_weather_and_PAIC':['final_weather_raw_screen','final_weather_hybrid_effects','final_weather_quadratic_age_shapes'],
 '03_cropping_treatment_and_legacy':['treatment_PAIC_active_means','treatment_PAIC_post_means'],
 '04_soil_carbon_stocks':['soc_ESM_by_mass_layer','supplement_soc_ESM_cumulative_profiles'],
 '06_soc_sequestration':['soc_sequestration_ESM_stocks','soc_sequestration_ESM_rates']}
captions={}
for stem,figs in mapping.items():
    d=Document(notes/f'{stem}.docx')
    ps=[p for p in d.paragraphs if p._p.xpath('.//w:drawing')]
    from docx.text.paragraph import Paragraph
    for fig,p in zip(figs,ps):captions[fig]=Paragraph(p._p.getnext(),p._parent).text
(root/'results/figure_descriptions/publication_captions.json').write_text(json.dumps(captions,indent=2,ensure_ascii=False),encoding='utf8')
