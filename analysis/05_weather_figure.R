# Run from the workspace root with Rscript --vanilla.
.libPaths(c('poplar_paper/renv/library', .libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
read <- function(path) read.csv(file.path(root, path))
loads <- subset(read('data/processed/weather_pca_loadings.csv'), weather_period == 'summer' & retained)
variance <- subset(read('data/processed/weather_pca_variance.csv'), weather_period == 'summer' & retained)
scores <- subset(read('data/processed/weather_pc_scores.csv'), weather_period == 'summer')
coefs <- subset(read('results/tables/baseline_weather_model_coefficients.csv'), weather_period == 'summer' & term != '(Intercept)')
diag <- subset(read('results/checks/baseline_weather_model_diagnostics.csv'), weather_period == 'summer')
summary <- subset(read('results/tables/baseline_weather_model_summary.csv'), weather_period == 'summer')
pcs <- paste0('PC', 1:4)
pc_labels <- setNames(sprintf('%s\n%.1f%%', variance$PC, 100*variance$proportion_variance), variance$PC)
labels <- c('Air temperature','Soil temperature','Rainfall','Sunshine','Ground frost days','Growing degree days','Wind speed','Windy days')
loads$variable_label <- factor(loads$variable, levels = rev(unique(loads$variable)), labels = rev(labels))
loads$PC <- factor(loads$PC, levels = pcs)
a <- ggplot(loads, aes(PC, variable_label, fill = loading)) +
  geom_tile(colour = 'white', linewidth = .6) +
  geom_text(aes(label = sprintf('%.2f', loading)), size = 3) +
  scale_fill_gradient2(low = '#2166AC', mid = 'white', high = '#B35806', limits = c(-1,1), name = 'Loading') +
  scale_x_discrete(labels = pc_labels) + labs(title = 'A  Summer weather structure', x = NULL, y = NULL) +
  theme_publication(11) + theme(axis.line = element_blank(), axis.ticks = element_blank())
coefs$score_sd <- vapply(coefs$term, function(pc) sd(scores[[pc]]), numeric(1))
coefs$n <- summary$n[match(coefs$hybrid_code, summary$hybrid_code)]
coefs$critical <- qt(.975, coefs$n - 5)
coefs$effect <- 100*expm1(coefs$estimate*coefs$score_sd)
coefs$lower <- 100*expm1((coefs$estimate-coefs$critical*coefs$std.error)*coefs$score_sd)
coefs$upper <- 100*expm1((coefs$estimate+coefs$critical*coefs$std.error)*coefs$score_sd)
coefs$term <- factor(coefs$term, levels = rev(pcs))
pos <- position_dodge(width = .65)
b <- ggplot(coefs, aes(effect, term, colour = hybrid_code, shape = hybrid_code, group = hybrid_code)) +
  geom_vline(xintercept = 0, colour = 'grey65', linetype = 2) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = 'y', width = .15, position = pos) +
  geom_point(position = pos, size = 2.5) + publication_scales(c('B','G','R','T'), 'Hybrid')[1:2] +
  labs(title = 'B  Association with PAIC', x = 'Change in PAIC per 1 SD of PC (%)', y = NULL,
       subtitle = 'Estimates and 95% t-Wald confidence intervals') + theme_publication(11)
facet_labels <- setNames(sprintf('%s | deviance reduction %.0f%%', publication_labels(summary$hybrid_code),100*summary$deviance_reduction), summary$hybrid_code)
series <- rbind(transform(diag, value = PAIC, series = 'Observed'), transform(diag, value = fitted, series = 'Fitted'))
c <- ggplot(series, aes(measurement_year, value, linetype = series, shape = series)) +
  geom_line(linewidth = .5, colour = '#0072B2') + geom_point(size = 1.8, colour = '#0072B2') +
  facet_wrap(~hybrid_code, nrow = 1, labeller = as_labeller(facet_labels)) +
  scale_linetype_manual(values = c(Observed = 'solid', Fitted = 'dashed')) +
  scale_shape_manual(values = c(Observed = 16, Fitted = 1)) +
  labs(title = 'C  Observed and fitted growth', x = 'Measurement year',
       y = expression(PAIC~(Mg~C~ha^{-1}~yr^{-1})), linetype = NULL, shape = NULL) + theme_publication(10)
out <- file.path(root, 'results/figures')
dir.create(out, recursive = TRUE, showWarnings = FALSE)
draw <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(3,2,heights = grid::unit(c(5.4,3.4,.7),'null'))))
  print(a, vp = grid::viewport(layout.pos.row=1, layout.pos.col=1))
  print(b, vp = grid::viewport(layout.pos.row=1, layout.pos.col=2))
  print(c, vp = grid::viewport(layout.pos.row=2, layout.pos.col=1:2))
  grid::grid.text('BASELINE DRAFT | Summer PCs explain 81.1% of weather variance; n = 23 years per hybrid.\nGamma(log) models; in-sample fits. Weather from year t - 1; age/time adjustment pending.',
    x = .02, y = .5, just = 'left', gp = grid::gpar(fontsize=9),
    vp = grid::viewport(layout.pos.row=3, layout.pos.col=1:2))
}
stem <- file.path(out, 'weather_pca_model_summer_draft')
png(paste0(stem,'.png'), width=12, height=9.5, units='in', res=600); draw(); dev.off()
pdf(paste0(stem,'.pdf'), width=12, height=9.5, useDingbats=FALSE); draw(); dev.off()
png(paste0(stem,'_preview.png'), width=1560, height=1235, res=130); draw(); dev.off()
write.csv(coefs, file.path(root,'results/tables/weather_summer_standardised_effects.csv'), row.names=FALSE)
