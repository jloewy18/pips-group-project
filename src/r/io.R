# Optional input/output helpers for batch results and raw experiment data.
# RDS preserves R objects; CSV exports tables for use outside R.

# Validate a filename stem shared by the save/load functions.
validate_file_name = function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !nzchar(trimws(name)) || grepl("[<>:\"/\\\\|?*[:cntrl:]]", name) ||
      grepl("[. ]$", name)) {
    stop("Use a nonempty filename without separators or invalid filename characters.")
  }
  invisible(NULL)
}

# Check overwrite protection and prepare the output directory.
prepare_output = function(paths, dir, overwrite) {
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("overwrite must be TRUE or FALSE.")
  }
  if (!overwrite && any(file.exists(paths))) {
    stop("Files already exist. Choose another name or use overwrite = TRUE.")
  }
  if (any(dir.exists(paths))) {
    stop("An output file path points to an existing directory.")
  }
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  if (!dir.exists(dir)) {
    stop("Could not create the output directory.")
  }
  invisible(NULL)
}

# Require the table used to export batch outcomes.
validate_batch_data = function(res) {
  if (!is.list(res) || !is.data.frame(res$data)) {
    stop("The batch result must be a list containing a data-frame 'data' component.")
  }
  invisible(NULL)
}

# Require both raw task datasets.
validate_experiment_data = function(experiment) {
  required = c("dat_aware", "dat_process")
  if (!is.list(experiment) || !all(required %in% names(experiment))) {
    stop("The experiment must contain dat_aware and dat_process.")
  }
  if (!all(vapply(experiment[required], is.data.frame, logical(1)))) {
    stop("dat_aware and dat_process must be data frames.")
  }
  invisible(NULL)
}

# Save a complete run_batch() result as RDS and its outcome table as CSV.
# Returns the output paths invisibly; existing files are protected by default.
save_batch = function(res, name, dir = "data", overwrite = FALSE) {
  validate_file_name(name)
  validate_batch_data(res)
  
  paths = c(
    rds = file.path(dir, paste0(name, ".rds")),
    csv = file.path(dir, paste0(name, ".csv"))
  )
  prepare_output(paths, dir, overwrite)
  
  saveRDS(res, paths[["rds"]])
  utils::write.csv(res$data, paths[["csv"]], row.names = FALSE)
  invisible(paths)
}

# Load a complete saved batch from RDS; use the same name without extension.
load_batch = function(name, dir = "data") {
  validate_file_name(name)
  path = file.path(dir, paste0(name, ".rds"))
  if (!file.exists(path)) {
    stop(sprintf("No saved batch found at '%s'.", path))
  }
  
  res = readRDS(path)
  validate_batch_data(res)
  return(res)
}

# Save raw datasets.
# Retain parameters and seed metadata only if present in the input object.
save_experiment = function(experiment, name, dir = "data/raw",
                           overwrite = FALSE) {
  validate_file_name(name)
  validate_experiment_data(experiment)
  
  raw = experiment[c("dat_aware", "dat_process")]
  if (!is.null(experiment$parameters)) {
    raw$parameters = experiment$parameters
  }
  if (!is.null(experiment$seed)) {
    raw$seed = experiment$seed
  }
  
  paths = c(
    rds = file.path(dir, paste0(name, ".rds")),
    awareness = file.path(dir, paste0(name, "_awareness.csv")),
    processing = file.path(dir, paste0(name, "_processing.csv"))
  )
  prepare_output(paths, dir, overwrite)
  
  saveRDS(raw, paths[["rds"]])
  utils::write.csv(raw$dat_aware, paths[["awareness"]], row.names = FALSE)
  utils::write.csv(raw$dat_process, paths[["processing"]], row.names = FALSE)
  invisible(paths)
}

# Load raw task datasets and any saved metadata from RDS.
# For the separate CSV files, use utils::read.csv().
load_experiment = function(name, dir = "data/raw") {
  validate_file_name(name)
  path = file.path(dir, paste0(name, ".rds"))
  if (!file.exists(path)) {
    stop(sprintf("No saved experiment found at '%s'.", path))
  }
  
  experiment = readRDS(path)
  validate_experiment_data(experiment)
  return(experiment)
}