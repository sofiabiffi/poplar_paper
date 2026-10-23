project_path <- function(...) file.path(getOption("poplar.paper.root"), ...)
safe_mean <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
safe_sum <- function(x) if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
safe_median <- function(x) if (all(is.na(x))) NA_real_ else median(x, na.rm = TRUE)
safe_quantile <- function(x, p) if (all(is.na(x))) NA_real_ else unname(quantile(x, p, na.rm = TRUE))
read_source <- function(name, sheet = 1) {
  x <- readxl::read_excel(project_path("data", "raw", name), sheet = sheet,
                          .name_repair = "minimal")
  names(x) <- trimws(names(x))
  if (anyDuplicated(names(x))) stop("Duplicate input column names in ", name)
  x
}
require_columns <- function(x, expected, label) {
  absent <- setdiff(expected, names(x))
  if (length(absent)) stop(label, " is missing: ", paste(absent, collapse = ", "))
}
assert_unique <- function(x, keys, label) {
  if (anyDuplicated(as.data.frame(x[keys]))) stop("Duplicate keys in ", label)
}
summarise_growth <- function(data, groups) {
  data |>
    tidyr::pivot_longer(c(PAIC, MAIC, carbon_stock_mg_ha), names_to = "metric", values_to = "value") |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(groups, "metric")))) |>
    dplyr::summarise(
      n_records = dplyr::n(), n_valid = sum(!is.na(value)),
      n_trees_valid = dplyr::n_distinct(tree_id[!is.na(value)]),
      mean = safe_mean(value), median = safe_median(value),
      sd = if (sum(!is.na(value)) > 1) sd(value, na.rm = TRUE) else NA_real_,
      q25 = safe_quantile(value, .25), q75 = safe_quantile(value, .75),
      min = safe_quantile(value, 0), max = safe_quantile(value, 1), .groups = "drop"
    )
}

