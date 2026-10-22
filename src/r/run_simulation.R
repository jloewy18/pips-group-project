# Runs an experiment: simulate data using mean sensitivities, then analyse.
# Q2 is a shared default defined in config.R.

# Run simulation; defaults match the Shiny app.
run_simulation = function(
    K_aware = 100,        # Awareness trials per participant.
    K_process = 400,      # Processing trials per participant.
    delta_aware = 0.25,   # Population mean awareness sensitivity.
    delta_process = 0.25, # Population mean processing sensitivity.
    N = 10,               # Number of participants per task.
    q2 = Q2               # Between-participant sensitivity variance.
  ) {
  exp_par = list(
    N = N,
    delta_aware = delta_aware,
    K_aware = K_aware,
    q2_aware = q2,
    delta_process = delta_process,
    K_process = K_process,
    q2_process = q2
  )
  
  experiment = sim_exp(exp_par)
  # Compare tasks within participants using matching participant IDs.
  experiment = add_results(experiment, dependent = TRUE)
  experiment$parameters = exp_par
  
  return(experiment)
}