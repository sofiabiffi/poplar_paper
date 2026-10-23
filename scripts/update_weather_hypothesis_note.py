"""Update the existing weather note in place, preserving manual captions and styles."""
from pathlib import Path
import csv,json,shutil,sys
from datetime import datetime
from docx import Document
from docx.shared import Inches

root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
path=root/'manuscript/analysis_notes/02_weather_and_PAIC.docx'
d=Document(path)
history=path.parent/'_history';history.mkdir(exist_ok=True)
shutil.copy2(path,history/f'02_weather_and_PAIC_before_hypotheses_{datetime.now():%Y%m%d_%H%M%S}.docx')
def replace(prefix,new):
    found=[p for p in d.paragraphs if p.text.startswith(prefix)]
    assert len(found)==1,(prefix,len(found))
    found[0].text=new
    return found[0]
def replace_either(old,newprefix,new):
    found=[p for p in d.paragraphs if p.text.startswith(old) or p.text.startswith(newprefix)]
    assert len(found)==1,(old,len(found))
    found[0].text=new
    return found[0]

replace('Current analysis for paper drafting','Current analysis for paper drafting   |   23 October 2026')
replace_either('Summer rainfall is positively associated','Eight biological hypotheses were compared',
 'Eight biological hypotheses were compared directly, without excluding weather variables by correlation strength. Summer rainfall and temperature ranked first for all four hybrids, with clearer support in Beaupre and Robusta. The age-only alternative remained more competitive for Gibecq and Trichobel. Summer weather associations remain exploratory and cannot independently explain the causal basis of hybrid performance.')
replace_either('The model dataset contains 26 measurement years','The hypothesis comparison uses 24',
 'The hypothesis comparison uses 24 common complete-weather measurement years from 1994 to 2023 (96 hybrid summaries). Summer associations are then estimated using all 26 years with complete summer weather (104 summaries). Weather in year t − 1 is paired with PAIC measured in year t. Hybrids share weather occasions; four summaries per year do not constitute four independent weather replicates.')
replace_either('Calculated results from the weather screen','Comparing the weather hypotheses','Comparing the weather hypotheses')
caption=('Figure 1. Eight hypothesis models fitted on the same 24 years for each hybrid, with a Gamma log link and linear and squared age. Weather terms are named in the rows. Values are AICc minus the lowest AICc within each hybrid: zero marks the top candidate; lower values indicate more support after penalising complexity. Rankings are exploratory under remaining temporal dependence and prior examination of these data.')
cp=[p for p in d.paragraphs if p.text.startswith('Figure 1.')];assert len(cp)==1
cp=cp[0]
prev=cp._p.getprevious()
assert prev.xpath('.//w:drawing'),'Expected existing figure immediately before Figure 1 caption'
from docx.text.paragraph import Paragraph
image_para=Paragraph(prev,cp._parent)
image_para.clear();image_para.add_run().add_picture(str(root/'results/figures/weather_hypothesis_comparison.png'),width=Inches(6.6))
cp.text=caption
replace_either('We inspected scatterplots for all nine variables','We compared the same eight',
 'We compared the same eight models separately for each hybrid, as defined by the rows in Figure 1. Spring and summer conditions combine rainfall and temperature; other weather models add one sunshine, dry-spell or frost predictor. Every model retains quadratic age. All nine weather candidates enter this comparison; correlations do not filter their inclusion.')
replace_either('Summer rainfall has the clearest consistent positive raw association','Summer conditions ranked first',
 'Summer conditions ranked first for every hybrid. Age alone ranked second, with AICc differences of 5.98 for Beaupre, 2.30 for Gibecq, 5.85 for Robusta and 2.13 for Trichobel. Support is clearer for Beaupre and Robusta. The other weather hypotheses have differences of at least 4.67; this does not exclude environmental influences absent from the candidate set.')
