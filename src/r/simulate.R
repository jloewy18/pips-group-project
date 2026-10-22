# Data generation for the awareness and processing tasks.

# Simulate an individual dataset for the processing task.
sim_individual_process = function(ind_sensitivity, K) {
  # Draw standardized RTs for both conditions.
  con_RT = rnorm(K / 2, mean = -ind_sensitivity / 2, sd = 1)
  incon_RT = rnorm(K / 2, mean = +ind_sensitivity / 2, sd = 1)
  
  dat = data.frame(
    condition = rep(c("con", "incon"), each = K / 2),
    response = c(con_RT, incon_RT)
  )
  
  # Randomize trial order.
  dat = dat[sample(nrow(dat)), ]
  return(dat)
}

# Simulate processing data across N participants.
sim_process = function(sensitivity, N, K, q2) {
  dat = data.frame()
  
  for (i in seq_len(N)) {
    # q2 is the between-participant variance.
    ind_sensitivity = rnorm(1, mean = sensitivity, sd = sqrt(q2))
    
    partDat = data.frame(
      participant = i,
      sim_individual_process(ind_sensitivity, K)
    )
    dat = rbind(dat, partDat)
  }
  
  return(dat)
}

# Simulate an individual dataset for the awareness task.
sim_individual_aware = function(ind_sensitivity, K) {
  # Internal evidence for two stimulus categories.
  evidence_A = rnorm(K / 2, mean = -ind_sensitivity / 2, sd = 1)
  evidence_B = rnorm(K / 2, mean = +ind_sensitivity / 2, sd = 1)
  
  dat = data.frame(
    condition = rep(c("A", "B"), each = K / 2),
    evidence = c(evidence_A, evidence_B)
  )
  
  # Choose B when evidence is above zero; otherwise choose A.
  choice = ifelse(dat$evidence > 0, "B", "A")
  dat$correct = choice == dat$condition
  
  # Internal evidence is not part of the exported dataset.
  dat$evidence = NULL
  
  # Randomize trial order.
  dat = dat[sample(nrow(dat)), ]
  return(dat)
}

# Simulate awareness data across N participants.
sim_aware = function(sensitivity, N, K, q2) {
  dat = data.frame()
  
  for (i in seq_len(N)) {
    ind_sensitivity = rnorm(1, mean = sensitivity, sd = sqrt(q2))
    
    partDat = data.frame(
      participant = i,
      sim_individual_aware(ind_sensitivity, K)
    )
    dat = rbind(dat, partDat)
  }
  
  return(dat)
}

# Validate experiment parameters
validate_parameters = function(ep) {
  if (!is.list(ep))
    stop("Experiment parameters must be a list.")
  
  # Reject the old interface so conflicting participant counts cannot be ignored.
  if (any(c("N_aware", "N_process") %in% names(ep)))
    stop("Use one shared N instead of N_aware and N_process.")
  
  required = c(
    "N",
    "delta_process", "K_process", "q2_process",
    "delta_aware", "K_aware", "q2_aware"
  )
  
  if (!all(required %in% names(ep)))
    stop("Missing experiment parameters: ",
         paste(setdiff(required, names(ep)), collapse = ", "))
  
  if (any(!vapply(ep[required], function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x)
  }, logical(1))))
    stop("Parameters must be finite numeric scalars.")
  
  if (ep$N < 3 || ep$N != round(ep$N))
    stop("N must be an integer of at least 3, shared by both tasks.")
  
  ks = c(ep$K_aware, ep$K_process)
  if (any(ks < 4 | ks != round(ks) | ks %% 2 != 0))
    stop("K must be an even total trial count of at least 4.")
  
  # Zero variance is allowed; negative variance is not.
  if (any(c(ep$q2_aware, ep$q2_process) < 0))
    stop("q2 cannot be negative.")
  
  invisible(NULL)
}

# Simulate both tasks with the same N and matching participant IDs.
sim_exp = function(exp_par) {
  validate_parameters(exp_par)
  
  # Keep processing first to preserve the existing random-draw order.
  dat_process = sim_process(
    sensitivity = exp_par$delta_process,
    N = exp_par$N,
    K = exp_par$K_process,
    q2 = exp_par$q2_process
  )
  
  dat_aware = sim_aware(
    sensitivity = exp_par$delta_aware,
    N = exp_par$N,
    K = exp_par$K_aware,
    q2 = exp_par$q2_aware
  )
  
  return(list(dat_process = dat_process, dat_aware = dat_aware))
}