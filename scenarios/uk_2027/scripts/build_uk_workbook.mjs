import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Workbook,SpreadsheetFile} from 'file:///C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
await fs.mkdir(path.join(root,'qa'),{recursive:true});
const data=JSON.parse(await fs.readFile(path.join(root,'scenario_data.json'),'utf8'));
const wb=Workbook.create();
const names=['Results','Inputs','Annual build','Cohort factors','Growth source','Sources'];
const sh=Object.fromEntries(names.map(n=>[n,wb.worksheets.add(n)]));
const q=n=>`'${n}'`;
const put=(s,cell,v)=>sh[s].getRange(cell).values=[[v]];
const formula=(s,cell,f)=>sh[s].getRange(cell).formulas=[[f]];
function header(s,r,vals){sh[s].getRangeByIndexes(r-1,0,1,vals.length).values=[vals];sh[s].getRangeByIndexes(r-1,0,1,vals.length).format={fill:'#233F50',font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:36,verticalAlignment:'center',horizontalAlignment:'center'};}
function base(s,end,col){const z=sh[s];z.showGridLines=false;z.getRange(`A1:${col}${end}`).format.font={name:'Arial',size:10};z.getRange(`A1:${col}${end}`).format.verticalAlignment='center';z.getRange(`A1:${col}${end}`).format.rowHeight=22;z.getRange(`A1:${col}${end}`).format.columnWidth=17;z.getRange('A2').format.font={size:15,bold:true,color:'#000000'};}
base('Inputs',29,'H');put('Inputs','A2','Scenario inputs');put('Inputs','A3','Blue cells can be edited; grassland SOC credit is fixed at zero. Calendar: 2027-2056.');
const inp=[['AGB carbon fraction',.4884],['BGB carbon fraction',.4690],['Root:shoot dry-biomass ratio',.26],['Tree-row SOC Mg C/ha/year',data.config.soc_tree_row_rate],['Grassland SOC credit fixed at zero',0]];
for(let i=0;i<inp.length;i++){put('Inputs',`A${i+5}`,inp[i][0]);put('Inputs',`B${i+5}`,inp[i][1]);}
formula('Inputs','B10','=B7*B6/B5');put('Inputs','A10','BGB C / AGB C');
header('Inputs',12,['Land definition','Baseline ha','Adoption','Trees / ha','Strip width m','Row centres m','Tree spacing m','Target system ha']);
for(let i=0;i<3;i++){const r=i+13,l=data.lands[i];put('Inputs',`A${r}`,l.land);put('Inputs',`B${r}`,l.baseline_ha);put('Inputs',`C${r}`,l.adoption_fraction);put('Inputs',`E${r}`,2);put('Inputs',`F${r}`,i?30:10);if(i){put('Inputs',`G${r}`,7);formula('Inputs',`D${r}`,`=10000/(F${r}*G${r})`);}else{put('Inputs',`D${r}`,166);formula('Inputs',`G${r}`,`=10000/(D${r}*F${r})`);}formula('Inputs',`H${r}`,`=B${r}*C${r}`);}
const notes=[
'Period: 1 January 2027 to 1 January 2057. End-year outputs: 2050 (24 periods) and 2056 (30 periods).',
'Planting is at the beginning of each year. Constant planting uses 24 equal cohorts, 2027-2050 inclusive.',
'Land targets are whole-system hectares containing trees and alleys, not tree-strip hectares. Cropland definitions are alternatives.',
'Grassland row geometry is confirmed: 2 m strips / 10 m row centres; density retained at 166 trees/ha.',
'No additional SOC accumulation is credited to tree rows or alleys on permanent grassland.',
'Croppable land also includes temporary grass and fallow. Its uniform arable SOC baseline is a simplifying assumption.',
'No mortality, harvesting, management emissions or displacement model. Combined stock means additional carbon, not total pre-existing SOC.',
'Values are deterministic scenario outcomes. No confidence intervals or invented growth reductions. Trichobel is a modelling exemplar.'];
notes.forEach((v,i)=>put('Inputs',`A${18+i}`,v));
sh.Inputs.getRange('A5:A10').format.columnWidth=38;sh.Inputs.getRange('B5:B8').format={font:{color:'#0072B2'},fill:'#EDF5FA'};sh.Inputs.getRange('B13:C15').format={font:{color:'#0072B2'},fill:'#EDF5FA'};sh.Inputs.getRange('D13:G15').format.fill='#EDF5FA';sh.Inputs.getRange('B5:B10').setNumberFormat('0.0000');sh.Inputs.getRange('C13:C15').setNumberFormat('0.0%');sh.Inputs.getRange('B13:B15').setNumberFormat('#,##0');sh.Inputs.getRange('D13:H15').setNumberFormat('#,##0.00');
sh.Inputs.dataValidations.add({range:'B5:B7',rule:{type:'decimal',operator:'between',formula1:0,formula2:1}});


