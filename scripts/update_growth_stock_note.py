from pathlib import Path
from datetime import datetime
import shutil
from docx import Document
from docx.shared import Pt
from docx.oxml import OxmlElement
from docx.text.paragraph import Paragraph
p=Path('manuscript/analysis_notes/01_tree_growth.docx')
(p.parent/'_history').mkdir(parents=True, exist_ok=True); shutil.copy2(p,p.parent/'_history'/('01_tree_growth_before_stock_test_'+datetime.now().strftime('%Y%m%d_%H%M%S')+'.docx'))
d=Document(p)
for q in d.paragraphs:
 if q.text.startswith('For the final-visit hybrid comparison,'):
  q.text += ' The additional stock analysis used the same aggregation and stock ~ block + hybrid model, with Holm adjustment across its six pairwise stock comparisons as a separate follow-up family. The one missing Robusta stock value was excluded without imputation; its row mean used four trees, and all row means retained equal weight.'
 if q.text.startswith('Block-adjusted comparisons of 2023 means'):
  node=OxmlElement('w:p');q._p.addnext(node);new=Paragraph(node,q._parent)
  new.text='Total aboveground carbon stock also differed among hybrids in 2023 (block-adjusted F\u2083,\u2086 = 135.02, p < 0.001). Trichobel had higher stock than all other hybrids (all Holm-adjusted p < 0.001). Beaupre and Robusta both exceeded Gibecq (adjusted p = 0.011 and 0.019, respectively), while Beaupre and Robusta did not differ significantly (p = 0.438). Median stocks were 65.99 for Trichobel, 40.08 for Beaupre, 38.73 for Robusta and 33.77 Mg C ha\u207b\u00b9 for Gibecq (Table 1).'
 if q.text.startswith('n = 45 trees per hybrid'):
  q.text='n = 45 trees per hybrid for PAIC and MAIC; stock n = 44 for Robusta and 45 for the other hybrids. Letters within each numeric column compare block-adjusted means: hybrids without a shared letter differ at Holm-adjusted p < 0.05. The increment comparisons use a family of 12 tests; the additional stock comparisons use a separate family of six. Shared letters indicate insufficient evidence of a difference.'
  for r in q.runs:r.font.size=Pt(9)
 if q.text.startswith('Use PAIC to discuss'):
  q.text += ' Stock comparisons gave the same significance pattern in the row-level sensitivity analysis. Stock and MAIC represent closely related quantities, so these are not independent lines of evidence; different missingness and multiplicity families can produce different significance patterns.'
for i,letter in enumerate(['b','c','b','a'],1):
 cell=d.tables[0].rows[i].cells[3]
 r=cell.paragraphs[0].add_run(letter);r.font.superscript=True;r.font.size=Pt(9)
anchor=next(q for q in d.paragraphs if q.text=='results/tables/growth_2023_row_sensitivity.csv')
for text in ['scripts/test_growth_2023_stock.R','results/tables/growth_2023_stock_contrasts.csv']:
 node=OxmlElement('w:p');anchor._p.addnext(node);anchor=Paragraph(node,anchor._parent);anchor.text=text
# Keep the table caption with the table; start the gap discussion on a new page.
next(q for q in d.paragraphs if q.text=='Measurement gaps and interpretation').paragraph_format.page_break_before=True
d.save(p)
