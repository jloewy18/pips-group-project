# Participant-level statistics and t-tests for both tasks and their comparison.

# Standard error of the mean.
sem = function(x) {
  return(sd(x) / sqrt(length(x)))
}

# Summarize participant-level values and run a one-sample t-test.
summarize_with_t = function(x, mu = 0, alternative = "two.sided") {
  return(list(
    mean = mean(x),
    sd = sd(x),
    sem = sem(x),
    ttest = t.test(x, mu = mu, alternative = alternative),
    all = x
  ))
}

# Awareness accuracy: two-sided test against chance.
acc_results_aware = function(dat_aware) {
  acc = tapply(dat_aware$correct, dat_aware$participant, mean)
  return(summarize_with_t(acc, mu = 0.5))
}

# Sensitivity estimated from correct responses in two conditions.
sens_results_aware = function(dat_aware) {
  conditions = sort(unique(dat_aware$condition))
  parts = split(dat_aware, dat_aware$participant)
  
  ds = vapply(parts, function(dat) {
    acc_A = dat$correct[dat$condition == conditions[1]]
    acc_B = dat$correct[dat$condition == conditions[2]]
    
    hit = mean(acc_A)
    fa = 1 - mean(acc_B)
    
    # Boundary corrections for hit and false-alarm rates of 0 or 1.
    if (hit == 0)
      hit = 1 / length(acc_A)
    if (hit == 1)
      hit = 1 - 1 / length(acc_A)
    if (fa == 0)
      fa = 1 / length(acc_B)
    if (fa == 1)
      fa = 1 - 1 / length(acc_B)
    
    qnorm(hit) - qnorm(fa)
  }, numeric(1))
  
  return(summarize_with_t(ds, mu = 0))
}

# Require the simulator's explicit processing labels for every participant.
validate_processing_conditions = function(dat_process) {
  if (anyNA(dat_process$condition) ||
      !setequal(as.character(dat_process$condition), c("con", "incon")))
    stop("Processing conditions must be labelled 'con' and 'incon'.")
  
  parts = split(as.character(dat_process$condition), dat_process$participant)
  has_both = vapply(parts, function(x) {
    setequal(x, c("con", "incon"))
  }, logical(1))
  
  if (!all(has_both))
    stop("Every participant must have both 'con' and 'incon' trials.")
  
  invisible(NULL)
}

# Processing RT effect used by the double t-test approach.
processing_measures_process = function(dat_process) {
  validate_processing_conditions(dat_process)
  parts = split(dat_process, dat_process$participant)
  
  mean_con = vapply(parts, function(dat) {
    mean(dat$response[dat$condition == "con"])
  }, numeric(1))
  
  mean_incon = vapply(parts, function(dat) {
    mean(dat$response[dat$condition == "incon"])
  }, numeric(1))
  
  return(list(
    mean_con = list(mean = mean(mean_con), all = mean_con),
    mean_incon = list(mean = mean(mean_incon), all = mean_incon),
    
    # Positive differences mean faster RTs on congruent trials.
    mean_diff = summarize_with_t(
      mean_incon - mean_con,
      mu = 0,
      alternative = "greater"
    )
  ))
}

# Classify processing trials using each participant's observed median RT.
add_predictions_process = function(dat_process) {
  validate_processing_conditions(dat_process)
  
  dat_process$criterion = ave(
    dat_process$response,
    dat_process$participant,
    FUN = median
  )
  
  # Predict incongruent above the median; congruent at or below it.
  predicted_incongruent = dat_process$response > dat_process$criterion
  dat_process$correct = ifelse(
    dat_process$condition == "con",
    !predicted_incongruent,
    predicted_incongruent
  )
  
  return(dat_process)
}

# Additional processing summaries; these tests do not set advantage flags.
acc_results_process = function(dat_process) {
  return(acc_results_aware(add_predictions_process(dat_process)))
}

sens_results_process = function(dat_process) {
  return(sens_results_aware(add_predictions_process(dat_process)))
}

add_results = function(experiment, dependent = TRUE) {
  if (!isTRUE(dependent))
    stop("This project implements the supplied paired analysis only.")
  
  # Match participant IDs before comparing the tasks.
  ids_aware = sort(unique(experiment$dat_aware$participant))
  ids_process = sort(unique(experiment$dat_process$participant))
  
  if (!identical(ids_aware, ids_process))
    stop("The paired analysis requires the same participant IDs in both tasks.")
  
  experiment$results_aware = list(
    accuracy = acc_results_aware(experiment$dat_aware),
    sensitivity = sens_results_aware(experiment$dat_aware)
  )
  
  experiment$results_process = list(
    processingMeasure = processing_measures_process(experiment$dat_process),
    accuracy = acc_results_process(experiment$dat_process),
    sensitivity = sens_results_process(experiment$dat_process)
  )
  
  # Align estimates by participant name before taking paired differences.
  d_aware = experiment$results_aware$sensitivity$all
  d_process = experiment$results_process$sensitivity$all[names(d_aware)]
  a_aware = experiment$results_aware$accuracy$all
  a_process = experiment$results_process$accuracy$all[names(a_aware)]
  
  experiment$results_comparison = list(
    # Retained as an additional summary, not used for advantage classification.
    accuracy = summarize_with_t(a_process - a_aware, mu = 0),
    
    # One-sided paired comparison: processing sensitivity exceeds awareness.
    sensitivity = summarize_with_t(
      d_process - d_aware,
      mu = 0,
      alternative = "greater"
    )
  )
  
  return(experiment)
}