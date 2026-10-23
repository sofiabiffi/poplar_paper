# Run source("prepare_data.R") first. No trend model is imposed here.
if (!exists("paper_data")) stop("First source prepare_data.R")
utils::write.csv(annual_hybrid, project_path("results", "tables", "growth_by_year_hybrid.csv"), row.names = FALSE)
utils::write.csv(growth_descriptive, project_path("results", "tables", "growth_descriptive.csv"), row.names = FALSE)
growth_plot_data <- annual_hybrid |>
  dplyr::filter(metric %in% c("PAIC", "MAIC"), n_valid > 0) |>
  dplyr::mutate(metric = factor(metric, levels = c("PAIC", "MAIC")))
growth_trends_plot <- ggplot2::ggplot(growth_plot_data,
  ggplot2::aes(measurement_year, median, colour = hybrid, fill = hybrid, shape = hybrid, linetype = hybrid)) +
  ggplot2::geom_ribbon(ggplot2::aes(ymin = q25, ymax = q75), alpha = .12, colour = NA) +
  ggplot2::geom_line(linewidth = .6) + ggplot2::geom_point(size = 1.8) +
  ggplot2::facet_wrap(~metric, ncol = 1, scales = "free_y") +
  ggplot2::labs(x = "Measurement year", y = expression("Carbon increment (Mg C ha"^{-1}*" yr"^{-1}*")"),
    colour = "Hybrid", fill = "Hybrid", shape = "Hybrid", linetype = "Hybrid",
    caption = "Medians and interquartile ranges across trees.\nLines connect observed visits; missing years are not imputed.") +
  publication_scales(unname(publication_hybrids), "Hybrid", include_fill = TRUE) + theme_publication()
save_publication_plot(growth_trends_plot,
  project_path("results", "figures", "paic_maic_descriptive"), width = 7.2, height = 6.8)

