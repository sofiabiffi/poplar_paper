# 2023 growth model diagnostic review

Reviewed all three block-level models and all three row-level sensitivity fits using residual versus fitted, normal Q-Q, scale-location and residual plots, residual spread by hybrid, standardised residuals, Cook distances and leverage. Reproduce with scripts/check_growth_2023_models.R.

Primary models have 12 block-hybrid observations and six residual degrees of freedom. Shapiro-Wilk p-values: PAIC 0.911, MAIC 0.427, stock 0.211. These do not establish normality; residuals are constrained by fitting the model and diagnostic power is limited.

MAIC and stock show no obvious major residual-distribution or variance problems. PAIC shows unequal residual spread by hybrid (residual SD 0.034 for Robusta versus 0.264 for Trichobel), also apparent in row-level sensitivity plots. Its largest standardised residual is 2.05 and largest Cook distance is 0.699. Constant variance is questionable; retain the existing coefficients and comparisons as provisional pending sensitivity analysis that addresses heteroscedasticity. The existing row-level sensitivity also assumes constant variance and does not resolve this concern.

Independence follows the assumed field replication, not a residual normality test. Averaging subsamples avoids treating trees as independent replicates but does not prove block independence. Block-by-hybrid interaction cannot be separately estimated with one block-hybrid summary per cell; it contributes to residual variation. No observations were removed and no model estimates or p-values were changed by this audit.
