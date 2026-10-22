# ------------------- PLOT AND ANALYSIS FUNCTIONS (plots.R) ------------------- #
# Compares two ways of testing for unconscious processing (Meyen et al., 2022):
# - the double t-test: processing significant (and positive) AND awareness not significant
# - the direct comparison: processing sensitivity significantly higher than awareness sensitivity
#
# Uses run_simulation() and classify_experiment() from the simulation code, so the
# analysis uses exactly the same tests and rules as the app, and ALPHA, Q2 and
# COLS from config.R.
# Load it AFTER load_all.R (run_plots.R does this), so these functions are the
# ones that are used. ggplot2 must be loaded.
#
# "settings" is a list with the arguments of run_simulation():
# K_aware, K_process, delta_aware, delta_process, N and q2.


# ---- 1. Simulating -----------------------------------------------------------

# repeats one simulated experiment many times with the same settings.
# each experiment is simulated with run_simulation() and classified with
# classify_experiment() (same rules as the app). the three p-values are added,
# because the scatter plot needs them.
# input: settings (arguments of run_simulation()), n_reps (number of simulated
# experiments), seed (fixes the random numbers) and alpha (significance level)
# output: a data frame with one row per experiment: whether each test is
# significant, whether each method claims unconscious processing, and the p-values
run_many_experiments <- function(settings, n_reps = 1000, seed = 2027, alpha = ALPHA) {
  if (n_reps < 10) stop("n_reps should be at least 10 to estimate rates.")
  set.seed(seed)
  do.call(rbind, lapply(seq_len(n_reps), function(i) {
    experiment <- do.call(run_simulation, settings)
    row <- classify_experiment(experiment, experiment = i, alpha = alpha)
    row$p_awareness  <- experiment$results_aware$accuracy$ttest$p.value
    row$p_processing <- experiment$results_process$processingMeasure$mean_diff$ttest$p.value
    row$p_comparison <- experiment$results_comparison$sensitivity$ttest$p.value
    row
  }))
}


# ---- 2. Rates and tests ------------------------------------------------------

# calculates how often each method claims unconscious processing.
# this is the false positive rate when both tasks are equally sensitive,
# and the detection rate when processing is truly more sensitive.
# input: results of run_many_experiments()
# output: one row per method: proportion of experiments with a claim and its 95% CI
claim_rates <- function(study_results) {
  methods <- c(double_processing_advantage = "Double t-test",
               comparison_processing_advantage = "Direct comparison")
  
  rows <- lapply(names(methods), function(column) {
    n_claims <- sum(study_results[[column]])          # how many TRUEs
    n_total  <- nrow(study_results)                   # how many experiments
    ci <- binom.test(n_claims, n_total)$conf.int      # 95% CI for a proportion
    data.frame(method = methods[[column]],
               rate = n_claims / n_total,
               ci_low = ci[1],
               ci_high = ci[2])
  })
  do.call(rbind, rows)
}

# power of each separate test: how often it is significant, with a 95% CI
# (uses aware_sig and process_sig from classify_experiment())
# input: results of run_many_experiments()
# output: one row per test: test, power, ci_low, ci_high
test_power <- function(study_results) {
  tests <- c(aware_sig = "Awareness test", process_sig = "Processing test")
  rows <- lapply(names(tests), function(column) {
    n_sig <- sum(study_results[[column]])
    ci <- binom.test(n_sig, nrow(study_results))$conf.int
    data.frame(test = tests[[column]], power = n_sig / nrow(study_results),
               ci_low = ci[1], ci_high = ci[2])
  })
  do.call(rbind, rows)
}

# power of each test for different numbers of trials.
# both tasks get the same number of trials (and the same sensitivity, from settings),
# so any difference in power comes from the tests themselves.
# input: settings, K_values (trials per task to try), n_reps and seed
# output: test_power() rows for every K, plus the participants and sensitivity used
power_by_trials <- function(settings, K_values = c(50, 100, 200, 400, 800),
                            n_reps = 200, seed = 2027) {
  rows <- lapply(K_values, function(K) {
    par <- modifyList(settings, list(K_aware = K, K_process = K))
    cbind(trials = K, test_power(run_many_experiments(par, n_reps = n_reps, seed = seed)))
  })
  out <- do.call(rbind, rows)
  out$participants <- settings$N            # kept for the plot subtitle
  out$sensitivity  <- settings$delta_aware
  out
}

