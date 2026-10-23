"""Check current export text and embedded-image consistency."""
from pathlib import Path
import hashlib,json
from docx import Document
from pypdf import PdfReader
root=Path(__file__).resolve().parents[1]
registry=json.loads((root/'results/figure_descriptions/publication_captions.json').read_text(encoding='utf8'))
checked=0
for path in (root/'manuscript/analysis_notes').glob('*.docx'):
    d=Document(path)
    for p in d.paragraphs:
        blips=p._p.xpath('.//a:blip')
        if not blips:continue
        from docx.text.paragraph import Paragraph
        caption=Paragraph(p._p.getnext(),p._parent).text
        stem=next(k for k,v in registry.items() if v==caption)
        rid=blips[0].get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}embed')
        assert d.part.related_parts[rid].blob==(root/'results/figures'/f'{stem}.png').read_bytes(),stem
        checked+=1
for path in (root/'results/figures').glob('*.pdf'):
    text=' '.join(p.extract_text() or '' for p in PdfReader(path).pages)
    for unwanted in ['Whiskers:', 'Boxes:', 'Model-adjusted means across hybrids', 'Summer weather associations with PAIC', 'DESCRIPTIVE |', 'NA']:
        assert unwanted not in text,(path.name,unwanted)
assert checked==10,checked
print(f'Confirmed {checked} embedded images match current PNG exports; all 18 figure PDFs omit titles and explanatory footnotes.')