base('Growth source',40,'F');put('Growth source','A2','Trichobel age trajectory');put('Growth source','A3','Arithmetic mean of 45 trees across the original treatments. Historical stocks used 0.50 C and 166 trees/ha.');
header('Growth source',4,['Age years','Measurement year','Source AGB C Mg/ha','Dry mass kg/tree','Evidence','Dry mass / age']);
for(const c of data.curve){const r=c.age+5;put('Growth source',`A${r}`,c.age);const o=data.observations.find(o=>o.age===c.age);put('Growth source',`B${r}`,o?.measurement_year??null);put('Growth source',`C${r}`,c.mean_dry_kg_tree*.5*166/1000);formula('Growth source',`D${r}`,`=C${r}/0.5/166*1000`);put('Growth source',`E${r}`,c.support);formula('Growth source',`F${r}`,`=IF(A${r}=0,0,D${r}/A${r})`);}
sh['Growth source'].getRange('C5:D36').setNumberFormat('0.0000');sh['Growth source'].getRange('E4:E36').format.columnWidth=32;sh['Growth source'].freezePanes.freezeRows(4);

base('Cohort factors',66,'G');put('Cohort factors','A2','Planting cohorts through time');put('Cohort factors','A3','Unit factors per hectare of the final target; growth lookups use the age trajectory.');
header('Cohort factors',4,['Planting schedule','End year','New target fraction','Established fraction','Weighted dry kg/tree','Area years / target ha','Weighted dry mass / age']);
let factors=new Map();let fr=5;
for(const schedule of ['All planted in 2027','Constant planting to 2050'])for(let year=2027;year<=2056;year++,fr++){
 const a=year-2026,fast=schedule.startsWith('All');factors.set(schedule+'|'+year,fr);
 put('Cohort factors',`A${fr}`,schedule);put('Cohort factors',`B${fr}`,year);
 formula('Cohort factors',`C${fr}`,fast?`=IF(B${fr}=2027,1,0)`:`=IF(B${fr}<=2050,1/24,0)`);
 formula('Cohort factors',`D${fr}`,fast?'=1':`=MIN(B${fr}-2026,24)/24`);
 formula('Cohort factors',`E${fr}`,fast?`=${q('Growth source')}!D${5+a}`:`=SUM(${q('Growth source')}!D${5+Math.max(1,a-23)}:D${5+a})/24`);
 formula('Cohort factors',`F${fr}`,fast?`=B${fr}-2026`:`=MIN(B${fr}-2026,24)*(MAX(1,B${fr}-2049)+B${fr}-2026)/2/24`);
 formula('Cohort factors',`G${fr}`,fast?`='Growth source'!F${5+a}`:`=SUM('Growth source'!F${5+Math.max(1,a-23)}:F${5+a})/24`);
}
sh['Cohort factors'].getRange('A4:A64').format.columnWidth=31;sh['Cohort factors'].getRange('C5:F64').setNumberFormat('0.0000');sh['Cohort factors'].freezePanes.freezeRows(4);

