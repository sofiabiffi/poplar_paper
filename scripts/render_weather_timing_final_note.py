from pathlib import Path
import importlib.util,os,tempfile,sys
root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
qa=root/'manuscript/analysis_notes/_qa/weather_timing_final'
tmp=qa/'_tmp';tmp.mkdir(parents=True,exist_ok=True);tempfile.tempdir=str(tmp)
os.environ['PATH']=r'C:\Users\sofia\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin'+os.pathsep+os.environ['PATH']
path=Path(r'C:\Users\sofia\.codex\plugins\cache\openai-primary-runtime\documents\26.1022.11436\skills\documents\render_docx.py')
spec=importlib.util.spec_from_file_location('renderer',path)
renderer=importlib.util.module_from_spec(spec);spec.loader.exec_module(renderer)
def exported_pdf(doc_path,user_profile,convert_tmp_dir,stem,verbose):
    pdf=qa/(stem+'.pdf')
    assert pdf.exists(),pdf
    return str(pdf),'Microsoft Word export to a fresh QA path'
renderer.convert_to_pdf=exported_pdf
pages=renderer.rasterize(str(root/'manuscript/analysis_notes/02_weather_and_PAIC.docx'),str(qa),120,False,False)
print('Weather timing note:',len(pages),'pages rendered')


