# ------------------- ANALYSIS AND PLOT FUNCTIONS ------------------- #

# Question: does the "double t-test" give false evidence for unconscious processing?

# Two ways to claim that a prime was processed without being consciously seen:
# - Double t-test: processing test significant AND awareness test not significant.
#   Common in the literature, but "not significant" does not mean "no awareness".
# - Direct comparison: processing sensitivity significantly higher than awareness
#   sensitivity. This tests the claim itself (Meyen et al., 2022).

# We simulate many experiments with a known truth and count how often each method is right.
#
# Simulations are run with run_batch() (batch.R), the same pipeline as the app,
# so the analysis uses exactly the same tests and rules. Constants come from
# config.R and the base plot style from plot_theme.R.
# "settings" is a batch_settings() list; B = number of simulated experiments.


# ---- 1. Rates and tests ------------------------------------------------------

# Share of experiments in which each method claims unconscious processing.
# If the tasks are equally sensitive, every claim is wrong (false positive rate);
# if processing is truly more sensitive, every claim is right (detection rate).
# The 95% CI shows how precise the estimate is with this number of simulations.
# Input: the data of a run_batch() result (one row per experiment).
claim_rates <- function(study_results) {
  methods <- c(double_processing_advantage = "Double t-test",
               comparison_processing_advantage = "Direct comparison")
  
  rows <- lapply(names(methods), function(column) {
    n_claims <- sum(study_results[[column]])
    n_total  <- nrow(study_results)
    ci <- binom.test(n_claims, n_total)$conf.int      # exact CI for a proportion
    data.frame(method = methods[[column]],
               rate = n_claims / n_total,
               ci_low = ci[1],
               ci_high = ci[2])
  })
  do.call(rbind, rows)
}

# Power of each separate test (share of experiments where it is significant).
# Input: the data of a run_batch() result.
# Explains the double t-test: if awareness has less power than processing,
# "processing yes, awareness no" happens even when both are equally sensitive.
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

# Power of both tests across numbers of trials.
# Both tasks get the same trials and sensitivity, so the only thing that varies
# is the amount of data: this shows how much power depends on trial count.
# (K_values must be 50-500: run_batch() only accepts that many trials per task.)
power_by_trials <- function(settings, K_values = c(50, 100, 200, 400), n_reps = 200) {
  rows <- lapply(K_values, function(K) {
    par <- modifyList(settings, list(K_aware = K, K_process = K, B = n_reps))
    cbind(trials = K, test_power(run_batch(par)$data))
  })
  out <- do.call(rbind, rows)
  out$participants <- settings$N            # stored for the plot subtitle
  out$sensitivity  <- settings$delta_aware
  out
}

# Power of both tests across numbers of participants.
# Both tasks get the same number of trials, so the only thing that varies is the
# number of participants: this shows the effect of sample size on its own.
power_by_participants <- function(settings, N_values = c(5, 10, 20, 40), trials = 100,
                                  n_reps = 200) {
  rows <- lapply(N_values, function(n) {
    par <- modifyList(settings, list(N = n, K_aware = trials, K_process = trials, B = n_reps))
    cbind(participants = n, test_power(run_batch(par)$data))
  })
  out <- do.call(rbind, rows)
  out$trials      <- trials                 # stored for the plot subtitle
  out$sensitivity <- settings$delta_aware
  out
}

# Test 1: is the direct comparison valid?
# A valid method should not make more false claims than alpha (5%).
# One-sided, because only too many false claims would be a problem.
test_type1_error <- function(study_results, alpha = ALPHA) {
  binom.test(sum(study_results$comparison_processing_advantage),
             nrow(study_results), p = alpha, alternative = "greater")
}

# Test 2: does the double t-test make more false claims than the direct comparison?
# McNemar's test, because both methods judge the same experiments (paired data).
compare_methods <- function(study_results) {
  claims <- table(
    double_ttest = factor(study_results$double_processing_advantage, levels = c(FALSE, TRUE)),
    direct_comparison = factor(study_results$comparison_processing_advantage, levels = c(FALSE, TRUE))
  )
  mcnemar.test(claims)
}

# Test 3: does one study design detect real effects more often than another?
# Test of two proportions, because the designs are separate sets of experiments.
compare_designs <- function(results_a, results_b) {
  prop.test(x = c(sum(results_a$comparison_processing_advantage),
                  sum(results_b$comparison_processing_advantage)),
            n = c(nrow(results_a), nrow(results_b)))
}


# ---- 2. Plots ----------------------------------------------------------------