base('Annual build',365,'V');put('Annual build','A2','Annual cohort calculation');put('Annual build','A3','Stocks and annual differences; totals are additional to a tree-free baseline. No alley SOC credited.');
header('Annual build',4,['Scenario code','Land','End year','Target ha','New ha','Established ha','Trees','AGB C Mg','BGB C Mg','SOC C Mg','Combined C Mg','Annual AGB C Mg','Annual combined C Mg','AGB Mt CO2','Combined Mt CO2','Annual AGB Mt CO2','Annual combined Mt CO2','Combined without grass SOC','Annual without grass SOC','Strip fraction','Area years / ha','AGB MAIC Mt CO2/yr']);
const lookup=new Map();let ar=5;
for(const code of ['CB_FAST','CB_STEADY','CR_FAST','CR_STEADY']){
 const def=code.startsWith('CB')?'Croppable area':'Cropped area';const schedule=code.endsWith('FAST')?'All planted in 2027':'Constant planting to 2050';
 for(const land of ['Permanent grassland',def]){
  const ir=land==='Permanent grassland'?13:(def==='Croppable area'?14:15);
  for(let year=2027;year<=2056;year++,ar++){
   const r=ar,f=factors.get(schedule+'|'+year);lookup.set(code+'|'+land+'|'+year,r);
   put('Annual build',`A${r}`,code);put('Annual build',`B${r}`,land);put('Annual build',`C${r}`,year);
   const fm={D:`=Inputs!H${ir}`,E:`=D${r}*'Cohort factors'!C${f}`,F:`=D${r}*'Cohort factors'!D${f}`,G:`=F${r}*Inputs!D${ir}`,
    H:`=D${r}*Inputs!D${ir}*'Cohort factors'!E${f}*Inputs!$B$5/1000`,I:`=H${r}*Inputs!$B$10`,
    J:`=D${r}*T${r}*Inputs!$B$8*U${r}${ir===13?'*0':''}`,K:`=SUM(H${r}:J${r})`,
    L:year===2027?`=H${r}`:`=H${r}-H${r-1}`,M:year===2027?`=K${r}`:`=K${r}-K${r-1}`,
    N:`=H${r}*44/12/1000000`,O:`=K${r}*44/12/1000000`,P:`=L${r}*44/12/1000000`,Q:`=M${r}*44/12/1000000`,
    R:ir===13?`=(H${r}+I${r})*44/12/1000000`:`=O${r}`,S:ir===13?(year===2027?`=R${r}`:`=R${r}-R${r-1}`):`=Q${r}`,
    T:`=Inputs!E${ir}/Inputs!F${ir}`,U:`='Cohort factors'!F${f}`,V:`=D${r}*Inputs!D${ir}*'Cohort factors'!G${f}*Inputs!$B$5/1000*44/12/1000000`};
   for(const [c,v] of Object.entries(fm))formula('Annual build',c+r,v);
  }
 }
 for(let year=2027;year<=2056;year++,ar++){
  const r=ar,a=lookup.get(code+'|Permanent grassland|'+year),b=lookup.get(code+'|'+def+'|'+year);lookup.set(code+'|UK total|'+year,r);
  put('Annual build',`A${r}`,code);put('Annual build',`B${r}`,'UK total');put('Annual build',`C${r}`,year);
  for(const c of 'DEFGHIJKLMNOPQRSV')formula('Annual build',c+r,`=${c}${a}+${c}${b}`);
 }
}
sh['Annual build'].getRange('B4:B364').format.columnWidth=25;sh['Annual build'].getRange('D5:S364').setNumberFormat('#,##0.000');sh['Annual build'].freezePanes.freezeRows(4);

