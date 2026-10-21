# Runs the simulation multiple times.
# Q2 and ALPHA are shared defaults defined in config.R.

# Collect simulation settings in a named list; defaults match the Shiny app.
batch_settings = function(K_aware = 100,
                          K_process = 400,
                          delta_aware = 0.25,
                          delta_process = 0.25,
                          N = 10,
                          q2 = Q2,
                          B = 100,
                          seed = 2026) {
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

# Reject invalid settings before they become repeated experiment failures.
valid_batch_settings = function(s) {
  required = c("K_aware", "K_process", "delta_aware", "delta_process",
               "N", "q2", "B", "seed")
  if (!is.list(s) || !all(required %in% names(s))) {
    return(FALSE)
  }
  
  valid_number = function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x)
  }
  valid_integer = function(x, low, high) {
    valid_number(x) && x == round(x) && x >= low && x <= high
  }
  valid_trials = function(x) {
    valid_integer(x, 50, 500) && x %% 2 == 0
  }
  
  # Sensitivities may exceed slider bounds in scripted simulations.
  valid_number(s$delta_aware) &&
    valid_number(s$delta_process) &&
    valid_number(s$q2) && s$q2 >= 0 &&
    valid_integer(s$N, 3, 200) &&
    valid_integer(s$B, 20, 1000) &&
    valid_integer(s$seed, 1, 1000000000) &&
    valid_trials(s$K_aware) &&
    valid_trials(s$K_process)
}

# Preserve outcome columns when every experiment fails so saved batches stay readable.
empty_batch_data = function() {
  data.frame(
    experiment = integer(),
    aware_sig = logical(),
    process_sig = logical(),
    outcome = integer(),
    double_processing_advantage = logical(),
    comparison_processing_advantage = logical(),
    p_awareness = numeric(),
    p_processing = numeric(),
    p_comparison = numeric()
  )
}

# Keep failed attempts rather than replacing them to expose potential selection bias.
run_batch = function(s, alpha = ALPHA, on_progress = NULL) {
  if (!valid_batch_settings(s)) {
    stop(paste(
      "Invalid batch settings: use finite numeric sensitivities, nonnegative finite q2,",
      "3-200 participants, 20-1000 experiments, even trial counts from 50-500,",
      "and an integer seed from 1 to 1,000,000,000."
    ))
  }
  if (!is.numeric(alpha) || length(alpha) != 1L ||
      !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("alpha must be a finite number strictly between 0 and 1.")
  }
  if (!is.null(on_progress) && !is.function(on_progress)) {
    stop("on_progress must be NULL or a function accepting b and B.")
  }
  
  B = as.integer(s$B)
  rows = vector("list", B)
  errors = character(B)
  
  # Seed once so a reproducible batch still contains distinct random experiments.
  set.seed(as.integer(s$seed))
  for (b in seq_len(B)) {
    # Catch experiment failures without hiding invalid settings or progress errors.
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
    }, error = function(err) err)
    
    if (inherits(result, "error")) {
      errors[b] = conditionMessage(result)
    } else {
      # Single-bracket assignment preserves list positions for experiment IDs.
      rows[b] = list(result)
    }
    
    # Throttle progress updates to reduce UI overhead without changing simulations.
    if (!is.null(on_progress) && (b %% 5L == 0L || b == B)) {
      on_progress(b, B)
    }
  }
  
  successful = Filter(Negate(is.null), rows)
  dat = if (length(successful)) {
    do.call(rbind, successful)
  } else {
    empty_batch_data()
  }
  rownames(dat) = NULL
  
  # Store alpha separately so the app can still compare settings lists directly.
  list(
    settings = s,
    data = dat,
    errors = errors[nzchar(errors)],
    attempted = B,
    alpha = alpha
  )
}
