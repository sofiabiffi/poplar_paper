import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {SpreadsheetFile,FileBlob} from 'file:///C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
await fs.mkdir(path.join(root,'qa'),{recursive:true});
let sourceFile=path.join(root,'source.xlsx');
try{await fs.access(sourceFile);}catch{sourceFile=path.join(root,'outputs/uk_trees_on_farmland_2027_2056.xlsx');}
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(sourceFile));
const sh=n=>wb.worksheets.getItem(n);
if(process.argv.includes('--inspect')){
 console.log((await wb.inspect({kind:'table',range:'Inputs!A12:H15',include:'values,formulas',tableMaxRows:4,tableMaxCols:8,maxChars:2200})).ndjson);
 const png=await wb.render({sheetName:'Results',range:'A2:G22',scale:1,format:'png'});
 await fs.writeFile(path.join(root,'qa/workbook_before.png'),new Uint8Array(await png.arrayBuffer()));process.exit(0);
}
const data=JSON.parse(await fs.readFile(path.join(root,'scenario_data.json'),'utf8'));
sh('Inputs').getRange('B14:B15').values=[[6125000],[4089000]];
for(let r=6;r<=13;r++)sh('Results').getRange('A'+r).values=[[r<=9?'Croppable 6.125m ha':'Arable cropped 4.089m ha']];
for(let r=5;r<=16;r++){
 const v=sh('Sources').getRange('D'+r).values[0][0];
 if(typeof v==='string'&&v.includes('6.1m'))sh('Sources').getRange('D'+r).values=[[v.replace('Use requested rounded 6.1m and 4.1m; 4.1m approximates arable crops, not all horticulture.','Use Defra 2025: croppable 6.125m ha; arable crops 4.089m ha. The cropped alternative excludes horticulture.')]];
}
wb.recalculate();
const checks=[];
for(let i=0;i<8;i++){
 const row=6+i,e=data.milestones.filter(r=>r.land==='UK total')[i];
 const a=sh('Results').getRange(`D${row}:G${row}`).values[0];
 const expected=[e.AGB_CO2_Mt,e.total_CO2_Mt,e.annual_AGB_CO2_Mt,e.MAIC_AGB_CO2_Mt];
 expected.forEach((x,j)=>{if(Math.abs(x-a[j])>1e-7)throw Error(`Mismatch row ${row} metric ${j}: ${x} != ${a[j]}`);});checks.push({row,matched:true});
}
if(sh('Inputs').getRange('B8').values[0][0]!==data.config.soc_tree_row_rate)throw Error('SOC input changed');
const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!',options:{useRegex:true,maxResults:30},maxChars:1500});
await fs.writeFile(path.join(root,'qa/workbook_land_checks.json'),JSON.stringify({checks,errorScan:errors.ndjson},null,2));
await(await SpreadsheetFile.exportXlsx(wb)).save(path.join(root,'outputs/uk_trees_on_farmland_2027_2056.xlsx'));
for(const [name,range]of [['Results','A2:G22'],['Results','G26:O48'],['Inputs','A12:H15'],['Sources','A5:D8']]){
 const blob=await wb.render({sheetName:name,range,scale:1,format:'png'});await fs.writeFile(path.join(root,'qa',name+(range==='G26:O48'?'_chart':'')+'.png'),new Uint8Array(await blob.arrayBuffer()));
}
console.log('All eight UK milestone results agree with the cohort calculation.');
