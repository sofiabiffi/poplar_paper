from pathlib import Path
import importlib.util,os,tempfile
root=Path.cwd()/'poplar_paper/manuscript/analysis_notes'; qa=root/'_qa'; temp=qa/'_tmp';temp.mkdir(parents=True,exist_ok=True);tempfile.tempdir=str(temp)
os.environ['PATH']=r'C:\Users\sofia\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin'+os.pathsep+os.environ['PATH']
p=Path(r'C:\Users\sofia\.codex\plugins\cache\openai-primary-runtime\documents\26.1020.11127\skills\documents\render_docx.py')
spec=importlib.util.spec_from_file_location('render_docx',p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def pdf(doc_path,user_profile,convert_tmp_dir,stem,verbose):return str(qa/stem/(stem+'.pdf')),'Word export'
m.convert_to_pdf=pdf
print(m.rasterize(str(root/'04_soil_carbon_stocks.docx'),str(qa/'04_soil_carbon_stocks'),120,False,False))
