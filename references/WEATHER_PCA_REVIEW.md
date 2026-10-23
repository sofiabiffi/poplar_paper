# OPEN: revisit before final weather results and manuscript claims

Requested by user, 20 October 2026. Keep this issue visible when results are more finalised.

PCA maximises variation in weather predictors, not association with PAIC. A low-variance PC can be relevant to PAIC, and a high-variance PC can be irrelevant. The exploratory >=80% weather-variance rule is a continuity choice, not a validated model-selection rule. Do not interpret a discarded PC or season as having no growth association.

Useful reading:
- Rick Wicklin (2017), [Should you use principal component regression?](https://blogs.sas.com/content/iml/2017/10/25/principal-component-regression-drawbacks.html). Discusses this caveat and alternatives. Do not automatically adopt significance-based component selection or PLS without validation.
- [scikit-learn: Principal Component Regression vs Partial Least Squares Regression](https://scikit-learn.org/stable/auto_examples/cross_decomposition/plot_pcr_vs_pls.html): worked illustration of a predictive low-variance direction.

Before finalising:
- Revisit PC retention using a validation design suitable for the small temporal dataset. Estimate scaling and PCA within each training fold; select/tune within training data, with separate outer evaluation if reporting tuned predictive performance. Keep hybrids from the same year together.
- Consider whether regularised regression or a supervised dimension reduction method is a useful sensitivity analysis, preserving an appropriate positive-response model.
- Check loading/subspace stability across years, especially near-tied axes. Ordinary model intervals condition on estimated PCA and do not include PCA or selection uncertainty.
- Review duplicated/redundant metrics (notably temperature and growing degree days), seasonal weighting, coverage, and potential shared trends with age/time.
- User confirmed retaining t - 1 weather for multi-year PAIC intervals: PAIC is annualised, but within-interval growth timing is unknown. Explain in Methods/Discussion. Resolve response-source discrepancies before inference.
- Compare seasonal and combined models only on identical response years. Do not select summer or another season solely from in-sample fit or individual unadjusted p-values.

Current exploration: analysis/06_combined_seasonal_weather.R combines four seasons only, omitting overlapping annual/half-year summaries. It preserves all varying metrics in the first draft and exports a redundancy audit. Results and figures are exploratory; final validation is pending.