replace_either('How the model variables were chosen','How the hypotheses were compared','How the hypotheses were compared')
replace_either('We retained summer rainfall as the clearest','AICc balances fitted likelihood',
 'AICc balances likelihood against the number of parameters, including Gamma dispersion. Every model uses identical responses and years. Measurement years 2001 and 2019 are excluded because of incomplete spring temperature or ground-frost records. The selected summer model then uses all 26 eligible summer years for the association plot; Figure 1 always compares 24 years.')
replace_either('This is hypothesis-guided exploratory selection','We also omitted each of the 24',
 'We also omitted each of the 24 years in turn and refitted all candidates. Summer remained first in 24/24 fits for Beaupre and Robusta, 23/24 for Gibecq and 22/24 for Trichobel. These are influence checks, not independent validation. Earlier data exploration informed the hypotheses; association intervals remain conditional on the selected summer model.')
replace_either('The same quadratic age specification is used in all four','The same quadratic age specification is used in all eight',
 'The same quadratic age specification is used in all eight hypothesis models (32 fits on the common 24 years). The combined summer-weather model ranks first in each hybrid and supplies the final associations. Its existing 26-year fit is retained after verifying that its PAIC and common-year summer weather inputs match the current data. The 26-year coefficient intervals describe that fitted model and do not include model-selection uncertainty; they are not model-averaged estimates.')
replace_either('The most consistent association is greater PAIC','The hypothesis comparison supports summer conditions',
 'The hypothesis comparison supports summer conditions over the other weather hypotheses considered. Support relative to age alone is clearer for Beaupre and Robusta. The reporting models associate wetter summers with greater PAIC, compatible with a role for water availability. The grouped summer-model ranking does not establish that both weather variables are individually necessary in every hybrid.')
replace_either('Weather refers to the growth year preceding measurement. Annualisation','Weather refers to the growth year preceding measurement; annualisation',
 'Weather refers to the growth year preceding measurement; annualisation cannot identify growth timing in missing years. AICc comparison uses 24 shared weather occasions, while final summer estimation uses 26. Reusing observations for selection and estimation makes the results exploratory rather than independent confirmation.')
replace_either('Residual correlations between consecutive calendar years','In the 24-year summer models',
 'In the 24-year summer models, consecutive-calendar-year residual correlations are approximately 0.50, 0.63, 0.38 and 0.02 for Beaupre, Gibecq, Robusta and Trichobel. AICc assumes independent errors, so these rankings remain approximate. The three-visit bootstrap accommodates some dependence, but its block length is not established as sufficient. AICc ranking alone does not validate the model.')
replace_either('Use Figure 2 for the weather associations','Use Figure 1 to show the hypothesis comparison',
 'Use Figure 1 to show the hypothesis comparison and Figure 2 for the conditional summer-weather associations. Explain that comparison uses 24 common years and the reporting summer models use all 26 eligible summer years. Figure S1 shows the fitted quadratic age shapes at fixed weather. Retain the age–time confounding, model-selection and temporal-dependence caveats.')
replace('Table S1.',
 'Table S1. These summaries describe the 26-year reporting summer models. Pseudo-R² = 1 − combined-model deviance / intercept-only deviance describes age and weather together. The last column compares that model with quadratic age alone; it is not a causal share of raw PAIC variance explained. The eight-hypothesis AICc comparison is calculated separately on 24 identical years, as shown in Figure 1.')
replace('Reproducibility:',
 'Reproducibility: analysis/17_weather_hypothesis_models.R and weather_hypothesis_ tables/model RDS document the 24-year selection comparison and year-omission checks. Analysis 14 and final_weather_ outputs supply the verified 26-year reporting summer associations and age curves. Correlation tables remain descriptive background. Figures use plot_style.R with 600 dpi PNG and vector PDF exports; earlier Word versions and the retired correlation figure are archived.')

# Keep the publication caption registry consistent without replacing other entries.
registry=root/'results/figure_descriptions/publication_captions.json'
captions=json.loads(registry.read_text(encoding='utf-8')) if registry.exists() else {}
captions['weather_hypothesis_comparison']=caption
registry.write_text(json.dumps(captions,ensure_ascii=False,indent=2),encoding='utf-8')
d.save(path)
print(f'Updated {path}; preserved the prior Word file and retained other publication captions.')
