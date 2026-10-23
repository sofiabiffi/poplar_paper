from pathlib import Path
from datetime import datetime
import shutil
from docx import Document
from docx.shared import Pt
root=Path(__file__).resolve().parents[1]
path=root/'manuscript/analysis_notes/02_weather_and_PAIC.docx'
d=Document(path);title='Weather associations with annual carbon increment'
start=next(i for i,p in enumerate(d.paragraphs) if p.text==title)
history=path.parent/'_history';history.mkdir(exist_ok=True)
shutil.copy2(path,history/f'{path.stem}_before_selection_clarification_{datetime.now():%Y%m%d_%H%M%S}.docx')
pars=d.paragraphs
i=next(i for i in range(start,len(pars)) if pars[i].text=='Weather variable selection')+1
pars[i].text=('Nine candidates represented hypotheses about warmth, water supply, light and stress: spring and summer mean air temperature, rainfall totals and sunshine hours (six variables); spring air and ground frost-day counts (two); and the longest April-September dry spell (one). Spring was March-May and summer June-August; frost meant minimum air/grass temperature below 0 degrees C and dry days had rainfall below 1 mm. For screening, we removed a separate quadratic age trend from log PAIC for each hybrid, divided departures by each hybrid residual standard deviation, and averaged them equally. We examined Pearson and Spearman correlations on 24 years with complete coverage for all nine candidates, checking single-year influence and alternative detrending. Summer rainfall (Pearson r = 0.30) and temperature (r = 0.37) showed the clearest positive associations; sunshine, frost and dry-spell measures were weaker. Both summer predictors were retained without further screening. This hypothesis-guided selection used the same data as model fitting and remains exploratory. The final two-predictor model has 26 complete years because it needs fewer weather records.')
i=next(i for i in range(start,len(pars)) if pars[i].text.startswith('Trichobel has the largest absolute point estimates'))
pars[i].text=('Percentage difference = absolute difference divided by predicted PAIC at the lower weather value, times 100. For temperature, Trichobel rises from 1.80 to 2.39 (+0.58, 32%), whereas Beaupre rises from 1.10 to 1.54 (+0.44, 41%). Trichobel therefore has a larger carbon increment difference but a smaller proportional difference. All 12 direct hybrid-difference intervals include zero; Trichobel temperature association is uncertain (95% interval -0.09 to +1.22).')
for p in [pars[j] for j in [next(i for i in range(start,len(pars)) if pars[i].text=='Weather variable selection')+1,i]]:
    for r in p.runs:r.font.size=Pt(9.5)
for p in pars[start:]:
    if p.text.startswith('Sources:'):
        p.text='Source: analysis/13_absolute_weather_paic.R; full results and intervals in preceding pages.'
        for r in p.runs:r.font.size=Pt(9.5)
    if p.style.name=='Heading 2':
        p.paragraph_format.space_before=Pt(4);p.paragraph_format.space_after=Pt(3)
    elif p.style.name!='Heading 1':p.paragraph_format.space_after=Pt(3)
d.save(path);print(path)
