# UK trees on farmland scenarios

Current specification, 26 October 2026: no additional SOC on permanent grassland; the croppable case is plotted and the cropped alternative is tabulated. One four-panel figure replaces the earlier separate figures. Previous runs and scripts are preserved under `_history`.

## Outputs

- `figures/uk_scenarios_summary.png` and `.pdf`: top panels compare AGB and combined additional stocks for the two planting schedules; bottom panels compare AGB PAIC and MAIC. Only 2056 has point markers. The PNG is 600 dpi and the PDF is vector.
- `outputs/uk_trees_on_farmland_2027_2056.xlsx`: editable inputs, current results for both land denominators, annual calculations, cohort factors and source information. The embedded chart uses croppable results only.
- `tables/uk_scenario_milestones.csv`: 2050 and 2056 for permanent grassland, the selected cropland category, and UK totals. Cropped and croppable are alternatives.
- `tables/uk_scenario_annual_results.csv`: annual stocks and changes, with AGB-only MAIC in `MAIC_AGB_CO2_Mt`. Do not interpret MAIC as calendar-year removal.
- `tables/uk_scenario_figure_data.csv`: the 240 records used in the four-panel figure, including exactly eight endpoint markers at 2056 (four series across two schedules).
- `tables/uk_scenario_cohorts.csv`: cohort ages, area, tree counts and component stocks. Grassland SOC is identically zero.
- The Word report is `manuscript/analysis_notes/05_carbon_scenario_planning.docx` in the paper project, with its previous versions preserved in `_history`.

## Methods

The programme covers 1 January 2027 to 1 January 2057, represented by 30 full growing years ending in 2027-2056. Trees are planted at the beginning of the year. End of 2050 includes 24 growing periods. Either all target land is planted in 2027 or 1/24 is planted each year in 2027-2050, followed by no further expansion.


Use 14% of 5.985 million ha permanent grassland (837,900 ha) plus 7% of either 6.1 million ha croppable (427,000 ha) or 4.1 million ha cropped (287,000 ha). These are whole-system hectares containing trees and alleys, not tree-strip hectares. Temporary grass in the croppable category is separate from permanent grassland, so the two categories do not overlap.

Defra 2025 Table 2.1 reports 6.125 million ha croppable: 4.089 million ha arable crops, 0.147 million ha horticulture, 0.576 million ha uncropped arable and 1.313 million ha temporary grass under five years. Retain the user's rounded 6.1 million ha denominator. The 4.1 million ha alternative approximates arable crops rather than all crops including horticulture.

Cropland uses 2m strips with 30m between row centres and 7m between trees: 47.619 trees/ha and 2/30 strip fraction. Grassland uses 166 trees/ha, 2m strips and 10m row centres: 20% strips and approximately 6m within rows. Growth per tree is held constant when transferring density.

Use arithmetic mean Trichobel stocks from 45 trees across their original cropping histories. Divide original Mg C/ha by 0.50 and 166, then multiply by 1000, to recover dry kg/tree. Linearly interpolate stock gaps. Age zero is assumed zero. Recorded ages 1-30 (1993-2022) supply the projection; age31 (2023) remains in source tables but is not needed for the horizon. Annual calendar fluctuations represent an observed age-profile analogue, not a future weather prediction.

AGB C fraction is 0.4884. BGB dry mass = 0.26 x AGB dry mass, with BGB C fraction 0.4690. Thus BGB C / AGB C = 0.2496724. PAIC is annual AGB stock difference; cohort MAIC is AGB stock / cohort age, summed nationally. PAIC and MAIC comparisons apply to AGB only. Do not sum MAIC over calendar years to reconstruct stocks.

Only cropland tree strips receive additional SOC, at 0.6510129934894138 Mg C per strip ha/year (32-year annualised ESM excess). This is 0.043400866 Mg C per whole-system cropland ha/year. All permanent grassland tree strips and all alleys receive zero SOC credit. The rate assumes a trajectory, rather than an observed annual change, and its uniform application to the heterogeneous croppable category remains a simplification.

Combined additional stock = AGB C + BGB C + cropland tree-strip SOC excess. Pre-existing SOC is excluded. Use exact C-to-CO2 factor 44/12. Living tree stocks remain standing: harvesting and mortality are discussed, not modelled. No net GHG balance or national net-zero date is estimated. Trichobel is an exemplar, not a national monoculture recommendation.

