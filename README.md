# Unconscious Priming: Comparing Two Statistical Methods
## Background

Unconscious priming occurs when a stimulus influences responses without conscious
awareness of it. In masked-priming experiments, briefly presented primes precede
targets. Prime and target categories either match (congruent) or differ (incongruent).

The double t-test approach uses two separate tests:

- **Processing:** Are reaction times significantly faster on congruent than incongruent trials?
- **Awareness:** Does prime-identification accuracy differ significantly from chance?

Significant processing combined with nonsignificant awareness has been interpreted
as evidence of unconscious priming (e.g., [Dehaene et al., 1998](https://www.nature.com/articles/26967)). 
However, nonsignificant awareness does not establish an absence of awareness, as 
it may reflect low statistical power. This processing-advantage pattern can therefore
occur even when awareness and processing sensitivities are equal.

Inspired by [Meyen et al. (2021)](https://doi.org/10.1037/xge0001065), this project
compares the classic double t-test approach with a direct comparison of sensitivities:

- **Awareness sensitivity (\(d'\)):** Estimated from prime-identification responses.
- **Processing sensitivity (\(d'\)):** Estimated by dividing each participant’s 
reaction times into faster and slower responses at their median and measuring how
well these distinguish congruent from incongruent trials.
- **Direct comparison:** A one-sided paired t-test tests whether processing \(d'\) 
exceeds awareness \(d'\).

## Citation
Liu, S., Paschold, K., & Loewy, J. (2026). *pips-group-project* [Computer software]. 
GitHub. https://github.com/jloewy18/pips-group-project

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
├── src/
│   └── r/
│       ├── analysis.R              # Additional statistical analyses and plots
│       ├── batch.R                 # Repeats simulations and collects results
│       ├── classify.R              # Classifies analysis outcomes
│       ├── config.R                # Shared settings and constants
│       ├── dependencies.R          # Checks and loads required packages
│       ├── io.R                    # Saves and loads simulation results
│       ├── load_all.R              # Loads project scripts in order
│       ├── participant_analysis.R  # Implements the analysis approaches
│       ├── plot_theme.R             # Shared ggplot theme
│       ├── run_analysis.R           # Runs the analysis workflow
│       ├── run_simulation.R         # Runs one simulated experiment
│       ├── shiny_app.R              # Interactive Shiny app
│       └── simulate.R               # Simulates participant responses
├── .gitignore                       # Specifies files Git should ignore
├── README.md                        # Project overview and instructions
├── main.Rmd                         # Main report and analysis workflow
└── pips-group-project.Rproj         # RStudio project file
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

This saves the complete batch result as an RDS file and the successful experiment-level
results as a CSV file in the `data/` directory. If the directory does not exist, 
it is created automatically when saving.

To load the saved batch:

```r
saved_results <- load_batch("example_batch")
```

Raw data from an individual experiment can also be saved using `save_experiment()` 
and retrieved using `load_experiment()`. These files are stored in `data/raw/`,
which is also created automatically when saving if it does not already exist.

## Dependencies
The R project uses ggplot2 for data visualization and Shiny for the interactive app.
knitr and rmarkdown support the main document. The src/r/dependencies. The R scripts
install these packages when they are missing.

## References
Dehaene, S., Naccache, L., Le Clec’H, G., Koechlin, E., Mueller, M., Dehaene-Lambertz, 
G., van de Moortele, P.-F., & Le Bihan, D. (1998). Imaging unconscious semantic 
priming. Nature, 395(6702), 597–600. https://doi.org/10.1038/26967 

Meyen, S., Zerweck, I. A., Amado, C., von Luxburg, U., & Franz, V. H. (2022). 
Advancing research on unconscious priming: When can scientists claim an indirect 
task advantage? Journal of Experimental Psychology: General, 151(1), 65–81. 
https://doi.org/10.1037/xge0001065 