# Fixed colours, so each method/task looks the same in every figure.
# Task colours come from config.R, so they match the app.
method_colours <- c("Double t-test" = "#c0392b", "Direct comparison" = "#2471a3")
test_colours <- c("Awareness test" = COLS[["Awareness"]],
                  "Processing test" = COLS[["Processing"]])

# Figure 1: how often each method wrongly claims unconscious processing.
# The dashed line marks alpha, the error rate a valid method should stay under.
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
    plot_theme() +
    theme(panel.grid.major.x = element_blank(),
          axis.text.x = element_text(size = 12, colour = "grey15"))
}

# Figure 2: why the double t-test fails (cf. Meyen et al., 2022, Figure S3).
# Each point is one experiment. Points below the diagonal: processing gave the
# smaller p value despite equal sensitivity. Shaded area: the misleading pattern.
plot_p_value_scatter <- function(study_results, alpha = ALPHA) {
  share <- mean(study_results$double_processing_advantage)
  min_p <- min(c(study_results$p_awareness, study_results$p_processing))
  
  # readable p values on the axes, with alpha marked where the dashed lines are
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
    plot_theme()
}

# Figure 3: power of each test against the number of trials.
# Big points mark the typical design (few awareness trials, many processing trials),
# to show the power gap that typical studies build in.
# Log x-axis, because the number of trials doubles at each step.
plot_power_by_trials <- function(power_table, K_aware = 100, K_process = 400) {
  typical <- rbind(
    power_table[power_table$test == "Awareness test" & power_table$trials == K_aware, ],
    power_table[power_table$test == "Processing test" & power_table$trials == K_process, ]
  )
  typical$label <- paste0(typical$test, "\n", typical$trials, " trials: ",
                          scales::percent(typical$power, accuracy = 1))
  typical$hjust <- c(-0.12, 1.12)   # labels on opposite sides so they do not overlap
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
    plot_theme() +
    theme(legend.position = "top")
}

# Figure 4: power of each test against the number of participants (equal trials per task).
# Big points mark the typical sample size, to show where typical studies stand.
plot_power_by_participants <- function(power_table, N_typical = 10) {
  typical <- power_table[power_table$participants == N_typical, ]
  typical$label <- paste0(typical$test, "\n", N_typical, " participants: ",
                          scales::percent(typical$power, accuracy = 1))
  is_aware <- typical$test == "Awareness test"
  typical$hjust <- ifelse(is_aware, -0.12, 1.12)   # labels apart so they do not overlap
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
                       breaks = seq(0, 1, 0.25)) +   # room above 100% for the label
    scale_colour_manual(values = test_colours) +
    scale_fill_manual(values = test_colours) +
    labs(x = "Participants per task (log scale)",
         y = "Experiments where the test is significant (power)",
         colour = NULL, fill = NULL,
         title = "More participants increase the power of both tests",
         subtitle = paste0(unique(power_table$trials), " trials per participant in both tasks. ",
                           "Same true sensitivity (δ = ",
                           unique(power_table$sensitivity), ").\n",
                           "Big points: typical number of participants. Bands: 95% CI.")) +
    plot_theme() +
    theme(legend.position = "top")
}

# Figure 5: how often each method detects real unconscious processing, per design.
# Compares designs with the same total data, to show the best way to collect it.
# The dashed line marks 80% power, the usual target when planning a study.
plot_power_designs <- function(rate_list, settings, target_power = 0.8) {
  power <- do.call(rbind, lapply(names(rate_list), function(design) {
    cbind(rate_list[[design]], design = design)
  }))
  power$design <- factor(power$design, levels = names(rate_list))   # keep the given order
  
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
    plot_theme() +
    theme(legend.position = "top",
          panel.grid.major.x = element_blank(),
          axis.text.x = element_text(size = 11, colour = "grey15", lineheight = 1.1))
}


# Stop if any experiments in a batch failed.
require_complete_batch <- function(batch, label) {
  if (length(batch$errors) || nrow(batch$data) != batch$attempted) {
    stop(
      label, ": ",
      nrow(batch$data), " of ", batch$attempted,
      " experiments analysed. Check the batch errors."
    )
  }
  invisible(NULL)
}

# Format claim rates and confidence intervals for the report tables.
display_claim_rates <- function(rates, n_experiments) {
  data.frame(
    Method = rates$method,
    `Experiments claiming processing advantage` = sprintf(
      "%d / %d",
      as.integer(round(rates$rate * n_experiments)),
      n_experiments
    ),
    `Claim rate` = sprintf("%.1f%%", 100 * rates$rate),
    `95% CI (lower bound)` = sprintf("%.1f%%", 100 * rates$ci_low),
    `95% CI (upper bound)` = sprintf("%.1f%%", 100 * rates$ci_high),
    check.names = FALSE
  )
}