## Sources

- Thillainathan I (2021), *Role of agroforestry and hedges in UK climate targets*, CCC, supplied PDF slide 7. Its 2.3 Mt CO2e/year estimate for 2050 uses different assumptions and is not a direct benchmark.
- Defra *Agriculture in the United Kingdom 2025*, Table 2.1: https://www.gov.uk/government/statistics/agriculture-in-the-united-kingdom-2025/chapter-2-structure-of-industry.
- Schulz-Nielsen et al. (2026), https://doi.org/10.3390/f17030395. The C fractions are calculated unweighted summaries of Table 2; 0.26 is a separate generic allocation assumption, discussed in the belowground note.
- Burgess PJ and Graves A (2022), *The Potential Contribution of Agroforestry to Net Zero Objectives*, Cranfield University, 48pp: https://dspace.lib.cranfield.ac.uk/handle/1826/18664. Context for integrating carbon and baseline emissions; not reproduced as a net balance here.
- SFI AGF1 and AGF2, England only, checked 26 October 2026: https://www.gov.uk/find-funding-for-land-or-farms/agf1-maintain-very-low-density-in-field-agroforestry-on-less-sensitive-land and https://www.gov.uk/find-funding-for-land-or-farms/agf2-maintain-low-density-in-field-agroforestry-on-less-sensitive-land. Bands 30-50 and 51-130 trees/ha pay GBP248 and GBP385/ha/year respectively. These are policy context, not modelled revenues or a full eligibility assessment.

## Reproduction

Run `scripts/calculate_uk_scenarios.py`, `scripts/plot_uk_scenarios.R`, `scripts/build_uk_workbook.mjs` and `scripts/build_uk_note.py` using the specified local runtimes. The old companion MAIC scripts are archived because MAIC is now part of the main AGB calculation. Scripts and workbook caches agree at all eight UK milestones; checks include zero grassland SOC, planting targets, age coverage, stock reconciliation and AGB MAIC. Word documents require rendering and visual review after regeneration.

Workbook edits update workbook calculations and its chart. Static CSVs, the publication figure and the note describe the saved parameter run; change the script assumptions consistently and rerun to refresh them. No arbitrary growth-reduction factors or unvalidated uncertainty intervals are introduced.

Figure presentation update: the stock row is panel A and AGB accumulation row is panel B. Each panel has a separate legend. A uses blue circles and green squares; B uses orange triangles and purple diamonds. Both x-axis labels are 'year'. Only the 2056 endpoints have point markers. Calculated results are unchanged.


Draft method schematic added 27 October 2026: figures/uk_scenarios_method_schematic.png and .pdf. Run scripts/plot_uk_schematic.R before the note builder to include it as Figure 2. The schematic traces land and growth inputs into planting cohorts, separate carbon pools and stock versus AGB-growth outputs. It changes no calculated results.


Schematic wording revised 27 October: both croppable and cropped land targets are shown. Tree diameters yield individual dry biomass, averaged across trees at each visit; mean biomass is interpolated linearly between measured ages. The historical 0.50 carbon fraction is omitted from the schematic and explained only as reversal of the old conversion in the methods. Scenario carbon fractions and numerical results are unchanged.


Editable method schematic: outputs/uk_upscaling_method_editable.pptx. Native PowerPoint boxes, text and arrows; wording updated to 'Same growth assumed across planting layouts'. Source: scripts/build_schematic_pptx.mjs and schematic.json. The PNG/PDF and Word note use the same wording. Previous versions were preserved in history folders.

## Internal calculation clarification and cohort audit, 27 October 2026

The reversal of the historical 0.50 carbon fraction and 166 trees/ha is data-preparation bookkeeping. Retain it in calculation documentation and code for reproducibility, but omit it from proposed paper methods. Paper wording should describe diameter-derived mean dry aboveground biomass per tree, linear interpolation between observed ages, and application of the selected carbon fractions.

