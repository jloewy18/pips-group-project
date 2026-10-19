# Settings list in the same form the app uses
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

# TRUE if all batch settings are valid.
valid_batch_settings = function(s) {
  valid_integer = function(x, low, high)
    is.numeric(x) &&
    length(x) == 1 &&
    is.finite(x) && x == round(x) && x >= low && x <= high
  valid_trials = function(x)
    valid_integer(x, 50, 500) && x %% 2 == 0
  valid_integer(s$N, 3, 200) &&
    valid_integer(s$B, 20, 1000) &&
    valid_integer(s$seed, 1, 1000000000) &&
    valid_trials(s$K_aware) && valid_trials(s$K_process)
}

# Repeats the experiment s$B times and classifies each one.
# on_progress: optional function(b, B), called every 5 experiments and at the end.
# Returns list(settings, data, errors, attempted):
#   data   = one row per successful experiment (see classify_experiment())
#   errors = messages of experiments that failed (failed ones are not replaced)
run_batch = function(s,
                     alpha = ALPHA,
                     on_progress = NULL) {
  if (!valid_batch_settings(s)) {
    stop(
      "Invalid batch settings: use 3-200 participants, 20-1000 experiments, even trial counts from 50-500, and an integer seed from 1 to 1,000,000,000."
    )
  }
  B = as.integer(s$B)
  rows = vector("list", B)
  errors = character(B)
  set.seed(as.integer(s$seed))
  for (b in seq_len(B)) {
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
    rows[b] = list(result)
    if (!is.null(on_progress) &&
        (b %% 5L == 0L || b == B))
      on_progress(b, B)
  }
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