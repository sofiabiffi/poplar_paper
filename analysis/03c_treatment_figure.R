# Combined treatment figure from existing model estimates; no refitting.
if (!exists("publication_scales")) stop("First source library.R with poplar.paper.root set.")
root <- getOption("poplar.paper.root")
out <- getOption("poplar.treatment.figure.output", file.path(root, "results", "figures"))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
read_phase <- function(phase, panel) {
  means <- read.csv(file.path(root,"results","tables",
    paste0("treatment_PAIC_",phase,"_interval_means.csv")))
  inference <- read.csv(file.path(root,"results","tables",
    paste0("treatment_PAIC_",phase,"_interval_inference.csv")))
  # Full treatment names are shared across panels; panel B denotes former treatment.
  means$treatment <- factor(publication_labels(means$treatment_code),
                           levels = unname(publication_treatments))
  means$year <- as.integer(sub(".*-", "", means$interval))
  means$panel <- panel
  markers <- do.call(rbind, lapply(split(inference, inference$measurement_year), function(z) {
    cf <- z$significant_holm[z$contrast_code == "C - F"]
    ca <- z$significant_holm[z$contrast_code == "C - A"]
    data.frame(year = z$measurement_year[1], panel = panel,
      marker = paste0(if(isTRUE(cf)) "*" else "", if(isTRUE(ca)) "+" else ""))
  }))
  tops <- aggregate(upper.CL ~ year, means, max)
  markers <- merge(markers,tops,by="year")
  markers$y <- markers$upper.CL + 0.08 * diff(range(c(means$lower.CL,means$upper.CL)))
  stopifnot(nrow(inference) == 3L * length(unique(means$interval)),
    all(inference$p_holm_phase >= inference$p_unadjusted - 1e-12))
  list(means=means,markers=markers)
}
a <- read_phase("active", "A")
b <- read_phase("post", "B")
means <- rbind(a$means,b$means)
markers <- rbind(a$markers,b$markers)
means$panel <- factor(means$panel,levels=c("A","B"))
markers$panel <- factor(markers$panel,levels=c("A","B"))
treatment_phase_figure <- ggplot2::ggplot(means,
  ggplot2::aes(year,emmean,colour=treatment,shape=treatment,linetype=treatment,group=treatment)) +
  ggplot2::geom_line(linewidth=0.6) +
  ggplot2::geom_point(size=2.1) +
  ggplot2::geom_errorbar(ggplot2::aes(ymin=lower.CL,ymax=upper.CL),
    width=0.1,linewidth=0.4,linetype="solid") +
  ggplot2::geom_text(data=markers,ggplot2::aes(year,y,label=marker),
    inherit.aes=FALSE,colour="black",size=4) +
  ggplot2::facet_wrap(~panel,ncol=1,scales="free_x") +
  publication_scales(unname(publication_treatments), NULL) +
  ggplot2::scale_x_continuous(breaks=function(limits)
    seq(ceiling(limits[1]/2)*2,floor(limits[2]/2)*2,by=2)) +
  ggplot2::labs(x="Year",y=expression("PAIC (Mg C ha"^{-1}*" yr"^{-1}*")")) +
  theme_publication() +
  ggplot2::theme(strip.text=ggplot2::element_text(hjust=0,size=12,face="bold"),
    panel.spacing=grid::unit(1.3,"lines"),legend.key.width=grid::unit(1.7,"lines"),
    plot.margin=ggplot2::margin(7,10,6,7)) +
  ggplot2::guides(colour=ggplot2::guide_legend(nrow=1),
    shape=ggplot2::guide_legend(nrow=1),linetype=ggplot2::guide_legend(nrow=1))
save_publication_plot(treatment_phase_figure,file.path(out,"treatment_PAIC_phases_AB"),
  width=7.2,height=7.0)
caption <- paste(
 "Figure 1. Model-adjusted periodic annual carbon increment (PAIC) during active cropping (A) and after cropping ceased (B), averaged equally across four poplar hybrids.",
 "Treatment labels in B refer to the former cropping treatments. Points show estimated marginal means; error bars show pointwise 95% confidence intervals.",
 "An asterisk marks continuous cropping versus continuous fallow and a plus marks continuous cropping versus alternate cropping, using Holm-adjusted p < 0.05 across all three treatment pairs and all observed intervals within each phase (21 tests in A; 54 in B).",
 "Markers denote differences in either direction; absence of a marker does not establish equality.",
 "Year denotes the measurement year and PAIC is annualised over the preceding measurement interval. The 2001 value averages growth years 1998-2000.",
 "The 2002-2005 boundary interval is excluded from both primary panels. Lines connect observed visits without imputing missing annual values.")
writeLines(caption,file.path(out,"treatment_PAIC_phases_AB_caption.txt"))
message("Combined A/B figure saved; model estimates and significance decisions unchanged.")

