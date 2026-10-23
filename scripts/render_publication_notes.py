from pathlib import Path
import importlib.util, os, tempfile
root=Path(__file__).resolve().parents[1]
qa=root/'manuscript/analysis_notes/_qa/publication'
tmp=qa/'_tmp'; tmp.mkdir(exist_ok=True,parents=True); tempfile.tempdir=str(tmp)
os.environ['PATH']=r'C:\Users\sofia\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin'+os.pathsep+os.environ['PATH']
path=Path(r'C:\Users\sofia\.codex\plugins\cache\openai-primary-runtime\documents\26.1022.11436\skills\documents\render_docx.py')
spec=importlib.util.spec_from_file_location('renderer',path)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def word_pdf(doc_path,user_profile,convert_tmp_dir,stem,verbose):
    return str(qa/stem/(stem+'.pdf')),'Microsoft Word fixed-format export'
m.convert_to_pdf=word_pdf
for folder in sorted(qa.iterdir()):
    if not (folder/(folder.name+'.pdf')).exists(): continue
    pages=m.rasterize(str(root/'manuscript/analysis_notes'/f'{folder.name}.docx'),str(folder),100,False,False)
    print(folder.name,len(pages))
