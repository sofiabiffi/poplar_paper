# Poplar carbon paper

Self-contained preparation and analysis project for the paper combining chapters 2 and 3. Original inputs are copied into this folder, and every preparation step reads only project-local inputs. Existing files outside this project are unchanged.

## Start in VS Code

Open `poplar_paper.code-workspace` with **File > Open Workspace from File**. Start an R terminal in the paper folder, then run:

```r
source("prepare_data.R")
```

This loads all packages from `library.R`, sources configuration and all six preparation modules, builds the polished datasets and weather PCAs, saves CSV/RDS copies, and leaves the named datasets in your environment. It does not fit response models or generate manuscript figures automatically.

From another working directory:

```r
source("C:/Users/sofia/Documents/misc_Rstuff/poplar_paper/prepare_data.R")
```

The master locates its own folder without changing your working directory. It works in a fresh R session and does not require objects from a previous analysis.

## Main objects in your environment

| Object | Contents / use |
|---|---|
| `tree_growth` | Tree visits with hybrid, treatment, block, row, DBH, PAIC, MAIC, stocks, age, growth year, measurement intervals and audit columns. Primary carbon units: Mg C ha-1, increments per year. |
| `annual_hybrid` | Year/hybrid summaries of PAIC, MAIC and stocks: n, mean, median, SD, quartiles and range. |
| `annual_hybrid_treatment` | Same summaries split by treatment. |
| `growth_descriptive` | Descriptive summaries pooled over visits within hybrid. These are descriptive record summaries, not independent-observation inference. |
| `tree_treatment_active` | Tree observations in the provisional active-cropping measurement years 1993-2004, retaining block and row IDs. |
| `tree_phase_means` | Tree-specific phase means with sample counts, available for comparison with earlier workflows. |
| `weather_daily` | Clean daily measurements and derived GDD/frost/growing/windy metrics. |
| `weather_windows` / `weather_wide` | Six biological weather windows, in long and wide format. |
| `weather_coverage` | Valid-day counts and fractions for every weather metric/window. |
| `growth_weather` | One row per measurement year and hybrid, legacy PAIC/MAIC summaries joined to previous-year weather and gap flags. |
| `weather_pca` | Six named PCA objects with scores, loadings, scaling, variance and retained-PC names. Example: `weather_pca$summer$retained_pcs`. |
| `weather_pc_scores` | Observation years and retained scores for each weather period. Different PCAs have different axis meanings. |
| `growth_weather_pcs` | PAIC/MAIC by hybrid joined to retained PC scores, ready for response modelling. Select one period before modelling. |
| `soil_depth` | BD, SOC%, depth thickness and calculated depth-specific stocks, retaining all observations. |
| `soil_profiles` | All soil profiles, completeness flags, available-depth totals and strict complete 0-30 cm stocks. |
| `soil_profile_complete` / `soil_stock_summary` | Complete 0-30 cm profiles and location summaries for stock presentation. |
| `soil_depth_summary` | Depth-level summaries, including BD/SOC%, available for supplements. |
| `paper_data` | Named list of 22 main tables above; also saved as `data/processed/paper_data.rds`. |

Hybrid, treatment and soil location lookup tables are loaded too. `paper_config` holds all assumptions in `scripts/config.R`.

## Analyses

After preparing data, source the module you want:

```r
source("analysis/01_growth_descriptive.R")  # Descriptive trends/tables
source("analysis/02_weather_paic.R")       # Baseline PCA -> PAIC Gamma models
source("analysis/03_treatment_active.R")   # PAIC active/post models and contrasts
source("analysis/04_soc_stocks.R")         # Stock summaries/plot
```

These are starting modules for paper development. The treatment module fits initial PAIC active/post mixed models and a boundary-interval sensitivity analysis; see analysis/README.md for assumptions and outputs. The weather module does not rank periods fitted to different observation sets. Model and figure development can proceed separately from stable data preparation.

## Reproducibility

- Tested with R 4.6.0 on Windows. A copied project-local library is supplied for use on this machine, so normal preparation does not install packages or depend on the parent project's library.
- `renv.lock` records package versions. On another computer/OS, run `source("setup_environment.R")` once to restore into the project library, then prepare data. Restoration may need internet access and compilation tools; a fresh network restore has not been tested here.
- `library.R` is the single package-loading file. Add packages there and deliberately update the lockfile with `source("scripts/snapshot_environment.R")` after installing a new dependency.
- `references/source_manifest.csv` records source paths, sizes and SHA-256 hashes. `results/checks/session_info.txt` records the preparation environment.
- Raw Excel files and the thesis are preserved as supplied. Formula caches are read, not recalculated in Excel. Recomputed carbon fields are audits, and supplied response values remain primary until reviewed.
- `results/checks/` holds response and allometry audits, partial weather coverage, PCA exclusions and incomplete soil profiles.
- `results/checks/VALIDATION.md` records the setup checks and current runtime limitations. Re-run the integrity checks with `source("scripts/check_preparation.R")` after preparing data.

## Folder structure

```text
library.R                  all package loading
poplar_paper.code-workspace VS Code workspace rooted in this folder
prepare_data.R             one master data-preparation entry point
setup_environment.R        restore dependencies on another machine
scripts/config.R           assumptions and lookup tables
scripts/prep/              modular dataset preparation
analysis/                  independent paper analysis modules
data/raw/                  unchanged selected source workbooks
data/processed/            regenerated CSV and RDS data
results/checks/             preparation audits and validation
results/tables/             analysis tables
results/figures/            analysis figures
results/models/             saved response-model objects
references/                 thesis, provenance and decisions
scenarios/                  planned editable Excel scenario module
manuscript/                space for paper drafts
```

Read `references/DECISIONS.md` for the exact conventions and open questions. The scenario workbook is deliberately deferred until area, adoption and carbon-rate assumptions are agreed.


