# Runs the simulation multiple times.
# Q2 and ALPHA are shared defaults defined in config.R.

# Collect simulation settings in a named list; defaults match the Shiny app.
batch_settings = function(
    K_aware = 100,        # Awareness trials per participant.
    K_process = 400,      # Processing trials per participant.
    delta_aware = 0.25,   # Population mean awareness sensitivity.
    delta_process = 0.25, # Population mean processing sensitivity.
    N = 10,               # Number of participants per task.
    q2 = Q2,              # Between-participant sensitivity variance.
    B = 100,              # Number of simulations.
    seed = 2026           # Seed for reproducibility.
) {
  list(
    K_aware = K_aware,
    K_process = K_process,
    delta_aware = delta_aware,
    delta_process = delta_process,
    N = N,
    q2 = q2,
    B = B,
    seed = seed
  )
}

# Return TRUE when batch settings satisfy the app's count and seed limits.
valid_batch_settings = function(s) {
  if (!is.list(s))
    return(FALSE)
  
  valid_integer = function(x, low, high)
    is.numeric(x) &&
    length(x) == 1 &&
    is.finite(x) && x == round(x) && x >= low && x <= high
  
  # Even trial counts keep the two conditions balanced.
  valid_trials = function(x)
    valid_integer(x, 50, 500) && x %% 2 == 0
  
  valid_integer(s$N, 3, 200) &&
    valid_integer(s$B, 20, 1000) &&
    valid_integer(s$seed, 1, 1000000000) &&
    valid_trials(s$K_aware) && valid_trials(s$K_process)
}

# Repeat and classify experiments; return settings, successful rows, errors, and attempt count.
# Optional on_progress(completed, total) reports progress to the app.
run_batch = function(s,
                     alpha = ALPHA,
                     on_progress = NULL) {
  if (!valid_batch_settings(s)) {
    stop(
      "Invalid batch settings: use 3-200 participants, 20-1000 experiments, even trial counts from 50-500, and an integer seed from 1 to 1,000,000,000."
    )
  }
  
  # Reject invalid simulation parameters before attempting the whole batch.
  validate_parameters(list(
    N = s$N,
    delta_aware = s$delta_aware,
    K_aware = s$K_aware,
    q2_aware = s$q2,
    delta_process = s$delta_process,
    K_process = s$K_process,
    q2_process = s$q2
  ))
  
  B = as.integer(s$B)
  
  # Preallocate storage for one result and possible error per experiment.
  rows = vector("list", B)
  errors = character(B)
  
  # Seed to reproduce the batch without restarting the random sequence each time.
  set.seed(as.integer(s$seed))
  
  for (b in seq_len(B)) {
    # Record failed experiments without stopping the remaining batch.
    result = tryCatch({
      e = run_simulation(
        K_aware = s$K_aware,
        K_process = s$K_process,
        delta_aware = s$delta_aware,
        delta_process = s$delta_process,
        N = as.integer(s$N),
        q2 = s$q2
      )
      classify_experiment(e, experiment = b, alpha = alpha)
    }, error = function(err) {
      errors[b] <<- conditionMessage(err)
      NULL
    })
    
    # Preserve the list position even when a failed experiment returns NULL.
    rows[b] = list(result)
    
    # Update progress every five experiments and at completion.
    if (!is.null(on_progress) &&
        (b %% 5L == 0L || b == B))
      on_progress(b, B)
  }
  
  # Combine successful classifications; data is NULL if every experiment failed.
  successful = Filter(Negate(is.null), rows)
  dat = if (length(successful))
    do.call(rbind, successful)
  else
    NULL
  
  list(
    settings = s,
    data = dat,
    errors = errors[nzchar(errors)],
    attempted = B
  )
}