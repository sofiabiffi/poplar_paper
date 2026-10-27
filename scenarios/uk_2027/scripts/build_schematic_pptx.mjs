import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {Presentation,PresentationFile} from 'file:///C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
await fs.mkdir(path.join(root,'qa'),{recursive:true});
process.env.RUNTIME_NODE_MODULES='C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
process.env.RUNTIME_NODE=process.execPath;
const {boxes,arrows}=JSON.parse(await fs.readFile(path.join(root,'schematic.json'),'utf8'));
const presentation=Presentation.create({slideSize:{width:1020,height:1140}});
const slide=presentation.slides.add();slide.background.fill='#FFFFFF';
const palette={Scenario:'#0072B2',Evidence:'#666666',Calculation:'#666666',AGB:'#0072B2',BGB:'#009E73',SOC:'#E69F00',Output:'#666666'};
const sx=81,sy=1092/12.1;
const X=x=>24+x*sx,Y=y=>24+(12.1-y)*sy;
for(const [i,a]of arrows.entries()){
 slide.shapes.add({geometry:'connector',kind:'straight',name:`Flow arrow ${i+1}`,
  position:{left:X(a.x),top:Y(a.y),width:(a.xend-a.x)*sx,height:(a.y-a.yend)*sy},
  line:{fill:'#777777',style:'solid',width:1.3},tail:{type:'triangle',width:'med',length:'med'}});
}
for(const [i,b]of boxes.entries()){
 const left=X(b.x-b.w/2),top=Y(b.y+b.h/2),width=b.w*sx,height=b.h*sy;
 slide.shapes.add({geometry:'rect',name:`Box ${i+1}: ${b.title}`,position:{left,top,width,height},fill:'#FFFFFF',line:{fill:palette[b.group],style:'solid',width:1.8}});
 const heading=slide.shapes.add({geometry:'textbox',name:`Heading ${i+1}: ${b.title}`,position:{left:left+8,top:top+7,width:width-16,height:30},fill:'none',line:{fill:'none',width:0}});
 heading.text=b.title;heading.text.style={typeface:'Arial',fontSize:18,bold:true,color:'#000000',alignment:'center',verticalAlignment:'middle',autoFit:'none',wrap:'none',insets:0};
 const body=slide.shapes.add({geometry:'textbox',name:`Text ${i+1}: ${b.title}`,position:{left:left+9,top:top+40,width:width-18,height:height-48},fill:'none',line:{fill:'none',width:0}});
 body.text=b.body;body.text.style={typeface:'Arial',fontSize:15.5,color:'#000000',alignment:'center',verticalAlignment:'middle',autoFit:'none',wrap:'none',insets:0};
}
slide.speakerNotes.text='Sources: UK scenario methods, 05_carbon_scenario_planning.docx. Land areas: Defra Agriculture in the United Kingdom 2025, Chapter 2 Table 2.1, https://www.gov.uk/government/statistics/agriculture-in-the-united-kingdom-2025/chapter-2-structure-of-industry. Planting-layout context: Thillainathan I (2021), Role of agroforestry and hedges in UK climate targets, CCC, slide 7. Carbon fractions: calculated unweighted summaries from Schulz-Nielsen et al. (2026), Table 2, https://doi.org/10.3390/f17030395. Tree trajectory: arithmetic mean of 45 Trichobel trees from the study. SOC rate: 32-year annualised ESM tree-row excess relative to arable soil. Croppable and cropped scenarios are alternatives. No additional SOC on permanent grassland or alleys. Growth across layouts is assumed identical. All slide text, boxes and connectors are editable native objects.';
const png=await presentation.export({slide,format:'png',scale:1.5});
await fs.writeFile(path.join(root,'qa/powerpoint_preview.png'),new Uint8Array(await png.arrayBuffer()));
const candidatePath=path.join(root,'build/candidate.pptx');
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);
const skill='C:/Users/sofia/.codex/plugins/cache/openai-primary-runtime/presentations/26.1025.11240/skills/presentations';
const {finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')).href);
const result=await finalizePresentation({
 workspaceDir:root,candidatePath,finalPath:path.join(root,'outputs/uk_upscaling_method_editable.pptx'),
 pythonExecutable:'C:/Users/sofia/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe',
 integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
 layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
 layoutArgs:['--expected-slide-size-emu',`${1020*9525},${1140*9525}`,'--validate-bullet-geometry','--validate-heading-fit'],
 explicitTotalSlideCount:1,requiredNativeTableOwnerSlides:[],requiredNativeChartOwnerSlides:[],
 fontPolicy:{basis:'design',families:['Arial']},verifyArtifactToolImport:true,
 receiptPath:path.join(root,'qa/presentation_validation.json')
});
console.log(JSON.stringify(result));