# power of each test for different numbers of participants.
# the number of trials stays as in settings (usually fewer for awareness).
# input: settings, N_values (participants to try), n_reps and seed
# output: test_power() rows for every N, plus the trials and sensitivity used
power_by_participants <- function(settings, N_values = c(5, 10, 20, 40),
                                  n_reps = 200, seed = 2027) {
  rows <- lapply(N_values, function(n) {
    par <- modifyList(settings, list(N = n))
    cbind(participants = n, test_power(run_many_experiments(par, n_reps = n_reps, seed = seed)))
  })
  out <- do.call(rbind, rows)
  out$trials_aware   <- settings$K_aware    # kept for the plot subtitle
  out$trials_process <- settings$K_process
  out$sensitivity    <- settings$delta_aware
  out
}

# test 1: does the direct comparison make more false claims than alpha allows?
# exact binomial test (one-sided: a valid test should not go above alpha).
# input: results of run_many_experiments() for a scenario with no true difference
# output: the test result (non-significant = the method is valid)
test_type1_error <- function(study_results, alpha = ALPHA) {
  binom.test(sum(study_results$comparison_processing_advantage),
             nrow(study_results), p = alpha, alternative = "greater")
}

# test 2: do the two methods differ in how often they claim unconscious processing?
# McNemar's test, because both methods are applied to the same experiments (paired).
# input: results of run_many_experiments()
# output: the test result
compare_methods <- function(study_results) {
  claims <- table(
    double_ttest = factor(study_results$double_processing_advantage, levels = c(FALSE, TRUE)),
    direct_comparison = factor(study_results$comparison_processing_advantage, levels = c(FALSE, TRUE))
  )
  mcnemar.test(claims)
}

# test 3: does the direct comparison detect more often in one design than in another?
# two-sample test of proportions, because the designs were simulated separately.
# input: results of run_many_experiments() for two designs
# output: the test result
compare_designs <- function(results_a, results_b) {
  prop.test(x = c(sum(results_a$comparison_processing_advantage),
                  sum(results_b$comparison_processing_advantage)),
            n = c(nrow(results_a), nrow(results_b)))
}


# ---- 3. Plots ----------------------------------------------------------------

# colours used in every plot: one per method, and the app's colours per task
method_colours <- c("Double t-test" = "#c0392b", "Direct comparison" = "#2471a3")
test_colours <- c("Awareness test" = COLS[["Awareness"]],
                  "Processing test" = COLS[["Processing"]])

# figure 1: bar plot of how often each method wrongly claims unconscious processing
# input: claim_rates() output for a scenario without a true difference, settings
# (shown in the subtitle) and alpha (acceptable false positive rate, dashed line)
# output: a ggplot object
plot_false_positives <- function(rates, settings, alpha = ALPHA) {
  ggplot(rates, aes(method, rate, fill = method)) +
    geom_col(width = 0.6) +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.15, colour = "grey30") +
    geom_text(aes(y = ci_high, label = scales::percent(rate, accuracy = 0.1)),
              vjust = -0.6, size = 4.5, fontface = "bold", colour = "grey15") +
    geom_hline(yintercept = alpha, linetype = "dashed", colour = "grey40") +
    annotate("text", x = 0.45, y = alpha,
             label = paste0("acceptable: ", scales::percent(alpha)),
             hjust = 0, vjust = -0.5, size = 3.8, colour = "grey30") +
    scale_y_continuous(labels = scales::percent, limits = c(0, 0.5),
                       breaks = seq(0, 0.5, 0.1)) +
    scale_fill_manual(values = method_colours, guide = "none") +
    labs(x = NULL,
         y = "Experiments that wrongly claim unconscious processing",
         title = "False claims of unconscious processing",
         subtitle = paste0("Both tasks equally sensitive (δ = ", settings$delta_aware,
                           "). Error bars: 95% CI.\n",
                           settings$N, " participants; ",
                           settings$K_aware, " awareness / ", settings$K_process,
                           " processing trials.")) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          axis.text.x = element_text(size = 13, colour = "grey15"),
          plot.title = element_text(face = "bold"))
}

