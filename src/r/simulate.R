# Data generation for the awareness and processing tasks.

# Simulate indivdual data sets for processing task
sim_individual_process = function(ind_sensitivity, K) {
  # Draw (standardized) RTs for each participant for both conditions
  con_RT = rnorm(K / 2, mean = -ind_sensitivity / 2, sd = 1)
  incon_RT = rnorm(K / 2, mean = +ind_sensitivity / 2, sd = 1)
  
  # Data frames with individual RTs per condition
  dat = data.frame(condition = rep(c("con", "incon"), each = K / 2),
                   response = c(con_RT, incon_RT))
  
  # Randomize trial order
  dat = dat[sample(nrow(dat)), ]
  return(dat)
}

# Simulate data sets across participants for processing task
sim_process = function(sensitivity, N, K, q2) {
  # Simulated data with individuals' RTs across all participants
  dat = data.frame()
  for (i in seq_len(N)) {
    # Sample individial sensitivity d'
    ind_sensitivity = rnorm(1, mean = sensitivity, sd = sqrt(q2))
    
    # Individual data sets
    partDat = data.frame(participant = i, sim_individual_process(ind_sensitivity, K))
    
    # Final data set
    dat = rbind(dat, partDat)
  }
  return(dat)
}

# Simulate indivdual data sets for awareness task
sim_individual_aware = function(ind_sensitivity, K) {
  # Internal evidence for two stimulus categories
  evidence_A = rnorm(K / 2, mean = -ind_sensitivity / 2, sd = 1)
  evidence_B = rnorm(K / 2, mean = +ind_sensitivity / 2, sd = 1)
  
  dat = data.frame(condition = rep(c("A", "B"), each = K / 2),
                   evidence = c(evidence_A, evidence_B))
  
  # Choose B when evidence is above zero; otherwise choose A
  choice = ifelse(dat$evidence > 0, "B", "A")
  
  # Correct if choice and condition correspond
  dat$correct = choice == dat$condition
  
  # Delete internal evidence column, no longer needed
  dat$evidence = NULL
  
  # Randomize trial order
  dat = dat[sample(nrow(dat)), ]
  
  return(dat)
}

# Simulate data sets across participants for awareness task
sim_aware = function(sensitivity, N, K, q2) {
  # Simulated data with individuals' accuracy across all participants
  dat = data.frame()
  for (i in seq_len(N)) {
    # Sample individial sensitivity d'
    ind_sensitivity = rnorm(1, mean = sensitivity, sd = sqrt(q2))
    
    # Individual data set
    partDat = data.frame(participant = i, sim_individual_aware(ind_sensitivity, K))
    
    # Final data set
    dat = rbind(dat, partDat)
  }
  return(dat)
}

# Validating input for the parameters
validate_parameters = function(ep) {
  required = c(
    "delta_process",
    "N_process",
    "K_process",
    "q2_process",
    "delta_aware",
    "N_aware",
    "K_aware",
    "q2_aware"
  )
  
  # Error for missing parameters
  if (!all(required %in% names(ep)))
    stop("Missing experiment parameters.")
  
  # Error for non-numeric and/or infinite parameters
  if (any(!vapply(ep[required], function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x)
  }, logical(1))))
    stop("Parameters must be finite numeric scalars.")
  
  # Error for less than 3 participants
  ns = c(ep$N_aware, ep$N_process)
  if (any(ns < 3 |
          ns != round(ns)))
    stop("Use at least 3 participants per task.")
  
  # Error for non-even number of trials and less than 4 trials
  ks = c(ep$K_aware, ep$K_process)
  if (any(ks < 4 | ks != round(ks) | ks %% 2 != 0)) {
    stop("K must be an even total trial count of at least 4.")
  }
  
  # Error for non-positive between-participants variance
  if (any(c(ep$q2_aware, ep$q2_process) < 0))
    stop("q2 cannot be negative.")
}

# Simulate experiment
sim_exp = function(exp_par) {
  # Ensure valid parameters
  validate_parameters(exp_par)
  
  # Simulate data for processing task
  dat_process = sim_process(exp_par$delta_process,
                            exp_par$N_process,
                            exp_par$K_process,
                            exp_par$q2_process)
  
  # Simulate data for awareness task
  dat_aware = sim_aware(exp_par$delta_aware,
                        exp_par$N_aware,
                        exp_par$K_aware,
                        exp_par$q2_aware)
  
  # Return list of data sets
  return(list(dat_process = dat_process, dat_aware = dat_aware))
}