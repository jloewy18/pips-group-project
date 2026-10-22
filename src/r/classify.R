# Turn one analysed experiment into one row of outcome flags.

# Returns p values and significance of double t-test and direct comparison of d'.
classify_experiment = function(
    e,
    experiment = NA_integer_,
    alpha = ALPHA
) {
  is_finite_scalar = function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x)
  }
  
  # The significance threshold must lie strictly between 0 and 1.
  if (!is_finite_scalar(alpha) || alpha <= 0 || alpha >= 1)
    stop("alpha must be a finite number strictly between 0 and 1.")
  
  p_values = list(
    p_awareness = e$results_aware$accuracy$ttest$p.value,
    p_processing = e$results_process$processingMeasure$mean_diff$ttest$p.value,
    p_comparison = e$results_comparison$sensitivity$ttest$p.value
  )
  
  # A list preserves missing NULL values so validation can detect them.
  valid = vapply(p_values, function(x) {
    is_finite_scalar(x) && x >= 0 && x <= 1
  }, logical(1))
  
  if (!all(valid))
    stop("Required p-values must be finite numeric scalars from 0 to 1: ",
         paste(names(p_values)[!valid], collapse = ", "))
  
  aware_sig = p_values$p_awareness < alpha
  process_sig = p_values$p_processing < alpha
  comparison_sig = p_values$p_comparison < alpha
  
  # Double t-test categories, in the order defined by OUTCOMES.
  outcome = if (process_sig && aware_sig) {
    1L  # Both.
  } else if (process_sig) {
    2L  # Processing only.
  } else if (aware_sig) {
    3L  # Awareness only.
  } else {
    4L  # Neither.
  }
  
  data.frame(
    experiment = experiment,
    aware_sig = aware_sig,
    process_sig = process_sig,
    outcome = outcome,
    double_processing_advantage = process_sig && !aware_sig,
    comparison_processing_advantage = comparison_sig,
    p_awareness = p_values$p_awareness,
    p_processing = p_values$p_processing,
    p_comparison = p_values$p_comparison
  )
}