# Load my groupmate's simulation code
library(ggplot2)
source("src/r/load_all.R")


# Settings for one fake experiment
exp_par <- list(
  delta_aware = 0.25,   # true awareness sensitivity
  N_aware = 10,         # participants in the awareness task
  K_aware = 100,        # trials per participant in the awareness task
  q2_aware = 0.0225,    # how much participants differ in awareness
  delta_process = 0.25, # true processing sensitivity (same as awareness!)
  N_process = 10,       # participants in the processing task
  K_process = 400,      # trials per participant in the processing task
  q2_process = 0.0225   # how much participants differ in processing
)

# Run one fake experiment and its statistical tests
experiment <- add_results(sim_exp(exp_par))

# The three p-values
experiment$results_aware$accuracy$ttest$p.value                      # awareness test
experiment$results_process$processingMeasure$mean_diff$ttest$p.value # processing test
experiment$results_comparison$sensitivity$ttest$p.value         # direct comparison


# using the previous function with random data
run_one_experiment(exp_par)


# repeats the experiment many times
results <- run_scenario(exp_par, n_reps = 400)
results

# run the following lines to see how often is each test significant
mean(results$p_awareness  < 0.05)  # awareness significant in ~67% of experiments
mean(results$p_processing < 0.05)   # processing significant in ~97% of experiments
mean(results$p_comparison < 0.05)   # comparison significant in ~5% of experiments

# Notes:
# - q2 is a VARIANCE in sim_aware()/sim_process() (sd = sqrt(q2)), so we use
#   q2 = 0.0225 (SD = 0.15), as in Meyen et al. (2022).
# - Same true sensitivity in both tasks, but processing is significant far
#   more often than awareness, because it averages over more trials.
# - The direct comparison stays at the 5% expected under no true difference.



# ---- Scenario 1: no unconscious processing (awareness = processing = 0.25) ----
# Every claim is a false positive, so the claim rate = false positive rate.
rates <- claim_rates(results)
rates # Results when both tasks are equally sensitive and therefore FALSE (you can change the set up in exp_par)
#Double t-test: 31.5% false positives, TOO MANY
#Direct comparison: 5% false positives, exactly what a valid test should have.


# ---- Scenario 2: real unconscious processing (awareness weaker than processing) ----
exp_par_power <- exp_par          # copy all the original settings
exp_par_power$delta_aware <- 0    # change only this: no awareness at all
# (processing stays at 0.25)

results_power <- run_scenario(exp_par_power, n_reps = 400)
rates_power <- claim_rates(results_power)
rates_power # Double t-test: 90.8% [87.5, 93.4]; direct comparison: 49.5% [44.5, 54.5].
# The double t-test's high "power" is not an advantage: it also makes 31.5%
# false claims in Scenario 1. The direct comparison is valid but underpowered,
# because the awareness task has few trials (K = 100) and participants (N = 10).

# ---- Scenario 3: better designs (real unconscious processing) ----

# 3a: more awareness trials (same number of participants)
exp_par_trials <- exp_par_power
exp_par_trials$K_aware <- 400

results_trials <- run_scenario(exp_par_trials, n_reps = 400)
rates_trials <- claim_rates(results_trials)
rates_trials

# 3b: more participants (same TOTAL number of trials as 3a in both tasks)
exp_par_people <- exp_par_power
exp_par_people$N_aware   <- 40
exp_par_people$N_process <- 40    # must equal N_aware
exp_par_people$K_process <- 100   # 40 x 100 = 4,000 processing trials, same as 10 x 400

results_people <- run_scenario(exp_par_people, n_reps = 400)
rates_people <- claim_rates(results_people)
rates_people

# Scenario 3 (real unconscious processing), power of the direct comparison:
# Original (N = 10, K_aware = 100, K_process = 400): 49.5%
# 3a more trials (N = 10, K_aware = 400, K_process = 400): 71.3%
# 3b more participants (N = 40, K_aware = 100, K_process = 100; same total trials as 3a): 96.0%
# For the same total data, more participants is better than more trials (cf. Meyen et al., 2022).
# Both designs collect the same total number of trials (4,000 per task).
# Spreading them over more participants (40 x 100) gave much more power
# than giving fewer participants more trials (10 x 400): 96% vs 71%.
# Same conclusion as Meyen et al. (2022).




# bar plot
all_rates <- combine_scenarios(
  list("1: Equal\nsensitivity"   = rates,
       "2: Original\ndesign"     = rates_power,
       "3a: More\ntrials"        = rates_trials,
       "3b: More\nparticipants"  = rates_people),
  measures = c("False positives", "Power", "Power", "Power")
)

plot_scenarios(all_rates)


# test 1: is the direct comparison valid? 
test_type1_error(results)
# When awareness and processing were equally sensitive, the direct comparison falsely 
# detected a difference in 5.0% of simulated experiments (95% CI [3.1, 7.6]), which did 
# not differ from the nominal 5% level (exact binomial test, p = 1.00).

# test 2: does the double t-test make more false claims?
compare_methods(results)
# The double t-test falsely concluded unconscious processing in 31.5% of experiments (95% CI [27.0, 36.3]),
# significantly more often than the direct comparison (McNemar’s χ²(1) = 83.52, p < .001).

# test 3: do more participants really beat more trials?
prop.test(
  x = c(sum(results_people$claim_direct_comparison),   # claims in 3b
        sum(results_trials$claim_direct_comparison)),  # claims in 3a
  n = c(nrow(results_people), nrow(results_trials))    # experiments in each
)
# With the same total number of trials, testing more participants (N = 40, 100 trials each)
# gave the direct comparison substantially more power than testing fewer participants with 
# more trials (N = 10, 400 trials each): 96.0% vs. 71.3%, a difference of 24.8 percentage
# points (95% CI [19.7, 29.8]; χ²(1) = 87.67, p < .001).



# Scatter plot of awareness vs processing p-values (cf. Meyen et al., Figure S3).
plot_p_value_scatter(results)

# this figure shows why the double t-test fails. Although both tasks were simulated with the
# same sensitivity, the processing test yielded much smaller p-values than the awareness
# test in most experiments (points below the diagonal), because it averages over more 
# trials. In 31.5% of experiments, processing was significant while awareness was not
# (shaded area), the pattern that is commonly interpreted as evidence for unconscious processing.