# figure 2: scatter plot showing why the double t-test fails (cf. Meyen et al., 2022, Figure S3).
# each point is one simulated experiment: awareness p value (x) vs processing p value (y).
# the shaded area marks the misleading pattern: processing significant, awareness not.
# input: results of run_many_experiments() and alpha (significance level)
# output: a ggplot object
plot_p_value_scatter <- function(study_results, alpha = ALPHA) {
  share <- mean(study_results$double_processing_advantage)
  min_p <- min(c(study_results$p_awareness, study_results$p_processing))
  
  # axis ticks as normal p values, plus alpha where the dashed lines are
  p_breaks <- c(0.000001, 0.0001, 0.01, alpha, 1)
  p_labels <- c("0.000001", "0.0001", "0.01", paste0("α = ", alpha), "1")
  
  ggplot(study_results, aes(p_awareness, p_processing)) +
    annotate("rect", xmin = alpha, xmax = 1, ymin = min_p, ymax = alpha,
             fill = method_colours[["Double t-test"]], alpha = 0.12) +
    geom_abline(slope = 1, intercept = 0, colour = "grey50") +
    geom_vline(xintercept = alpha, linetype = "dashed", colour = "grey40") +
    geom_hline(yintercept = alpha, linetype = "dashed", colour = "grey40") +
    geom_point(alpha = 0.35, size = 1.3, colour = "#34495e") +
    annotate("text", x = 1, y = min_p, hjust = 1, vjust = -0.5, size = 4,
             colour = method_colours[["Double t-test"]],
             label = paste0("Misleading pattern: ", scales::percent(share, 0.1))) +
    scale_x_log10(breaks = p_breaks, labels = p_labels) +
    scale_y_log10(breaks = p_breaks, labels = p_labels) +
    labs(x = "p value of the awareness test (log scale)",
         y = "p value of the processing test (log scale)",
         title = "Same sensitivity, very different p values",
         subtitle = "Each point is one simulated experiment. Grey line: equal p values.") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"))
}

# figure 3: line plot of the power of each test against the number of trials,
# with the typical design of each task marked
# input: power_by_trials() output, and the trials typically used in each task
# (K_aware, K_process), which are marked with a big point
# output: a ggplot object
plot_power_by_trials <- function(power_table, K_aware = 100, K_process = 400) {
  # the typical design: awareness at K_aware trials, processing at K_process trials
  typical <- rbind(
    power_table[power_table$test == "Awareness test" & power_table$trials == K_aware, ],
    power_table[power_table$test == "Processing test" & power_table$trials == K_process, ]
  )
  typical$label <- paste0(typical$test, "\n", typical$trials, " trials: ",
                          scales::percent(typical$power, accuracy = 1))
  typical$hjust <- c(-0.12, 1.12)   # awareness label to the right, processing to the left
  typical$vjust <- c(1.1, 1.6)
  
  ggplot(power_table, aes(trials, power, colour = test, fill = test)) +
    geom_hline(yintercept = 0.8, linetype = "dashed", colour = "grey40") +
    annotate("text", x = min(power_table$trials), y = 0.8, label = "80% power",
             hjust = 0, vjust = -0.5, size = 3.8, colour = "grey30") +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, colour = NA) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    geom_point(data = typical, size = 5, shape = 21, colour = "white", stroke = 1.5) +
    geom_text(data = typical, aes(label = label, hjust = hjust, vjust = vjust),
              size = 3.8, fontface = "bold", show.legend = FALSE) +
    scale_x_log10(breaks = unique(power_table$trials)) +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1.02)) +
    scale_colour_manual(values = test_colours) +
    scale_fill_manual(values = test_colours) +
    labs(x = "Trials per participant (log scale)",
         y = "Experiments where the test is significant (power)",
         colour = NULL, fill = NULL,
         title = "The awareness task usually has fewer trials, and so less power",
         subtitle = paste0(unique(power_table$participants), " participants per task. ",
                           "Same true sensitivity in both tasks (δ = ",
                           unique(power_table$sensitivity), ").\n",
                           "Big points: number of trials in typical design. Bands: 95% CI.")) +
    theme_minimal(base_size = 13) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"))
}