base('Results',57,'L');put('Results','A2','UK trees on farmland scenarios');put('Results','A3','Trichobel. Planting target reached by 2050. Croppable and cropped definitions are alternatives.');
header('Results',5,['Cropland definition','Planting schedule','End year','AGB stock Mt CO2','Combined stock Mt CO2','AGB PAIC Mt CO2/yr','AGB MAIC Mt CO2/yr']);
let rr=6;
for(const code of ['CB_FAST','CB_STEADY','CR_FAST','CR_STEADY'])for(const year of [2050,2056]){
 const r=rr++,ref=lookup.get(code+'|UK total|'+year);put('Results',`A${r}`,code.startsWith('CB')?'Croppable 6.125m ha':'Arable cropped 4.089m ha');put('Results',`B${r}`,code.endsWith('FAST')?'All planted in 2027':'Constant planting to 2050');put('Results',`C${r}`,year);
 for(const [col,source]of Object.entries({D:'N',E:'O',F:'P',G:'V'}))formula('Results',col+r,`='Annual build'!${source}${ref}`);
}
sh.Results.getRange('A5:A13').format.columnWidth=24;sh.Results.getRange('B5:B13').format.columnWidth=31;sh.Results.getRange('D6:I13').setNumberFormat('0.00');
put('Results','A15','Combined = AGB + BGB + additional SOC on cropland tree strips only. Grassland SOC credit is zero.');
put('Results','A16','PAIC and MAIC describe AGB only. Cropped-area results are tabulated; figures use the croppable baseline.');
header('Results',19,['Land definition','Target ha','Trees / ha','Trees at target','Tree-strip ha','Constant ha / year','Strip SOC Mg C/ha/year']);
for(let i=0;i<3;i++){const r=20+i,ir=13+i;formula('Results','A'+r,`=Inputs!A${ir}`);formula('Results','B'+r,`=Inputs!H${ir}`);formula('Results','C'+r,`=Inputs!D${ir}`);formula('Results','D'+r,`=B${r}*C${r}`);formula('Results','E'+r,`=B${r}*Inputs!E${ir}/Inputs!F${ir}`);formula('Results','F'+r,`=B${r}/24`);formula('Results','G'+r,`=Inputs!$B$8*Inputs!E${ir}/Inputs!F${ir}${ir===13?'*0':''}`);}
sh.Results.getRange('B20:F22').setNumberFormat('#,##0.0');sh.Results.getRange('G20:G22').setNumberFormat('0.0000');
header('Results',26,['End year','Croppable all 2027','Croppable constant','Cropped all 2027','Cropped constant']);
for(let year=2027;year<=2056;year++){const r=year-2027+27;put('Results','A'+r,String(year));for(const [i,code]of ['CB_FAST','CB_STEADY','CR_FAST','CR_STEADY'].entries())formula('Results',String.fromCharCode(66+i)+r,`='Annual build'!O${lookup.get(code+'|UK total|'+year)}`);}
sh.Results.getRange('B27:E56').setNumberFormat('0.0');
const chart=sh.Results.charts.add('line',sh.Results.getRange('A26:C56'));chart.title='Croppable case: combined carbon stock (Mt CO2)';chart.titleTextStyle.fontSize=13;chart.setPosition('G26','O48');chart.xAxis={axisType:'textAxis',textStyle:{fontSize:10,typeface:'Arial'}};chart.yAxis={numberFormatCode:'0',numberFormatSourceLinked:false,textStyle:{fontSize:10,typeface:'Arial'}};chart.legend={position:'bottom',textStyle:{fontSize:10,typeface:'Arial'}};
for(const [i,s]of chart.series.items.entries()){const c=['#0072B2','#D55E00'][i];s.fill=c;s.line={fill:c,style:i%2?'dashed':'solid',width:2};}

base('Sources',20,'D');put('Sources','A2','Sources and interpretation');header('Sources',4,['Input or context','Reference','Location','Interpretation']);
const sources=[
 ['Trichobel AGB stocks','annual_hybrid.csv','data/processed/annual_hybrid.csv','45 trees; arithmetic mean; 1993-2023; original carbon fraction 0.50 and density 166.'],
 ['Tree-row SOC','soc_sequestration_ESM_summary.csv','results/tables/soc_sequestration_ESM_summary.csv','Tree rows 32 years: 21.046292 Mg C/ha excess / 32 = 0.657696629.'],
 ['CCC scenario context','Thillainathan I (2021), Role of agroforestry and hedges in UK climate targets','references/Role of AF in net zero Indra, T. 2021.pdf, slide 7','Layout and 14%/7% context; not a like-for-like reproduction.'],
 ['UK land denominators','Defra Agriculture in the UK 2025, Table 2.1','https://www.gov.uk/government/statistics/agriculture-in-the-united-kingdom-2025/chapter-2-structure-of-industry','Use Defra 2025: croppable 6.125m ha; arable crops 4.089m ha. The cropped alternative excludes horticulture.'],
 ['Root allocation and C fractions','Schulz-Nielsen et al. 2026; Cairns et al. 1997','https://doi.org/10.3390/f17030395','0.4884 and 0.4690 are calculated unweighted summaries; root:shoot 0.26 retained as assumption.'],
 ['Earlier net-zero modelling','Burgess PJ and Graves A (2022), The Potential Contribution of Agroforestry to Net Zero Objectives','https://dspace.lib.cranfield.ac.uk/handle/1826/18664','Context; scenarios here omit emissions, harvesting and displacement, so are not net GHG balances.'],
 ['SFI very low density','AGF1 (checked 26 October 2026)','https://www.gov.uk/find-funding-for-land-or-farms/agf1-maintain-very-low-density-in-field-agroforestry-on-less-sensitive-land','30-50 trees/ha; GBP248/ha/year. England only; density does not establish full eligibility.'],
 ['SFI low density','AGF2 (checked 26 October 2026)','https://www.gov.uk/find-funding-for-land-or-farms/agf2-maintain-low-density-in-field-agroforestry-on-less-sensitive-land','51-130 trees/ha; GBP385/ha/year. Grassland 166 is outside these two bands.'],
 ['Timing and transfer','Scenario assumptions','Inputs sheet','Planting begins each calendar year; observed ages 1-30 used. Age31 measurement retained for context.'],
 ['Interpolation','Linear interpolation of mean stocks','Growth source sheet','Interpolated gaps are assumptions; no measured annual weather sequence forecast.'],
 ['Grassland geometry','Confirmed experimental analogue','Inputs sheet','166 trees/ha, 2m strips and 10m centres; 20% strips. 6m approximately within rows.']];
