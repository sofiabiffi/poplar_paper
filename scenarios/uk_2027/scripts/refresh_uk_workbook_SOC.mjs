import fs from 'node:fs/promises';import path from 'node:path';import {fileURLToPath} from 'node:url';
import {SpreadsheetFile,FileBlob} from 'file:///C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const root=process.argv[2]||path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const data=JSON.parse(await fs.readFile(path.join(root,'scenario_data.json'),'utf8'));
const source=JSON.parse(await fs.readFile(path.join(root,'soc_rate_input.json'),'utf8'));
const file=path.join(root,'outputs/uk_trees_on_farmland_2027_2056.xlsx');const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(file));
const get=n=>wb.worksheets.getItem(n),sources=get('Sources'),inputs=get('Inputs'),results=get('Results');
const put=(s,c,v)=>s.getRange(c).values=[[v]],f=(s,c,v)=>s.getRange(c).formulas=[[v]];
sources.getRange('A19:D19').values=[['SOC rate calibration','Value','Units','Interpretation']];sources.getRange('A19:D19').format={fill:'#233F50',font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:30,wrapText:true};
sources.getRange('A20:D25').values=[['Tree-row ESM mean stock',source.tree_stock,'Mg C/ha','21 complete tree-row cores'],['Arable FD mean stock',source.arable_stock,'Mg C/ha','47 complete arable cores'],['Duration',32,'years','Agreed duration 1992-2024'],['Annualised SOC excess',null,'Mg C/ha/year','(Tree ESM - arable FD) / years'],['Tree-row stock SD',source.tree_stock_SD,'Mg C/ha','Variation among tree cores'],['Annualised profile SD',null,'Mg C/ha/year','Tree-row stock SD / years; arable mean held fixed']];
f(sources,'B23','=(B20-B21)/B22');f(sources,'B25','=B24/B22');sources.getRange('A20:D25').format.font={name:'Arial',size:10};sources.getRange('A20:D25').format.wrapText=true;sources.getRange('A20:D25').format.rowHeight=40;sources.getRange('B20:B25').setNumberFormat('0.000000');
put(sources,'D6',`Tree ESM minus arable fixed-depth stock / 32 years. Rate ${source.rate.toFixed(9)}; profile SD ${source.rate_SD.toFixed(9)} Mg C/ha/year. SD is descriptive, not a confidence interval.`);
f(inputs,'B8',"='Sources'!B23");put(inputs,'A25','Scenario calculations use the mean SOC rate. Profile SD is descriptive; no uncertainty bands are applied.');
put(results,'A17',`Input SOC rate: ${source.rate.toFixed(3)} Mg C/strip ha/year; profile SD ${source.rate_SD.toFixed(3)}. Scenarios use the mean rate only.`);
wb.recalculate();const checks=[];
for(let i=0;i<8;i++){
 const r=i+6,exp=data.milestones.filter(r=>r.land==='UK total')[i];const v=results.getRange(`D${r}:G${r}`).values[0];const expected=[exp.AGB_CO2_Mt,exp.total_CO2_Mt,exp.annual_AGB_CO2_Mt,exp.MAIC_AGB_CO2_Mt];
 for(let j=0;j<4;j++)if(Math.abs(v[j]-expected[j])>1e-7)throw Error(`Workbook mismatch ${r}/${j}`);checks.push({row:r,matched:true});
}
const start=results.getRange('E6').values[0][0];const form=inputs.getRange('B8').formulas;put(inputs,'B8',0);wb.recalculate();if(!(results.getRange('E6').values[0][0]<start))throw Error('Rate change failed');inputs.getRange('B8').formulas=form;wb.recalculate();
const err=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!',options:{useRegex:true,maxResults:30},maxChars:1000});
const qa=path.join(root,'qa/SOC_reference_update');await fs.mkdir(qa,{recursive:true});await fs.writeFile(path.join(qa,'workbook_checks.json'),JSON.stringify({checks,rate_zero_recalculation:true,errorScan:err.ndjson},null,2));
await(await SpreadsheetFile.exportXlsx(wb)).save(file);
for(const [name,range]of [['Results','A2:G17'],['Results','G26:O48'],['Inputs','A2:H15'],['Sources','A19:D25'],['Annual build','A2:K12']]){const blob=await wb.render({sheetName:name,range,scale:1,format:'png'});await fs.writeFile(path.join(qa,name.replaceAll(' ','_')+(range==='G26:O48'?'_chart':'')+'.png'),new Uint8Array(await blob.arrayBuffer()));}
console.log('Workbook central results verified at all eight milestones; rate edits recalculate. SD only, no interval columns.');
