# Save/load helpers

# Saves a batch result (output of run_batch()) to data/ as .rds
# and .csv (one row per successfully analysed experiment)
save_batch = function(res, name, dir = "data") {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  saveRDS(res, file.path(dir, paste0(name, ".rds")))
  utils::write.csv(res$data, file.path(dir, paste0(name, ".csv")), row.names = FALSE)
  invisible(file.path(dir, name))
}

# Loads the complete batch result from its RDS file
load_batch = function(name, dir = "data") {
  path = file.path(dir, paste0(name, ".rds"))
  if (!file.exists(path)) {
    stop(sprintf("No saved batch found at '%s'.", path))
  }
  readRDS(path)
}

# Saves raw datasets for one experiment, for example output of sim_exp()
save_experiment = function(experiment, name, dir = "data/raw",
                           overwrite = FALSE) {
  required = c("dat_aware", "dat_process")
  if (!is.list(experiment) || !all(required %in% names(experiment))) {
    stop("experiment must contain dat_aware and dat_process.")
  }
  if (!all(vapply(experiment[required], is.data.frame, logical(1)))) {
    stop("dat_aware and dat_process must be data frames.")
  }
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !nzchar(name) || grepl("[/\\\\]", name) || name %in% c(".", "..")) {
    stop("Use a nonempty file name without folder separators.")
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("overwrite must be TRUE or FALSE.")
  }
  
  raw = experiment[required]
  if (!is.null(experiment$parameters)) raw$parameters = experiment$parameters
  if (!is.null(experiment$seed)) raw$seed = experiment$seed
  
  paths = c(
    rds = file.path(dir, paste0(name, ".rds")),
    awareness = file.path(dir, paste0(name, "_awareness.csv")),
    processing = file.path(dir, paste0(name, "_processing.csv"))
  )
  if (!overwrite && any(file.exists(paths))) {
    stop("Files already exist. Choose another name or use overwrite = TRUE.")
  }
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  if (!dir.exists(dir)) stop("Could not create the output directory.")
  
  saveRDS(raw, paths[["rds"]])
  utils::write.csv(raw$dat_aware, paths[["awareness"]], row.names = FALSE)
  utils::write.csv(raw$dat_process, paths[["processing"]], row.names = FALSE)
  invisible(paths)
}

# Loads raw datasets and any saved metadata from their RDS file
# For individual CSV files, use read.csv()
load_experiment = function(name, dir = "data/raw") {
  path = file.path(dir, paste0(name, ".rds"))
  if (!file.exists(path)) {
    stop(sprintf("No saved experiment found at '%s'.", path))
  }
  experiment = readRDS(path)
  required = c("dat_aware", "dat_process")
  if (!is.list(experiment) || !all(required %in% names(experiment))) {
    stop("The file does not contain the expected experiment datasets.")
  }
  if (!all(vapply(experiment[required], is.data.frame, logical(1)))) {
    stop("The saved task datasets must be data frames.")
  }
  experiment
}
