# Loads all project code into the global environment
# Run from the project root (main.Rmd does this automatically)
local({
  r_dir = file.path("src", "r")
  if (!dir.exists(r_dir)) stop("Run this from the project root (the folder containing 'src').")
  
  source(file.path(r_dir, "dependencies.R"))
  ensure_packages()
  
  # Required for the simulation and the app
  required = c("config.R", "plot_theme.R", "io.R", "simulate.R", "participant_analysis.R",
               "run_simulation.R", "classify.R", "batch.R", "shiny_app.R")
  for (script in required) source(file.path(r_dir, script))
  
  # Required for the analysis
  optional = c("analysis.R")
  for (script in optional) {
    path = file.path(r_dir, script)
    if (file.exists(path)) source(path) else message("Skipping missing optional file: ", path)
  }
})