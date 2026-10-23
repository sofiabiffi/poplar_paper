# Scenario workbook: planned next module

The interactive Excel workbook will be designed after agreeing the scenario logic. No land area, adoption trajectory, SOC sequestration rate or projection period has been assumed in this setup.

Available inputs are the annual PAIC/MAIC and stock summaries in `data/processed/annual_hybrid.csv`, their treatment-specific counterparts, and the complete-profile SOC summaries. These can support distinct PAIC-based and MAIC-based estimates without equating MAIC with an instantaneous annual growth rate.

Agree together:

1. Target geography, eligible land categories and area source/year.
2. Tree-row/whole-system area convention, eligible fraction and adoption schedule.
3. Projection horizon and stand-age/cohort treatment.
4. Which measured hybrid/treatment rates enter each PAIC and MAIC scenario.
5. Whether and how SOC stock differences become sequestration rates, with a justified timescale and spatial weighting.
6. Carbon-to-CO2 conversion, uncertainty and what colleagues may edit.

The original scenario sheets remain in `data/raw/soil_and_legacy_scenarios.xlsx` as historical context. They are not used by preparation. The future Excel deliverable should use transparent formulas and editable inputs, and will not require R to explore scenarios.