Independent recomputation of the three carbon components agrees with all eight UK milestone results (two land definitions x two schedules x two milestone years; relative tolerance 1e-12). No scenario values were changed. Constant planting is 24 equal cohorts, planted at the start of each year in 2027-2050. At end-2056 their ages are 7-30, compared with age 30 for all-2027 planting. Mean dry AGB across ages 7-30 is 419.799947 kg/tree; age-30 dry AGB is 764.396422 kg/tree. The AGB ratio is 0.549191408. The SOC ratio is 18.5/30 = 0.616666667 because soil accumulation is linear in cohort age. For grassland plus croppable land, end-2056 AGB/BGB/SOC stocks expressed as Mt CO2 are 218.233506/54.486883/2.059467 for all-2027 and 119.851967/29.923728/1.270005 for constant planting. Combined stocks are 274.779857 and 151.045700 Mt CO2, respectively. These are accumulated stocks expressed as CO2, not annual removals.

Word schematic revised: AGB now branches directly to cohort PAIC/MAIC calculations before their summation, separately from aggregation of carbon stocks. Only the Word draft and its PNG/PDF schematic and R source were updated. The editable PowerPoint and its JSON/CSV inputs retain the previous layout at the user's request. Scenario calculations are unchanged.

Current figure presentation, 27 October 2026: Figure 1 uses all-solid curves, separate legends for A and B, blue circles / green squares for stocks and vermillion triangles / purple diamonds for AGB growth. Endpoint symbols at 2056 are enlarged from 2.3 to 3.3 mm. The dotted 2050 reference is retained. Calculation data and all age/duration conventions are unchanged.

The authoritative method scheme is outputs/uk_upscaling_method_SB.pptx. Its first slide is reproduced without editing in the current Word note and figures/uk_scenarios_method_schematic.png and .pdf. Re-export it using scripts/export_sb_schematic.ps1. The earlier plot_uk_schematic.R, build_schematic_pptx.mjs and editable PowerPoint are legacy drafts and should not overwrite the SB scheme. Figure 1 remains reproducible with scripts/plot_uk_scenarios.R. Previous figures and Word notes were preserved before replacement.

Recovery note, 27 October 2026: the latest scheme embedded in Word differs from the older SB PowerPoint saved on disk. The Word image was extracted unchanged to outputs/uk_upscaling_method_SB_exact_Word_figure.png. An editable reconstruction of that later diagram is saved separately as outputs/uk_upscaling_method_SB_recovered.pptx, checked with a native PowerPoint render. It is a reconstruction, not recovery of the original unsaved binary. The earlier SB file is retained unchanged. The current Word figure remains the exact original image. The vector PDF exported from the saved SB file is an older layout and must not be treated as the latest reference. Do not re-export the older SB file over the current schematic image.


SOC baseline update, 27 October 2026: tree-row rate = (mean ESM tree-row stock - mean fixed-depth arable stock) / 32 years. Current input is 0.651012993 Mg C/ha/year, with descriptive profile SD 0.259344597. Scenarios use the mean only. SD is not a confidence interval and no bootstrap or scenario uncertainty bounds are reported. Re-run refresh_uk_workbook_SOC.mjs after the workbook builder to refresh rate calibration.

Current parameter run, 27 October 2026: use exact Defra 2025 baselines of 6,125,000 ha croppable and 4,089,000 ha arable cropped land, replacing 6,100,000 and 4,100,000. Targets are 428,750 and 286,230 system ha; annual planting over 24 years is 17,864.583333 and 11,926.25 ha. Permanent grassland remains 5,985,000 ha, with an 837,900 ha target and 34,912.5 ha/year. All other configuration values, observed growth and age conventions are unchanged. The existing SOC calibration of 0.6510129934894138 Mg C per tree-strip ha/year is retained, using the previously updated fixed-depth arable baseline. Only the two land baseline parameters changed in this rerun.

The cohort calculations, tables, Figure 1, workbook and corresponding Word note are refreshed. Workbook values agree at all eight UK milestones. Independent proportional-scaling checks passed for 1,200 component comparisons, with unchanged grassland results. New incremental refresh scripts preserve existing workbook/note content: scripts/refresh_land_workbook.mjs and scripts/refresh_land_note.py. The user-authored PowerPoint files and embedded schematic image are unchanged. The scheme's rounded land labels are superseded by the exact areas in current methods and tables; the Word caption flags this. Earlier runs and documents were preserved in history folders.
