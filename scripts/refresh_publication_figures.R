# Run from the project root. Refresh presentation from saved data and models.
root <- normalizePath('.', winslash='/')
options(poplar.paper.root=root)
source('library.R')
source('scripts/config.R')
source('scripts/prep/00_helpers.R')
paper_data <- readRDS('data/processed/paper_data.rds')
list2env(paper_data, envir=.GlobalEnv)
dir.create('results/figure_descriptions',showWarnings=FALSE)
original_save <- save_publication_plot
save_publication_plot <- function(plot,path_stem,width=7.2,height=4.8) {
  notes <- c(plot$labels$title,plot$labels$subtitle,plot$labels$caption)
  writeLines(as.character(notes),file.path(root,'results/figure_descriptions',paste0(basename(path_stem),'.txt')))
  original_save(plot,path_stem,width,height)
}
source('analysis/01_growth_descriptive.R')
source('scripts/treatment_presentation.R')
models <- readRDS('results/models/treatment_PAIC_models.rds')
for (label in names(models)) {
  emm <- emmeans::emmeans(models[[label]]$model,~treatment_code|interval,weights='equal',lmer.df='satterthwaite')
  present_treatment_phase(emm,label)
}
source('analysis/04_soc_stocks.R')
# Reuse the current quadratic-age model and existing bootstrap results.
m <- readRDS('results/models/final_raw_paic_weather.rds')
fits <- m$fits; dat <- m$data
effects <- read.csv('results/tables/final_weather_absolute_effects.csv')
hybrids <- names(publication_hybrids); ages <- 'Quadratic age'
ref_temp <- mean(dat$temp_c); ref_rain <- mean(dat$rain_c)
out <- function(x,n) invisible(NULL) # figure refresh does not replace model tables
common_cor <- read.csv('results/tables/final_weather_raw_correlations_common.csv')
lines <- readLines('analysis/14_raw_paic_weather_final.R')
start <- grep('^labels <- c\\(spring_rainfall',lines)
end <- grep("^source\\('poplar_paper/analysis/14_raw_paic_weather_figures.R'",lines)
eval(parse(text=lines[start:(end-1)]))
source('analysis/14_raw_paic_weather_figures.R')
# These legacy modules use workspace-relative paths. Adapt paths in memory.
run_local <- function(path) {
  lines <- readLines(path)
  lines <- gsub("'poplar_paper/", "'",lines,fixed=TRUE)
  lines <- gsub("root <- 'poplar_paper'", "root <- '.'",lines,fixed=TRUE)
  eval(parse(text=lines),envir=.GlobalEnv)
}
run_local('analysis/17_soc_sequestration.R')
run_local('analysis/09_paic_shared_fluctuations.R')
