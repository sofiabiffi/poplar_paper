from pathlib import Path
import importlib.util, os, tempfile
root=Path.cwd()/"poplar_paper/manuscript/analysis_notes"
qa=root/"_qa"
temp=qa/"_tmp";temp.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(temp)
os.environ["PATH"] = r"C:\Users\sofia\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin" + os.pathsep + os.environ["PATH"]
path=Path(r"C:\Users\sofia\.codex\plugins\cache\openai-primary-runtime\documents\26.1020.11127\skills\documents\render_docx.py")
spec=importlib.util.spec_from_file_location("render_docx",path)
renderer=importlib.util.module_from_spec(spec);spec.loader.exec_module(renderer)
# The packaged LibreOffice backend is unavailable on this Windows host.
# Use PDFs exported by Word and keep the packaged rasterisation workflow.
def word_pdf(doc_path,user_profile,convert_tmp_dir,stem,verbose):
    pdf=qa/stem/(stem+".pdf")
    if not pdf.exists(): raise FileNotFoundError(pdf)
    return str(pdf), "Microsoft Word fixed-format export"
renderer.convert_to_pdf=word_pdf
for doc in [root / "03_cropping_treatment_and_legacy.docx"]:
    if doc.name.startswith('~$'): continue
    pages=renderer.rasterize(str(doc),str(qa/doc.stem),120,False,False)
    print(doc.name, len(pages), "pages rendered")
