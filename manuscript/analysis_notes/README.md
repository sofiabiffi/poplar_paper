# Analysis notes for paper drafting

## Current weather note updated 21 October 2026

02_weather_and_PAIC.docx contains only the current original-PAIC analysis with hybrid-specific quadratic age, summer rainfall and temperature. It explains variable selection and stand-development adjustment, presents the final absolute dot-and-whisker figure, and includes fixed-weather quadratic age shapes as Figure S1. Whiskers describe uncertainty in mean associations, not annual variation in sensitivity. No preliminary detrending or response standardisation is required. Weather remains aligned to the preceding growth year, including annualised multi-year intervals.

The active figure stems are final_weather_raw_screen, final_weather_hybrid_effects and final_weather_quadratic_age_shapes. Superseded weather figures are in archive/weather_figures_before_quadratic_final_2026-10-21. Growth, treatment and soil figures and the separately saved Trichobel comparison remain in results/figures. Earlier Word versions, including manual edits, are preserved in _history.

Use analysis/14_raw_paic_weather_final.R and its companion diagnostics, then scripts/build_final_weather_note.py. Do not overwrite the current weather account using the original all-notes builder below. Export with Word and run scripts/render_analysis_notes.py; visually inspect the changed pages. QA files are internal. Other Word notes are unchanged.

## Original notes and general maintenance

Updated 20 October 2026. The five Word files cover tree growth, weather relationships with PAIC, cropping treatments and legacy, soil carbon stocks, and scenario planning. Each separates methods, calculated results, interpretation and outstanding decisions, with source pointers to the project files. Scenario planning has no new calculated results.

The notes explicitly explain that the 2001 PAIC is an annualised average over growth years 1998-2000. Missing visits reduce temporal resolution; they do not themselves cause low PAIC. The weather explanation has not yet been tested with predictors aligned to that entire interval.

These documents are reference notes to develop alongside the analyses. They are not refreshed automatically when R outputs change. Update the relevant Word note after a substantive analysis change, including its numerical values, interpretation and date. The script scripts/build_analysis_notes.py recreates the initial notes from project tables and recorded decisions; preserve manual Word revisions before rerunning it. QA renders are kept in _qa and are not manuscript deliverables.

Documents

- 01_tree_growth.docx
- 02_weather_and_PAIC.docx
- 03_cropping_treatment_and_legacy.docx
- 04_soil_carbon_stocks.docx
- 05_carbon_scenario_planning.docx

Treatment note update on 22 October 2026: the current expanded version is 03_cropping_treatment_and_legacy_updated_20261022.docx. It adds the pseudo-R model, the explicit block tests and design-based rationale for retaining block, and the active cropping figure. The earlier file could not be overwritten because it was locked; it remains unchanged. A backup was preserved in the QA folder. Use the expanded version for further edits.
