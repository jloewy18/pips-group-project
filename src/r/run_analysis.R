# ------------------- RUN PLOTS -------------------------------- #
# Makes the figures and tests, using the functions in src/r/plots.R.
# Run from the project folder (the folder that contains src/).

library(ggplot2)
source("src/r/load_all.R")   

source("src/r/analysis.R")      # my functions, loaded last so these are the ones used

n_reps <- 400   # simulated experiments per scenario (use 50 for a quick test)


# ==== Settings ====
# Arguments of run_simulation(). 100 awareness trials vs 400 processing trials,
# as in typical studies (Dehaene et al., 1998: 112 vs 512).
# Q2 (config.R) = 0.15^2 = variance of individual sensitivities, as in Meyen et al. (2022).
settings <- list(
  K_aware = 100,        # trials per participant in the awareness task
  K_process = 400,      # trials per participant in the processing task
  delta_aware = 0.25,   # true awareness sensitivity
  delta_process = 0.25, # true processing sensitivity (same as awareness)
  N = 10,               # participants (the same people do both tasks)
  q2 = Q2               # variance of individual sensitivities
)


# ==== Part A. The problem: false claims of unconscious processing ====
# Scenario 1: both tasks equally sensitive, so every claim is a false positive
results <- run_many_experiments(settings, n_reps = n_reps)
rates <- claim_rates(results)
rates

# Figure 1: the double t-test makes far more false claims than the direct comparison
plot_false_positives(rates, settings)

# Test 1: does the direct comparison stay at or below 5% false positives?
test_type1_error(results)

# Test 2: does the double t-test make significantly more false claims? (McNemar)
compare_methods(results)


# ==== Part B. Why: the awareness test has less power ====
# Figure 2: same sensitivity, but the processing test gives much smaller p values
plot_p_value_scatter(results)

# Figure 3: the awareness task has fewer trials, and so less power
power_trials <- power_by_trials(settings, n_reps = 200)
plot_power_by_trials(power_trials, K_aware = settings$K_aware, K_process = settings$K_process)

# Figure 4: more participants increase the power of both tests
power_people <- power_by_participants(settings, n_reps = 200)
plot_power_by_participants(power_people, N_typical = settings$N)


# ==== Part C. The solution: the direct comparison, with a good design ====
# Scenario 2: real unconscious processing (no awareness, processing stays 0.25)
settings_power <- modifyList(settings, list(delta_aware = 0))
results_power  <- run_many_experiments(settings_power, n_reps = n_reps)
rates_power    <- claim_rates(results_power)

# Scenario 3a: 4x more awareness trials (10 participants x 400 trials per task)
settings_trials <- modifyList(settings_power, list(K_aware = 400))
results_trials  <- run_many_experiments(settings_trials, n_reps = n_reps)
rates_trials    <- claim_rates(results_trials)

# Scenario 3b: 4x more participants (40 participants x 100 trials per task;
# same total number of trials as 3a)
settings_people <- modifyList(settings_power, list(N = 40, K_process = 100))
results_people  <- run_many_experiments(settings_people, n_reps = n_reps)
rates_people    <- claim_rates(results_people)

# Figure 5: detection rate of both methods for the three designs
# (the double t-test's high rate is no advantage: it also claims effects
# that do not exist, see Figure 1)
plot_power_designs(list(
  "Original design\n10 participants\nawareness: 100 trials\nprocessing: 400 trials"               = rates_power,
  "4x more awareness trials\n10 participants\nawareness: 400 trials\nprocessing: 400 trials"  = rates_trials,
  "4x more participants\n40 participants\nawareness: 100 trials\nprocessing: 100 trials"      = rates_people
), settings = settings_power)

# Test 3: for the same total data, do more participants detect more often than more trials?
compare_designs(results_people, results_trials)