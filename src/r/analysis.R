# ------------------- FUNCTIONS -------------------------------- # 

# calculates how often each method claims unconscious processing.
    #  returns the false positive rate when both tasks are equally sensitive,
    # and the power when processing is truly more sensitive.
claim_rates <- function(study_results) {
  methods <- c(double_processing_advantage = "Double t-test",
               comparison_processing_advantage = "Direct comparison")
  
  rows <- lapply(names(methods), function(column) {
    n_claims <- sum(study_results[[column]])          # how many TRUEs
    n_total  <- nrow(study_results)                   # how many experiments
    ci <- binom.test(n_claims, n_total)$conf.int      # 95% CI for the proportion
    data.frame(method = methods[[column]],
               rate = n_claims / n_total,
               ci_low = ci[1],
               ci_high = ci[2])
  })
  do.call(rbind, rows)
}


# combines the claim rates of several scenarios into one table for plotting.
    # output: one table with the rates of all scenarios, labelled by scenario and measure (false positives and power).
combine_scenarios <- function(rate_list, measures) {
  if (length(rate_list) != length(measures)) {
    stop("rate_list and measures must have the same length.")
  }
  combined <- do.call(rbind, lapply(seq_along(rate_list), function(i) {
    cbind(rate_list[[i]], scenario = names(rate_list)[i], measure = measures[i])
  }))
  combined$scenario <- factor(combined$scenario, levels = names(rate_list))
  combined$measure <- factor(combined$measure, levels = c("False positives", "Power"))
  combined
}


# bar plot comparing false positive rates and power for all scenarios
plot_scenarios <- function(combined, alpha = 0.05, target_power = 0.8) {
  reference <- data.frame(measure = factor(c("False positives", "Power"),
                                           levels = levels(combined$measure)),
                          y = c(alpha, target_power))
  ggplot(combined, aes(scenario, rate, fill = method)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.7) +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                  position = position_dodge(width = 0.75), width = 0.2) +
    geom_hline(data = reference, aes(yintercept = y),
               linetype = "dashed", colour = "grey40") +
    facet_grid(~ measure, scales = "free_x", space = "free_x") +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    scale_fill_manual(values = c("Double t-test" = "#c0392b",
                                 "Direct comparison" = "#2471a3")) +
    labs(x = NULL, y = "Simulated experiments with a claim", fill = NULL,
         title = "double t-test vs direct comparison claims",
         subtitle = "Error bars: 95% CI. Dashed lines: 5% false positives, 80% power.") +
    theme_minimal(base_size = 13) +
    theme(legend.position = "top")
}


# test whether the direct comparison keeps false positives at alpha
test_type1_error <- function(study_results, alpha = 0.05) {
  binom.test(sum(study_results$comparison_processing_advantage),
             nrow(study_results), p = alpha)
}


# Tests whether the two methods differ in how often they claim unconscious processing.
# Compare the claims of the two methods with McNemar's test (both methods are applied to the same experiments).
compare_methods <- function(study_results) {
  claims <- table(
    double_ttest = factor(study_results$double_processing_advantage, levels = c(FALSE, TRUE)),
    direct_comparison = factor(study_results$comparison_processing_advantage, levels = c(FALSE, TRUE))
  )
  mcnemar.test(claims)
}

# scatter plot showing why the double t-test fails (cf. Meyen et al., 2022, Figure S3).
    # each point is one simulated experiment: awareness p-value (x) vs processing p-value (y).
    # the shaded area marks the misleading pattern: processing significant, awareness not.
      # input: the results of run_scenario() and alpha (significance level).
plot_p_value_scatter <- function(study_results, alpha = 0.05) {
  share <- mean(study_results$double_processing_advantage)
  min_p <- min(c(study_results$p_awareness, study_results$p_processing))
  
  ggplot(study_results, aes(p_awareness, p_processing)) +
    annotate("rect", xmin = alpha, xmax = 1, ymin = min_p, ymax = alpha,
             fill = "#c0392b", alpha = 0.12) +
    geom_abline(slope = 1, intercept = 0, colour = "grey50") +
    geom_vline(xintercept = alpha, linetype = "dashed", colour = "grey40") +
    geom_hline(yintercept = alpha, linetype = "dashed", colour = "grey40") +
    geom_point(alpha = 0.35, size = 1.3, colour = "#34495e") +
    annotate("text", x = 1, y = min_p, hjust = 1, vjust = -0.5, size = 4,
             colour = "#c0392b",
             label = paste0("Misleading pattern: ", scales::percent(share, 0.1))) +
    scale_x_log10(labels = scales::label_log()) +
    scale_y_log10(labels = scales::label_log()) +
    labs(x = "p-value of the awareness test",
         y = "p-value of the processing test",
         title = "Same sensitivity, very different p-values",
         subtitle = "Each point is one simulated experiment. Grey line: equal p-values.") +
    theme_minimal(base_size = 13)
}

