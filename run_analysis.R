# ------------------- RUN ANALYSIS -------------------------------- #
# Runs all simulations, figures and tests (functions in src/r/analysis.R).
# Run from the project folder.

library(ggplot2)
source("src/r/load_all.R")   # simulation code (run_batch etc.) and analysis functions


n_reps <- 400   # how often each scenario is simulated. more = more precise percentages.



# ---- Settings ----
# A typical unconscious-priming study: few awareness trials, many processing trials
# (e.g. Dehaene et al., 1998: 112 vs 512). Both tasks equally sensitive, so any
# claim of unconscious processing is false. Q2 = 0.15^2: participants differ in
# sensitivity, as in Meyen et al. (2022).
settings <- batch_settings(
  K_aware = 100,        # trials per participant, awareness task
  K_process = 400,      # trials per participant, processing task
  delta_aware = 0.25,   # true awareness sensitivity
  delta_process = 0.25, # true processing sensitivity
  N = 10,               # participants (each does both tasks)
  q2 = Q2,              # variance of sensitivity between participants
  B = n_reps,           # number of simulated experiments
  seed = 2027           # fixed seed, so results are reproducible
)





# ---- PART A. THE PROBLEM: FALSE CLAIMS OF UNCONSCIOUS PROCESSING ----

results <- run_batch(settings)$data   # one row per simulated experiment
rates <- claim_rates(results)
rates

# Figure 1: the double t-test makes many false claims, the direct comparison does not.
plot_false_positives(rates, settings)

# Test 1: does the direct comparison stay at or below 5% false claims?
test_type1_error(results)

# Test 2: is the difference between the methods significant?
compare_methods(results)






# ---- PART B.WHY: THE AWARENESS TEST HAS LESS POWER ----

# Figure 2: equal sensitivity, yet the processing test gives much smaller p-values
plot_p_value_scatter(results)

# Figure 3: with fewer trials, the awareness test misses effects more often
power_trials <- power_by_trials(settings, n_reps = 200)
plot_power_by_trials(power_trials, K_aware = settings$K_aware, K_process = settings$K_process)

# Figure 4: more participants raise the power of both tests
# (same number of trials in both tasks, so only the number of participants varies)
power_people <- power_by_participants(settings, trials = 100, n_reps = 200)
plot_power_by_participants(power_people, N_typical = settings$N)







# ---- PART C. THE SOLUTION: THE DIRECT COMPARISON WITH A BETTER DESIGN ----

# Now there IS unconscious processing (awareness 0, processing 0.25), so we can
# check how often each method detects it.
settings_power <- modifyList(settings, list(delta_aware = 0))
results_power  <- run_batch(settings_power)$data
rates_power    <- claim_rates(results_power)

# Two ways to collect 4x more awareness data (same total trials, so a fair comparison):
# more trials per person...
settings_trials <- modifyList(settings_power, list(K_aware = 400))
results_trials  <- run_batch(settings_trials)$data
rates_trials    <- claim_rates(results_trials)

# ...or more people
settings_people <- modifyList(settings_power, list(N = 40, K_process = 100))
results_people  <- run_batch(settings_people)$data
rates_people    <- claim_rates(results_people)

# Figure 5: which design detects real effects best?
# The double t-test's high rate is no advantage: it also "detects" effects that do not exist (Figure 1).
plot_power_designs(list(
  "Original design\n10 participants\nawareness: 100 trials\nprocessing: 400 trials"           = rates_power,
  "4x more awareness trials\n10 participants\nawareness: 400 trials\nprocessing: 400 trials"  = rates_trials,
  "4x more participants\n40 participants\nawareness: 100 trials\nprocessing: 100 trials"      = rates_people
), settings = settings_power)

# Test 3: is "more participants" significantly better than "more trials"?
compare_designs(results_people, results_trials)
