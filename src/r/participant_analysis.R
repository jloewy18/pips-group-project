# Participant-level statistics and t-tests for both tasks and their comparison.

# Standard error of the mean
sem = function(x) {
  return(sd(x) / sqrt(length(x)))
}

# Summary of given values (accuracy or RT) and one-sample t-test result
summarize_with_t = function(x, mu = 0) {
  return(list(
    mean = mean(x),
    sd = sd(x),
    sem = sem(x),
    ttest = t.test(x, mu = mu),
    all = x
  ))
}

# Results of awareness task
acc_results_aware = function(dat_aware) {
  # Mean accuracy per participant
  acc = tapply(dat_aware$correct, dat_aware$participant, mean)
  
  # Summary of results (one-sample t-test: accuracy sig. different from 0.5?)
  return(summarize_with_t(acc, mu = 0.5))
}

# Sensitivity results of awareness task
sens_results_aware = function(dat_aware) {
  conditions = sort(unique(dat_aware$condition))
  
  # Perform calculations for each participant
  parts = split(dat_aware, dat_aware$participant)
  ds = vapply(parts, function(dat) {
    # Accuracy per condition
    acc_A = dat$correct[dat$condition == conditions[1]]
    acc_B = dat$correct[dat$condition == conditions[2]]
    
    # Calculate hit and false alarm rates
    hit = mean(acc_A)
    fa = 1 - mean(acc_B)
    
    # Boundary corrections if hits/FAs are 0 or 1
    if (hit == 0)
      hit = 1 / length(acc_A)
    if (hit == 1)
      hit = 1 - 1 / length(acc_A)
    if (fa == 0)
      fa = 1 / length(acc_B)
    if (fa == 1)
      fa = 1 - 1 / length(acc_B)
    
    # Individual sensitivity
    qnorm(hit) - qnorm(fa)
  }, numeric(1))
  
  # Summarize t-test results
  return(summarize_with_t(ds, mu = 0))
}

processing_measures_process = function(dat_process) {
  conditions = sort(unique(dat_process$condition))
  
  # Perform calculations for each participant
  parts = split(dat_process, dat_process$participant)
  
  # Mean response in congruent and incongruent condition
  mean_con = vapply(parts, function(dat) {
    mean(dat$response[dat$condition == conditions[1]])
  }, numeric(1))
  mean_incon = vapply(parts, function(dat) {
    mean(dat$response[dat$condition == conditions[2]])
  }, numeric(1))
  
  return(list(
    mean_con = list(mean = mean(mean_con), all = mean_con),
    mean_incon = list(mean = mean(mean_incon), all = mean_incon),
    
    # One-sample t-test of difference in means between conditions to 0
    mean_diff = summarize_with_t(mean_incon - mean_con, mu = 0)
  ))
}

# SDT classification of correct/false based on above/below median
add_predictions_process = function(dat_process) {
  conditions = sort(unique(dat_process$condition))
  
  # Calculate median per participant
  dat_process$criterion = ave(dat_process$response, dat_process$participant, FUN = median)
  
  # Initially: Correct response if above median
  dat_process$correct = dat_process$response > dat_process$criterion
  
  # Correct classification if at or below median in congruent trials
  # and above median in incongruent trials
  congruent = dat_process$condition == conditions[1]
  dat_process$correct[congruent] = !dat_process$correct[congruent]
  dat_process
}

# Apply SDT classification to accuracy results of processing task
acc_results_process = function(dat_process) {
  acc_results_aware(add_predictions_process(dat_process))
}

# Apply SDT classification to sensitivity results of processing task
sens_results_process = function(dat_process) {
  sens_results_aware(add_predictions_process(dat_process))
}

add_results = function(experiment, dependent = TRUE) {
  if (!isTRUE(dependent)) {
    stop("This app version implements the supplied paired analysis only.")
  }
  
  # Error if participants are unequal between tasks
  ids_aware = sort(unique(experiment$dat_aware$participant))
  ids_process = sort(unique(experiment$dat_process$participant))
  if (!identical(ids_aware, ids_process)) {
    stop("The paired analysis requires the same participant IDs in both tasks.")
  }
  
  # Save all results for both tasks in lists
  experiment$results_aware = list(
    accuracy = acc_results_aware(experiment$dat_aware),
    sensitivity = sens_results_aware(experiment$dat_aware)
  )
  experiment$results_process = list(
    processingMeasure = processing_measures_process(experiment$dat_process),
    accuracy = acc_results_process(experiment$dat_process),
    sensitivity = sens_results_process(experiment$dat_process)
  )
  d_aware = experiment$results_aware$sensitivity$all
  d_process = experiment$results_process$sensitivity$all[names(d_aware)]
  a_aware = experiment$results_aware$accuracy$all
  a_process = experiment$results_process$accuracy$all[names(a_aware)]
  experiment$results_comparison = list(
    accuracy = summarize_with_t(a_process - a_aware, mu = 0),
    sensitivity = summarize_with_t(d_process - d_aware, mu = 0)
  )
  
  return(experiment)
}