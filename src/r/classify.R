# Turns one analysed experiment (the output of run_simulation()) into one row of
# outcome flags. Stops with an error if a required result is not finite.
# outcome: 1 = Both, 2 = Processing only, 3 = Awareness only, 4 = Neither
# (labels in OUTCOMES, see config.R)
classify_experiment = function(e,
                               experiment = NA_integer_,
                               alpha = ALPHA) {
  a = e$results_aware$accuracy
  r = e$results_process$processingMeasure$mean_diff
  d = e$results_comparison$sensitivity
  if (any(!is.finite(
    c(
      a$ttest$p.value,
      r$ttest$p.value,
      d$ttest$p.value,
      r$mean,
      d$mean
    )
  )))
    stop("Required results were not finite.")
  aware_sig = a$ttest$p.value < alpha
  process_sig = r$ttest$p.value < alpha && r$mean > 0
  outcome = if (process_sig &&
                aware_sig) {
    1L
  } else if (process_sig) {
    2L
  } else if (aware_sig) {
    3L
  } else {
    4L
  }
  data.frame(
    experiment = experiment,
    aware_sig = aware_sig,
    process_sig = process_sig,
    outcome = outcome,
    double_processing_advantage = process_sig && !aware_sig,
    comparison_processing_advantage = d$ttest$p.value < alpha && d$mean > 0
  )
}
