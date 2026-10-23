import fs from 'node:fs/promises';
import {createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
const require=createRequire('C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {Workbook,SpreadsheetFile}=await import(pathToFileURL(require.resolve('@oai/artifact-tool')).href);
const base='C:/Users/sofia/Documents/misc_Rstuff/poplar_paper';
const out=base+'/outputs/soil_provenance_20261022';await fs.mkdir(out,{recursive:true});
const p=JSON.parse(await fs.readFile(base+'/data/processed/study_site_soil_2024_payload.json','utf8'));
const wb=Workbook.create();
function table(name,headers,rows){
 const s=wb.worksheets.add(name);s.showGridLines=false;
 s.getRangeByIndexes(0,0,rows.length+1,headers.length).values=[headers,...rows];
 s.getUsedRange().format.font={name:'Arial',size:10};
 s.getUsedRange().format.rowHeight=19;
 s.getUsedRange().format.columnWidth=19;
 s.getRangeByIndexes(0,0,1,headers.length).format={fill:'#23465B',font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:44,verticalAlignment:'center'};
 s.tables.add(s.getUsedRange(),true,name.replaceAll('_','')+'Table');
 s.freezePanes.freezeRows(1);
 return s;
}
const main=table('soil_0_30',p.headers,p.rows);
for(const [j,h] of p.headers.entries()){
 const col=main.getRangeByIndexes(1,j,p.rows.length,1);
 if(['profile_id','sample_id','legacy_profile_id','field_id','strata_id'].includes(h)) main.getRangeByIndexes(0,j,p.rows.length+1,1).format.columnWidth=33;
 if(['location','former_treatment','location_correction'].includes(h))main.getRangeByIndexes(0,j,p.rows.length+1,1).format.columnWidth=29;
 if(h==='former_treatment_code')main.getRangeByIndexes(0,j,p.rows.length+1,1).format.columnWidth=25;
 if(['fine_bd_gcm3','total_bd_gcm3','SOC_perc'].includes(h))col.setNumberFormat('0.000');
 if(['latitude','longitude'].includes(h))col.setNumberFormat('0.000000');
 if(['company_carbon_stock_t_ha','total_dry_mass_g','fine_fraction_mass_g'].includes(h))col.setNumberFormat('0.000');
 if(h==='date_extracted'){col.values=p.rows.map(r=>[new Date(r[j]+'T00:00:00Z')]);col.setNumberFormat('yyyy-mm-dd');}
}
const raw=table('company_site_results',p.raw_headers,p.raw_rows);
raw.getRange('B:G').format.columnWidth=32;
const dateIndex=p.raw_headers.indexOf('Date extracted');
raw.getRangeByIndexes(1,dateIndex,p.raw_rows.length,1).values=p.raw_rows.map(r=>[new Date(r[dateIndex])]);
raw.getRangeByIndexes(1,dateIndex,p.raw_rows.length,1).setNumberFormat('yyyy-mm-dd');
raw.getRangeByIndexes(1,7,p.raw_rows.length,2).setNumberFormat('0.000000');
const meta=table('Guide',['Topic','Definition or source'],[...p.notes,['Data dictionary','Definitions below apply to soil_0_30.'],...p.dictionary]);
meta.getRange('A:A').format.columnWidth=31;meta.getRange('B:B').format.columnWidth=110;
meta.getUsedRange().format.wrapText=true;meta.getUsedRange().format.autofitRows();
wb.recalculate();
console.log((await wb.inspect({kind:'table',range:'soil_0_30!A1:P5',tableMaxRows:5,tableMaxCols:16,maxChars:1500})).ndjson);
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!',options:{useRegex:true,maxResults:10},maxChars:600})).ndjson);
for(const [sheetName,range] of [['soil_0_30','A1:H10'],['soil_0_30','I1:Q8'],['company_site_results','A1:F8'],['Guide','A1:B16']]){
 const blob=await wb.render({sheetName,range,scale:1.4,format:'png'});
 await fs.writeFile(out+'/'+sheetName+'_'+range[0]+'_preview.png',new Uint8Array(await blob.arrayBuffer()));
}
await (await SpreadsheetFile.exportXlsx(wb)).save(out+'/study_site_soil_2024.xlsx');
console.log('Saved '+out+'/study_site_soil_2024.xlsx');
