# Setup validation, 20 October 2026

- Master preparation completed in clean `Rscript --vanilla` sessions, sourced both from the workspace parent and from the paper project directory.
- 22 prepared tables exported and reloaded from the combined RDS without changes.
- 31 data-integrity checks passed; see `validation.csv` and `scripts/check_preparation.R`.
- All 60 weather predictors in the new wide table agree numerically with the existing biologically aligned weather output, including missingness. The previous-year assignment is unchanged for multi-year growth increments.
- Five copied source files (four workbooks and thesis PDF) verified against recorded SHA-256 hashes. Original workspace files were also checked and unchanged.
- Lockfile records 72 packages; all 65 project-local copied package versions occur in the lockfile. R-recommended dependencies come with the R installation.
- All four starter analysis modules executed successfully. The 24 baseline PCA/PAIC Gamma fits converged. This verifies execution, not final model adequacy or paper inference.
- Descriptive PAIC/MAIC and SOC figures were generated and visually reviewed.

The three-year intervals, incomplete soil profiles, partial daily weather coverage and response/allometry differences remain explicit in the data and audits. They have not been hidden by setup.

The supplied environment emits warnings that lmerTest, emmeans and broom.mixed were built with R 4.6.1 while this installed R is 4.6.0. Loading and the tested workflows succeeded. Fresh package installation/restore on another machine or operating system has not been tested. Windows sandbox permission checks prevented R from enumerating packages correctly during the initial snapshot; the final snapshot was generated outside that sandbox and checked against the local package manifest.

No final treatment model, temporal growth model, statistical interpretation, or scenario projection has been agreed by these checks. The scenario Excel workbook remains the planned next module after assumptions are selected.
