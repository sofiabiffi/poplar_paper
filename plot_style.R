# Workspace figure defaults. Okabe-Ito colours; labels never change analysis IDs.
publication_palette <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7",
                         "#E69F00", "#56B4E9", "#000000", "#F0E442")
publication_hybrids <- c(B = "Beaupre", G = "Gibecq", R = "Robusta", T = "Trichobel")
publication_treatments <- c(F = "Continuous fallow", C = "Continuous cropping", A = "Alternate cropping")
publication_labels <- function(x) {
  labels <- c(publication_hybrids, publication_treatments,
    CF = "Continuous fallow", CC = "Continuous cropping", AC = "Alternate cropping",
    "1_tree" = "Tree row", "2_alley" = "Alley", "3_arable" = "Arable reference")
  out <- as.character(x)
  hit <- match(out, names(labels))
  out[!is.na(hit)] <- unname(labels[hit[!is.na(hit)]])
  response_hit <- grepl("^(PAI|PAIC|MAIC)_[BGRT]$", out)
  if (any(response_hit)) {
    hybrid <- publication_hybrids[sub(".*_", "", out[response_hit])]
    out[response_hit] <- paste(sub("_.*", "", out[response_hit]), hybrid, sep = ": ")
  }
  out
}
publication_table <- function(x) {
  x <- as.data.frame(x)
  if ("hybrid_code" %in% names(x) && !"hybrid" %in% names(x))
    x$hybrid <- publication_labels(x$hybrid_code)
  if ("treatment_code" %in% names(x) && !"treatment" %in% names(x))
    x$treatment <- publication_labels(x$treatment_code)
  if ("contrast" %in% names(x)) {
    x$contrast_code <- as.character(x$contrast)
    for (code in names(publication_treatments))
      x$contrast <- gsub(paste0("\\b", code, "\\b"), publication_treatments[[code]], x$contrast)
  }
  if ("term" %in% names(x)) {
    x$term_code <- x$term
    x$term <- gsub("treatment_code", "Cropping treatment", x$term, fixed = TRUE)
    x$term <- gsub("hybrid_code", "Hybrid", x$term, fixed = TRUE)
    x$term <- gsub("interval", "Measurement interval", x$term, fixed = TRUE)
    x$term <- gsub("block", "Block", x$term, fixed = TRUE)
    x$term <- gsub(":", " x ", x$term, fixed = TRUE)
  }
  x
}
theme_publication <- function(base_size = 11) {
  ggplot2::theme_classic(base_size = base_size, base_family = "sans") +
    ggplot2::theme(legend.position = "bottom", legend.title = ggplot2::element_text(face = "bold"),
      legend.key.width = grid::unit(1.5, "lines"),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      axis.text = ggplot2::element_text(colour = "black"),
      plot.title = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank(),
      plot.caption = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(8, 12, 8, 8))
}
publication_scales <- function(groups, title = NULL, include_fill = FALSE, include_linetype = TRUE) {
  n <- length(groups)
  if (n > length(publication_palette)) stop("More than eight groups: use facets rather than recycle colours.")
  colours <- stats::setNames(publication_palette[seq_len(n)], groups)
  shapes <- stats::setNames(c(16, 17, 15, 18, 3, 4, 8, 1)[seq_len(n)], groups)
  lines <- stats::setNames(rep(c("solid", "dashed", "dotdash", "longdash"), length.out = n), groups)
  scales <- list(ggplot2::scale_colour_manual(values = colours, breaks = groups, labels = publication_labels, name = title),
       ggplot2::scale_shape_manual(values = shapes, breaks = groups, labels = publication_labels, name = title),
       ggplot2::scale_linetype_manual(values = lines, breaks = groups, labels = publication_labels, name = title))
  if (!include_linetype) scales <- scales[-3L]
  if (include_fill) scales <- c(scales, list(ggplot2::scale_fill_manual(values = colours, breaks = groups, labels = publication_labels, name = title)))
  scales
}
save_publication_plot <- function(plot, path_stem, width = 7.2, height = 4.8) {
  # Finish rendering before replacing an image that may be open in a viewer.
  for (extension in c("png", "pdf")) {
    target <- paste0(path_stem, ".", extension)
    temp <- tempfile("figure_", tmpdir = dirname(target), fileext = paste0(".", extension))
    if (extension == "png") {
      ggplot2::ggsave(temp, plot, width = width, height = height,
        units = "in", dpi = 600, bg = "white")
    } else {
      ggplot2::ggsave(temp, plot, width = width, height = height,
        units = "in", device = grDevices::pdf, useDingbats = FALSE, bg = "white")
    }
    copied <- FALSE
    for (attempt in seq_len(3)) {
      copied <- file.copy(temp, target, overwrite = TRUE)
      if (copied) break
      Sys.sleep(0.2)
    }
    if (!copied) stop("Could not replace figure; rendered copy retained at ", temp)
    unlink(temp)
  }
}
# Safe discrete and continuous defaults also apply to older plotting scripts.
options(ggplot2.discrete.colour = publication_palette,
        ggplot2.discrete.fill = publication_palette,
        ggplot2.continuous.colour = "viridis",
        ggplot2.continuous.fill = "viridis")
ggplot2::theme_set(theme_publication())


# For legacy scripts: preserve their filenames and dimensions, and add vector PDF.
publication_ggsave <- function(filename, plot = ggplot2::last_plot(), ..., dpi = 600) {
  ggplot2::ggsave(filename = filename, plot = plot, ..., dpi = max(600, dpi), bg = "white")
  if (tolower(tools::file_ext(filename)) == "png")
    ggplot2::ggsave(filename = sub("\\.png$", ".pdf", filename, ignore.case = TRUE),
      plot = plot, ..., device = grDevices::pdf, useDingbats = FALSE, bg = "white")
}





