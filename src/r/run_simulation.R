# Runs a complete experiment: simulation + analysis
# q2 is the VARIANCE of the true participant sensitivities
run_simulation = function(K_aware = 400,
                          K_process = 400,
                          delta_aware = 0.25,
                          delta_process = 0.25,
                          N = 10,
                          q2 = 0.15^2) {
  exp_par = list(
    delta_aware = delta_aware,
    N_aware = N,
    K_aware = K_aware,
    q2_aware = q2,
    delta_process = delta_process,
    N_process = N,
    K_process = K_process,
    q2_process = q2
  )
  
  experiment = sim_exp(exp_par)
  experiment = add_results(experiment, dependent = TRUE)
  experiment$parameters = exp_par
  
  return(experiment)
}
