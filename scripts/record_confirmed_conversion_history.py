from pathlib import Path
from datetime import datetime
import json,shutil
from docx import Document
root=Path(__file__).resolve().parents[1]
stamp=datetime.now().strftime('%Y%m%d_%H%M%S')
replacements={
'The user reports that the two sampled fields formed one arable field before 1994.':'The user confirms that the two sampled fields formed one arable field before the experiment began in 1992.',
'The user reports that the experiment ended in 2004.':'The final crop was planted in autumn 2003 and harvested in August 2004, as confirmed by the user after consulting a colleague.',
'r_F = (S_F - S_R) / (2024 - 1994) = (S_F - S_R) / 30':'r_F = (S_F - S_R) / (2024 - 1992) = (S_F - S_R) / 32',
'nominal 30-year and 20-year durations':'nominal 32-year and 20-year durations',
'not an observed 1994 or 2004 baseline':'not an observed 1992 or 2004 baseline'}
chronology='The user confirms Continuous fallow alleys have remained grassland continuously since the experiment started in 1992. Continuous cropping alleys have remained grassland continuously since cropping ended after the August 2004 harvest. The final crop was sown in autumn 2003. Thus the nominal calendar-year durations to 2024 are 32 and 20 years. The earlier 1994 start date was mistaken; the 1992-1998 period in the historic report describes an earlier reporting window, not the final cessation date. Exact fractional durations require the conversion date and a verified sampling date: if Date extracted on 24-25 January 2024 records field sampling, August 2004 to sampling is approximately 19.4 years. The harvest day and exact onset of grass cover were not supplied.'
decisions='The start year, final crop season and continuity of grassland are now confirmed. Remaining decisions are the duration convention (nominal calendar years versus verified elapsed dates), grassland management details (mowing, grazing and organic inputs), availability of baseline soil measurements especially around 2004, and arable management comparability. Specify the ESM extrapolation policy and scenario trajectory. Prior accumulation beside trees remains a limitation for interpreting the Continuous cropping contrast as solely post-2004 sequestration.'
folder=root/'manuscript/analysis_notes'
for filename in ['06_soc_sequestration.docx','03_cropping_treatment_and_legacy.docx']:
    path=folder/filename;shutil.copy2(path,folder/'_history'/(path.stem+'_before_confirmed_history_'+stamp+'.docx'))
    d=Document(path)
    for p in d.paragraphs:
        text=p.text
        if filename.startswith('06'):
            if text.startswith('The proposed conversion dates are'):text=chronology
            elif text.startswith('Confirm the onset and continuity'):text=decisions
            else:
                for old,new in replacements.items():text=text.replace(old,new)
            text=text.replace('Calendar-year differences are approximate exposure periods until conversion timing is established.','The 32-year and 20-year denominators are nominal calendar-year conventions. If January 2024 extraction dates are verified sampling dates, use approximately 19.4 years for the Continuous cropping contrast in a date-based sensitivity analysis; do not assign a precise August day.')
        elif text.startswith('Cropping stopped after the 2004 harvest.'):
            text=text.replace('Cropping stopped after the 2004 harvest.','The final crop was planted in autumn 2003 and harvested in August 2004, confirmed by the user after consulting a colleague on 22 October 2026. Cropping ceased after that harvest. Continuous fallow remained grassland from 1992; Continuous cropping became continuous grassland after cessation.')
            text+=' The confirmed harvest month supports the existing primary phase assignments; no model refit is required for this clarification. The active-with-boundary fit remains a sensitivity analysis containing the mixed cessation interval, not a strictly pre-harvest estimate.'
        if text!=p.text:p.text=text
    d.save(path)
# Keep the sequestration builder consistent with the confirmed site history.
path=root/'scripts/build_soc_sequestration_note.py';s=path.read_text()
for old,new in replacements.items():s=s.replace(old,new)
lines=s.splitlines()
for i,line in enumerate(lines):
    if line.startswith("p(d,'The proposed conversion dates are"):
        lines[i]='p(d,'+repr(chronology)+')'
    if line.startswith("p(d,'Confirm the onset and continuity"):
        lines[i]='p(d,'+repr(decisions)+')'
path.write_text('\n'.join(lines)+'\n')
meta=root/'results/checks/soil_provenance/confirmed_site_metadata.json'
m=json.loads(meta.read_text());m.update(experiment_start_year=1992,continuous_fallow_grassland_since=1992,last_crop_sown='autumn 2003',last_crop_harvest='August 2004',continuous_cropping_grassland_since='after August 2004 harvest',grassland_continuity='F continuous since start; C continuous since cessation; user confirmed 2026-10-22',soc_duration_convention='32 and 20 nominal calendar years; exact elapsed duration pending verification of sample date',tree_phase_audit='2004 cutoff; 2002-2005 Boundary; Post begins 2005-2006 interval; assignments unchanged')
meta.write_text(json.dumps(m,indent=2)+'\n')
print('Updated both notes, sequestration builder and confirmed site metadata.')
