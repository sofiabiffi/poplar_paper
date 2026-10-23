# Initial PAIC treatment results

Run: 20 October 2026. Source: analysis/03_treatment_active.R.

All three models converged without singular fits. Preparation checks (31) and treatment checks passed. All available measured trees contribute to row-by-hybrid means; three blocks supply treatment replication. Block is retained regardless of significance (active p=0.511; post p=0.650).

Differences below are Mg C/ha/year, averaged equally across hybrids and observed intervals. Confidence intervals and p-values are Bonferroni-adjusted for the three overall contrasts.

| Period | Contrast | Difference | 95% CI | Adjusted p |
|---|---|---:|---|---:|
| Active | Continuous cropping minus continuous fallow | -0.473 | -0.743 to -0.203 | 0.0068 |
| Active | Alternate cropping minus continuous fallow | -0.190 | -0.460 to 0.080 | 0.1475 |
| Active | Continuous cropping minus alternate cropping | -0.283 | -0.552 to -0.013 | 0.0428 |
| Post | Continuous cropping minus continuous fallow | 0.310 | -0.079 to 0.698 | 0.1026 |
| Post | Alternate cropping minus continuous fallow | 0.127 | -0.261 to 0.516 | 0.7920 |
| Post | Continuous cropping minus alternate cropping | 0.183 | -0.206 to 0.571 | 0.4084 |

The active treatment omnibus test gives p=0.0057, with treatment-by-interval p<0.001. Thus the average contrasts do not imply a constant difference throughout cultivation. The post treatment omnibus test gives p=0.0806. Neither nonsignificance nor a change in sign establishes disappearance of a legacy.

Boundary sensitivity: including the 2002-2005 increment with active cropping gives Continuous cropping minus continuous fallow=-0.445 (adjusted p=0.0075), Alternate cropping minus continuous fallow=-0.185 (p=0.1462), Continuous cropping minus alternate cropping=-0.260 (p=0.0506). The Continuous cropping minus continuous fallow conclusion is consistent across these choices; Continuous cropping minus alternate cropping is sensitive near the conventional significance threshold.

Read treatment_PAIC_post_interval_contrasts.csv and the corresponding plot for the legacy trajectory averaged across hybrids. These intervals are adjusted for the three comparisons within each interval, not across the full time series. No formal duration or equivalence claim is made.

Residual plots show some unequal spread and tail departures, particularly after cropping. These common-variance Gaussian models are an initial analysis; residual variance and remaining serial dependence should be assessed further before treating the reported p-values as final. Nonpositive PAIC observations were retained. Model summaries, variance components, residual records, and counts are exported for review.

Rerun from the project directory:

```r
source("prepare_data.R")
source("analysis/03_treatment_active.R")
source("scripts/check_treatment.R")
```

Presentation update: the main treatment figures now average across hybrids and use full treatment names, accessible colours, symbols, and line types. Both 600 dpi PNG and vector PDF are exported. The treatment-by-hybrid interaction is nonsignificant in the active (p=0.613) and post (p=0.570) models. Hybrid main effects are significant in both (p<0.001); therefore the appropriate statement concerns lack of clear evidence for different treatment responses among hybrids, not absence of hybrid differences in PAIC.

## Phase-wide interval inference update

Use the new interval_inference tables for time-specific significance. Holm correction spans all three treatment pairs and all intervals in each phase, while figures focus on the two contrasts involving continuous cropping. The reference treatments remain separate; nonsignificance does not establish equality. The previous within-interval results above are retained for transparency, but do not control error across the searched time series.

In the post-cropping model, continuous cropping exceeds continuous fallow in growth years 2008 and 2009 after phase-wide adjustment (p=0.00242 and 0.0380). Other years, including growth year 2013, do not meet this criterion. The 2007-2010 pattern may be discussed as suggestive of release from crop competition, but it is not significant in every year and does not establish the mechanism. No observations or intervals have been discarded.
