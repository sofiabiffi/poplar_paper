# Presentation and multiplicity for interval-specific treatment contrasts.
# Source after library.R. Reusable with saved models; no refitting is needed.
present_treatment_phase <- function(by_interval, label) {
  contrasts <- emmeans::contrast(by_interval, list(
    "C - F" = c(-1, 1, 0), "A - F" = c(-1, 0, 1), "C - A" = c(0, 1, -1)))
  inference <- as.data.frame(summary(contrasts, infer = c(TRUE, TRUE), adjust = "none"))
  names(inference)[names(inference) == "p.value"] <- "p_unadjusted"
  inference$p_holm_phase <- stats::p.adjust(inference$p_unadjusted, method = "holm")
  inference$n_tests_in_family <- nrow(inference)
  inference$significant_holm <- inference$p_holm_phase < 0.05
  inference$measurement_year <- as.integer(sub(".*-", "", as.character(inference$interval)))
  inference$growth_year <- inference$measurement_year - 1L
  inference$family <- paste(label, ": all three treatment pairs across all observed intervals")
  inference$CI_basis <- "Pointwise 95%; significance markers use phase-wide Holm p-values"
  utils::write.csv(publication_table(inference),
    project_path("results", "tables", paste0("treatment_PAIC_", label, "_interval_inference.csv")), row.names = FALSE)
  means <- as.data.frame(confint(by_interval))
  means$measurement_year <- as.integer(sub(".*-", "", as.character(means$interval)))
  means$treatment <- publication_labels(means$treatment_code)
  phase_title <- c(active = "Active cropping", post = "After cropping ceased",
    active_with_boundary = "Active cropping including boundary interval")[[label]]
  year_scale <- function() ggplot2::scale_x_continuous(breaks = function(limits)
    seq(ceiling(limits[1] / 2) * 2, floor(limits[2] / 2) * 2, by = 2))
  # Only the two comparisons involving continuous cropping appear in plots;
  # all three pairs remain in the adjustment family, including alternate vs fallow.
  focus <- inference[inference$contrast %in% c("C - F", "C - A"), ]
  focus$contrast <- if (label == "post") {
    ifelse(focus$contrast == "C - F",
      "Former continuous cropping - former continuous fallow",
      "Former continuous cropping - former alternate cropping")
  } else {
    ifelse(focus$contrast == "C - F",
      "Continuous cropping - continuous fallow",
      "Continuous cropping - alternate cropping")
  }
  focus$marker <- ifelse(focus$significant_holm, "*", "")
  offset <- 0.06 * diff(range(c(focus$lower.CL, focus$upper.CL)))
  p <- ggplot2::ggplot(focus, ggplot2::aes(measurement_year, estimate,
    colour = contrast, shape = contrast, linetype = contrast, group = contrast)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.4) +
    ggplot2::geom_line(linewidth = 0.6) + ggplot2::geom_point(size = 2.3) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lower.CL, ymax = upper.CL),
      width = 0.12, linewidth = 0.4, linetype = "solid") +
    ggplot2::geom_text(ggplot2::aes(y = upper.CL + offset, label = marker),
      size = 4, show.legend = FALSE) +
    publication_scales(unique(focus$contrast), "Treatment comparison") +
    theme_publication() + year_scale() +
    ggplot2::guides(colour = ggplot2::guide_legend(ncol = 1),
      shape = ggplot2::guide_legend(ncol = 1), linetype = ggplot2::guide_legend(ncol = 1)) +
    ggplot2::labs(x = "Measurement year (preceding growth interval)",
      y = expression("PAIC difference (Mg C ha"^{-1}*" yr"^{-1}*")"), title = phase_title,
      caption = paste0("Equal hybrid weights; pointwise 95% CIs. * Holm-adjusted p < 0.05 across all ",
        nrow(inference), " pair-by-interval tests in this phase.\nA CI excluding zero alone does not establish significance after adjustment."))
  save_publication_plot(p,
    project_path("results", "figures", paste0("treatment_PAIC_", label, "_contrasts")), height = 5.6)
  markers <- do.call(rbind, lapply(split(inference, inference$measurement_year), function(z) {
    cf <- z$significant_holm[z$contrast == "C - F"]
    ca <- z$significant_holm[z$contrast == "C - A"]
    data.frame(measurement_year = z$measurement_year[1],
      marker = paste0(if (isTRUE(cf)) "*" else "", if (isTRUE(ca)) "+" else ""))
  }))
  tops <- aggregate(upper.CL ~ measurement_year, means, max)
  markers <- merge(markers, tops, by = "measurement_year")
  markers$y <- markers$upper.CL + 0.08 * diff(range(c(means$lower.CL, means$upper.CL)))
  treatment_groups <- unname(publication_treatments)
  if (label == "post") {
    means$treatment <- paste("Former", tolower(means$treatment))
    treatment_groups <- paste("Former", tolower(treatment_groups))
  }
  mean_plot <- ggplot2::ggplot(means, ggplot2::aes(measurement_year, emmean,
    colour = treatment, shape = treatment, linetype = treatment, group = treatment)) +
    ggplot2::geom_line(linewidth = 0.65) + ggplot2::geom_point(size = 2.3) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lower.CL, ymax = upper.CL),
      width = 0.12, linewidth = 0.4, linetype = "solid") +
    ggplot2::geom_text(data = markers, ggplot2::aes(measurement_year, y, label = marker),
      inherit.aes = FALSE, colour = "black", size = 4.2) +
    publication_scales(treatment_groups, "Cropping treatment") + theme_publication() + year_scale() +
    ggplot2::guides(colour = ggplot2::guide_legend(ncol = 1),
      shape = ggplot2::guide_legend(ncol = 1), linetype = ggplot2::guide_legend(ncol = 1)) +
    ggplot2::labs(x = "Measurement year (preceding growth interval)",
      y = expression("PAIC (Mg C ha"^{-1}*" yr"^{-1}*")"), title = phase_title,
      caption = paste0("Model-adjusted means across hybrids; pointwise 95% CIs. Continuous cropping differs from:\n* continuous fallow; + alternate cropping (Holm p < 0.05 across all ",
        nrow(inference), " pair-by-interval tests in this phase)."))
  save_publication_plot(mean_plot,
    project_path("results", "figures", paste0("treatment_PAIC_", label, "_means")), height = 5.6)
  list(contrasts = inference, means = means, markers = markers)
}

