# Run after analysis/03_treatment_active.R, or with project packages loaded
# and treatment_paic_results read from results/models/treatment_PAIC_models.rds.
stopifnot(exists("treatment_paic_results"))
for (nm in names(treatment_paic_results)) {
  x <- treatment_paic_results[[nm]]
  stopifnot(nlevels(x$data$row_id) == 9L,
            nlevels(x$data$block) == 3L,
            all(x$data$n_trees >= 1L & x$data$n_trees <= 5L),
            !anyDuplicated(x$data[c("row_id", "hybrid_code", "interval")]),
            all(is.finite(x$data$PAIC)),
            nrow(x$overall) == 3L,
            all(is.finite(x$overall$estimate)),
            all(x$overall$lower.CL <= x$overall$estimate),
            all(x$overall$upper.CL >= x$overall$estimate),
            is.null(x$convergence), !x$singular)
}
a <- treatment_paic_results$active$data
p <- treatment_paic_results$post$data
s <- treatment_paic_results$active_with_boundary$data
stopifnot(all(a$analysis_phase == "Active"),
          all(a$measurement_year <= 2002L),
          all(p$analysis_phase == "Post"),
          all(p$interval_start_growth_year >= 2005L),
          !any(a$interval %in% p$interval),
          any(s$interval == "2002-2005"),
          all(s$analysis_phase %in% c("Active", "Boundary")))
message("Treatment checks passed: phase separation, nine treatment rows, subsample counts, finite contrasts and model convergence.")

# Pooled figures must have exactly three contrasts per interval, not facets
# interpreted as separate treatment replicates.
for (x in treatment_paic_results) {
  stopifnot(!"hybrid_code" %in% names(x$interval),
            all(table(x$interval$interval) == 3L),
            "hybrid_code" %in% names(x$hybrid_interval))
}
message("Pooled treatment presentation checks passed.")

for (x in treatment_paic_results) {
  d <- x$interval_inference
  stopifnot(nrow(d) == 3L * nlevels(x$data$interval),
    isTRUE(all.equal(d$p_holm_phase, p.adjust(d$p_unadjusted, "holm"))),
    all(d$p_holm_phase >= d$p_unadjusted - 1e-12),
    all(d$significant_holm == (d$p_holm_phase < 0.05)),
    all(d$lower.CL <= d$estimate & d$upper.CL >= d$estimate))
}
message("Phase-wide multiplicity checks passed.")
