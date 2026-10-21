# pips-group-project
This repository contains an R-based simulation project developed for the Programming
in Psychological Science course of the Research Master Psychology at the University of Amsterdam.

The project investigates how two statistical approaches perform when comparing 
sensitivity in awareness and processing tasks: the double t-test approach and
the direct comparison of sensitivities. By simulating repeated experiments 
under different conditions, we examine how often each approach identifies a processing 
advantage, including false-positive rates and statistical power.

The repository also includes an interactive Shiny app that allows users to explore how experimental parameters affect the results of the two approaches.

## Getting started

### Requirements

- R (use a recent version compatible with the packages used in the project).
- RStudio is recommended.
- The `knitr` and `rmarkdown` packages are required to knit the main report.

Install the packages for the report with:

```r
install.packages(c("knitr", "rmarkdown"))
```

### Open the project

1. Clone or download this repository.
2. Open `pips-group-project.Rproj` in RStudio.
3. Open `main.Rmd`.
4. Knit the document to generate the HTML report.

The report loads the required R scripts through `src/r/load_all.R`. Follow the 
instructions in the report to run simulations, inspect the analyses, and interpret the results.

## Repository structure

```text
pips-group-project/
├── data/                         # Saved simulation results and raw data
├── src/
│   └── r/
│       ├── dependencies.R        # Checks and loads required packages
│       ├── config.R              # Shared settings and constants
│       ├── plot_theme.R          # Shared ggplot theme
│       ├── io.R                  # Saves and loads simulation results
│       ├── simulate.R            # Simulates participant responses
│       ├── participant_analysis.R# Implements the analysis approaches
│       ├── run_simulation.R      # Runs one simulated experiment
│       ├── classify.R            # Classifies analysis outcomes
│       ├── batch.R               # Repeats simulations and collects results
│       ├── analysis.R             # Additional statistical analyses and plots
│       ├── shiny_app.R            # Interactive Shiny app
│       └── load_all.R             # Loads project scripts in order
├── main.Rmd                      # Main report and analysis workflow
├── README.md 
└── pips-group-project.Rproj       # RStudio project file
```

## How the project works

The project follows a workflow from data simulation to statistical analysis and visualisation.

1. **Load the code.** `load_all.R` loads the required dependencies, settings, and functions.
2. **Simulate one experiment.** `run_simulation()` generates participant data for
the awareness and processing tasks and applies the analysis methods.
3. **Classify the results.** `classify_experiment()` classifies the outcomes of 
the analyses.
4. **Repeat the simulations.** `run_batch()` runs multiple simulated experiments 
and collects the results.
5. **Analyse and visualise the outcomes.** The analysis functions calculate claim
rates, confidence intervals, statistical tests, and figures.
6. **Save and reuse results.** The functions in `io.R` save batch results and raw
simulated data in CSV and RDS formats.
7. **Explore the results interactively.** The Shiny app lets users change simulation
settings and observe how the two approaches perform across repeated experiments.

## Running the simulation

Open the project in RStudio and run the following commands from the repository root:

```r
source("src/r/load_all.R")
```

To run a single simulated experiment, use `run_simulation()` with the required 
parameter settings. To run repeated experiments, configure the settings with 
`batch_settings()` and pass them to `run_batch()`.

For example:

```r
settings <- batch_settings(
  K_aware = 100,
  K_process = 400,
  delta_aware = 0.25,
  delta_process = 0.25,
  N = 10,
  B = 100,
  seed = 2026
)

results <- run_batch(settings)
```

The settings control the number of trials in each task, the assumed population 
sensitivities, the number of participants, the number of simulated experiments, 
and the random seed. The random seed makes the simulation reproducible when the 
same settings and code are used.

## Running the Shiny app

The interactive app allows users to adjust simulation parameters and compare the
outcomes of the two statistical approaches.

Run:

```r
source("src/r/load_all.R")
run_app()
```

The app displays the assumed population sensitivities, the results of repeated 
simulations, and visualisations of the classifications produced by each approach. 
Stop the app when you have finished exploring it.

## Saving and loading results

The functions in `io.R` allow simulation results to be saved and reused.

Save the results of a batch:

```r
save_batch(results, name = "example_batch")
```

This saves the batch result as an RDS file and the successful experiment-level
results as a CSV file in the `data/` directory.

To load the saved batch:

```r
saved_results <- load_batch("example_batch")
```

Raw data from an individual experiment can also be saved using `save_experiment()`
and retrieved using `load_experiment()`.

## Main research question

The project examines whether the double t-test and direct comparison of sensitivities
lead to different conclusions about processing advantages.

The double t-test evaluates evidence from separate tests, whereas direct comparison
evaluates the difference between the estimated sensitivities themselves. Comparing 
these approaches across simulated conditions helps us investigate the risk of false-positive
conclusions and the influence of experimental design on statistical power.

The report presents the scenarios, figures, statistical tests, and interpretations 
used to address this research question.


## References
Meyen, S., Zerweck, I. A., Amado, C., von Luxburg, U., & Franz, V. H. (2022). 
Advancing research on unconscious priming: When can scientists claim an indirect 
task advantage? Journal of Experimental Psychology: General, 151(1), 65–81. 
https://doi.org/10.1037/xge0001065 

Shanks, D. R. (2016). Regressive research: The pitfalls of post hoc data selection
in the study of Unconscious Mental Processes. Psychonomic Bulletin &amp; Review, 
24(3), 752–775. https://doi.org/10.3758/s13423-016-1170-y 

Stein, T., van Gaal, S., & Fahrenfort, J. (2023). How (Not) to Demonstrate Unconscious
Priming:Overcoming Issues with Post-Hoc Data Selection, Low Power, and Frequentist
Statistics. https://doi.org/10.2139/ssrn.4573995 