sh.Sources.getRange(`A5:D${sources.length+4}`).values=sources;sh.Sources.getRange('A4:A16').format.columnWidth=28;sh.Sources.getRange('B4:B16').format.columnWidth=55;sh.Sources.getRange('C4:C16').format.columnWidth=70;sh.Sources.getRange('D4:D16').format.columnWidth=80;sh.Sources.getRange('A5:D16').format.wrapText=true;sh.Sources.getRange('A5:D16').format.rowHeight=62;
sh.Results.tabColor='#233F50';sh.Inputs.tabColor='#79A6BF';
wb.recalculate();
const checks=[];
for(let i=0;i<8;i++){const row=6+i;const expected=data.milestones.filter(r=>r.land==='UK total')[i];const values=sh.Results.getRange(`D${row}:G${row}`).values[0];const ex=[expected.AGB_CO2_Mt,expected.total_CO2_Mt,expected.annual_AGB_CO2_Mt,expected.MAIC_AGB_CO2_Mt];for(let j=0;j<ex.length;j++){if(Math.abs(values[j]-ex[j])>1e-7)throw Error(`Mismatch ${row}/${j}: ${values[j]} vs ${ex[j]}`);}checks.push({row,matched:true});}
const before=sh.Results.getRange('D6').values[0][0];put('Inputs','B5',.5);wb.recalculate();const changed=sh.Results.getRange('D6').values[0][0];if(Math.abs(changed/before-.5/.4884)>1e-8)throw Error('Carbon fraction edit failed');put('Inputs','B5',.4884);wb.recalculate();
if(sh['Annual build'].getRange('J5').values[0][0]!==0)throw Error('Grassland SOC is not zero');
const baselineArea=sh.Results.getRange('B20').values[0][0];put('Inputs','C13',.07);wb.recalculate();if(Math.abs(sh.Results.getRange('B20').values[0][0]-baselineArea/2)>1e-7)throw Error('Adoption test failed');put('Inputs','C13',.14);
const baselineTrees=sh.Results.getRange('D20').values[0][0];put('Inputs','D13',83);wb.recalculate();if(Math.abs(sh.Results.getRange('D20').values[0][0]-baselineTrees/2)>1e-7)throw Error('Density test failed');put('Inputs','D13',166);wb.recalculate();
const err=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!',options:{useRegex:true,maxResults:30},maxChars:2000});
await fs.writeFile(path.join(root,'qa/workbook_checks.json'),JSON.stringify({checks,errorScan:err.ndjson},null,2));
console.log((await wb.inspect({kind:'table',range:'Results!A5:G13',include:'values,formulas',tableMaxRows:9,tableMaxCols:9,maxChars:1800})).ndjson);
const out=await SpreadsheetFile.exportXlsx(wb);await out.save(path.join(root,'outputs/uk_trees_on_farmland_2027_2056.xlsx'));
for(const [s,range]of [['Results','A2:G22'],['Results','G26:O48'],['Inputs','A2:H15'],['Annual build','A2:K12'],['Cohort factors','A2:F12'],['Growth source','A2:E14'],['Sources','A2:D8']]){try{const blob=await wb.render({sheetName:s,range,scale:1,format:'png'});await fs.writeFile(path.join(root,'qa',s.replaceAll(' ','_')+(range==='G26:O48'?'_chart':'')+'.png'),new Uint8Array(await blob.arrayBuffer()));}catch(e){console.log('Render failed',s,String(e).slice(0,200));}}
console.log('Workbook saved and verified against Python cohort results');

await import('./refresh_uk_workbook_SOC.mjs');