# figure 4: line plot of the power of each test against the number of participants,
# with the typical design marked
# input: power_by_participants() output, and the typical number of participants
# (N_typical), which is marked with a big point
# output: a ggplot object
plot_power_by_participants <- function(power_table, N_typical = 10) {
  # the typical design: both tasks at N_typical participants
  typical <- power_table[power_table$participants == N_typical, ]
  typical$label <- paste0(typical$test, "\n", N_typical, " participants: ",
                          scales::percent(typical$power, accuracy = 1))
  # awareness label to the right and below, processing label to the left and above
  is_aware <- typical$test == "Awareness test"
  typical$hjust <- ifelse(is_aware, -0.12, 1.12)
  typical$vjust <- ifelse(is_aware, 1.1, -0.3)
  
  ggplot(power_table, aes(participants, power, colour = test, fill = test)) +
    geom_hline(yintercept = 0.8, linetype = "dashed", colour = "grey40") +
    annotate("text", x = max(power_table$participants), y = 0.8, label = "80% power",
             hjust = 1, vjust = 1.6, size = 3.8, colour = "grey30") +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, colour = NA) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    geom_point(data = typical, size = 5, shape = 21, colour = "white", stroke = 1.5) +
    geom_text(data = typical, aes(label = label, hjust = hjust, vjust = vjust),
              size = 3.8, fontface = "bold", show.legend = FALSE) +
    scale_x_log10(breaks = unique(power_table$participants)) +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1.12),
                       breaks = seq(0, 1, 0.25)) +   # extra room on top for the label
    scale_colour_manual(values = test_colours) +
    scale_fill_manual(values = test_colours) +
    labs(x = "Participants per task (log scale)",
         y = "Experiments where the test is significant (power)",
         colour = NULL, fill = NULL,
         title = "More participants increase the power of both tests",
         subtitle = paste0(unique(power_table$trials_aware), " awareness trials and ",
                           unique(power_table$trials_process), " processing trials per participant. ",
                           "Same true sensitivity (δ = ",
                           unique(power_table$sensitivity), ").\n",
                           "Big points: typical design. Bands: 95% CI.")) +
    theme_minimal(base_size = 13) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"))
}

# figure 5: bar plot of how often both methods detect real unconscious processing,
# for different study designs
# input: a named list of claim_rates() outputs, one per design with real
# unconscious processing (the names become the bar labels), settings (the true
# sensitivities, shown in the subtitle) and target_power (dashed line)
# output: a ggplot object
plot_power_designs <- function(rate_list, settings, target_power = 0.8) {
  power <- do.call(rbind, lapply(names(rate_list), function(design) {
    cbind(rate_list[[design]], design = design)
  }))
  power$design <- factor(power$design, levels = names(rate_list))
  
  ggplot(power, aes(design, rate, fill = method)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.75) +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                  position = position_dodge(width = 0.8), width = 0.2,
                  colour = "grey30") +
    geom_text(aes(y = ci_high, label = scales::percent(rate, accuracy = 1)),
              position = position_dodge(width = 0.8), vjust = -0.6,
              size = 4.2, fontface = "bold", colour = "grey15") +
    geom_hline(yintercept = target_power, linetype = "dashed", colour = "grey40") +
    annotate("text", x = 0.45, y = target_power, label = "80% power",
             hjust = 0, vjust = -0.5, size = 3.8, colour = "grey30") +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1.08),
                       breaks = seq(0, 1, 0.25)) +
    scale_fill_manual(values = method_colours) +
    labs(x = NULL,
         y = "Experiments that detect unconscious processing",
         fill = NULL,
         title = "Detection rate of each method for different study designs",
         subtitle = paste0("Real unconscious processing (awareness δ = ",
                           settings$delta_aware, ", processing δ = ",
                           settings$delta_process, "). Error bars: 95% CI.")) +
    theme_minimal(base_size = 13) +
    theme(legend.position = "top",
          panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          axis.text.x = element_text(size = 11.5, colour = "grey15", lineheight = 1.1),
          plot.title = element_text(face = "bold"))
}