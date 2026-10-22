# Shiny app to visualise how parameter settings change analysis outcomes.

# Run from the repository root:
# source("src/r/load_all.R")
# run_app()

info_button = function(id, description) {
  actionButton(
    inputId = id, label = "ⓘ", class = "info-button",
    title = paste("About", description),
    `aria-label` = paste("Information about", description)
  )
}

# Help topics to reduce amount of text in UI.
app_help = list(
  info_awareness = list(
    title = "What happens in the awareness task?",
    body = tagList(
      p("Participants identify the briefly presented, masked prime's category. Each response is recorded as correct or incorrect; chance accuracy is 50%.")
    )
  ),
  info_processing = list(
    title = "What happens in the processing task?",
    body = tagList(
      p("Participants classify a target following a masked prime. On congruent trials, prime and target categories match; on incongruent trials, they differ."),
      p("The outcome is reaction time (RT). A priming effect means faster RTs on congruent than incongruent trials.")
    )
  ),
  info_assumptions = list(
    title = "Simulation assumptions",
    body = tagList(
      p("The same participants complete both tasks. Each experiment samples new participant sensitivities and trials. True sensitivities are independent across tasks; observed estimates are paired by participant ID."),
      p(sprintf("Between-person sensitivity SD is fixed at %.2f. RTs use standardized units.", sqrt(Q2))),
      p("The number of experiments is the number of simulation repetitions. More repetitions make percentages more stable. The same settings, seed, and code reproduce a batch. Change the seed for new samples.")
    )
  ),
  info_population = list(
    title = "Sensitivity and the population plot",
    body = tagList(
      p(
        strong("True mean sensitivity δ"),
        " describes how strongly people in the population, on average, respond 
        to information from the primes. This value cannot be known for real 
        experiments."
      ),
      tags$ul(
        tags$li(
          strong("Awareness sensitivity: "),
          "How well can people identify the prime? Higher values mean
        more accurate identification."
        ),
        tags$li(
          strong("Processing sensitivity: "),
          "How clearly do reaction times reveal whether prime and target
        match? Higher values mean congruent trials are more consistently
        faster than incongruent trials."
        )
      ),
      p(
        "For either task, ",
        strong("zero"),
        " means no average effect: chance-level identification or no
      systematic reaction-time difference. ",
        strong("Negative values"),
        " indicate a reversed pattern: below-chance identification or
      faster incongruent responses."
      ),
      p(
        "The curves show how true sensitivities vary ",
        strong("between people"),
        ". The vertical lines mark each task's population average δ.
      Wider curves mean more variation between individuals."
      )
    )
  ),
  info_double = list(
    title = "How are the double t-test outcomes classified?",
    body = tagList(
      p(sprintf("The awareness test is two-sided against 50%% accuracy. The processing test is one-sided for a positive incongruent-minus-congruent RT difference. Significant means p < %g.", ALPHA)),
      tags$ul(
        tags$li(strong("Both: "), "Both tests are significant."),
        tags$li(strong("Processing only: "), "Only the processing test is significant. This is the highlighted pattern."),
        tags$li(strong("Awareness only: "), "Only the awareness test is significant."),
        tags$li(strong("Neither: "), "Neither test is significant.")
      ),
      p("A significant awareness result can be above or below chance. The processing test only evaluates faster congruent responses. A nonsignificant awareness result can reflect low power, it is not evidence of absent awareness.")
    )
  ),
  info_comparison = list(
    title = "How is the direct comparison calculated?",
    body = tagList(
      p("Awareness d′ is estimated from identification responses. For processing, each participant's median RT separates faster and slower responses. Processing d' is determined by how well faster or slower responses distinguish congruent from incongruent trials."),
      p(sprintf("A one-sided paired t-test evaluates whether processing-d′-minus-awareness-d′ is greater than zero. The processing advantage category requires p < %g.", ALPHA)),
      p("The other category means there is insufficient evidence for a processing advantage. It does not establish equal sensitivity or an awareness advantage.")
    )
  )
)

ui = fluidPage(
  tags$head(tags$style(HTML(sprintf("
    body { background:#f5f7fa; color:#253342; font-size:15px; }
    .container-fluid { max-width:1450px; }
    .well { background:white; border:1px solid #dde3eb; box-shadow:none; }
    .card { background:white; border:1px solid #dde3eb; border-radius:8px;
            padding:18px; margin-bottom:16px; }
    .card h3 { margin-top:0; font-size:21px; font-weight:650; }
    .truth { background:#fff8e9; border:2px solid #d8bd7d; }
    .muted { color:#586575; font-size:13px; }
    .big { font-size:32px; font-weight:700; }
    .warning { background:#fff0df; border-left:4px solid #c77820;
               padding:12px; border-radius:6px; }
    .comparison-result { background:#edf6f1; border-left:4px solid %s;
                         padding:12px; border-radius:6px; }
    .stale-alert { background:#fdecea; color:#8a1111; border:2px solid #d32f2f;
                   border-left:10px solid #d32f2f; padding:14px 16px;
                   border-radius:6px; margin-top:12px; font-size:16px;
                   animation:stale-pulse 1.6s ease-out 3; }
    .stale-alert strong { color:#b71c1c; font-size:17px; }
    .stale-alert p { margin:6px 0 0; color:#8a1111; }
    @keyframes stale-pulse {
      0%% { box-shadow:0 0 0 0 rgba(211,47,47,.55); }
      100%% { box-shadow:0 0 0 14px rgba(211,47,47,0); }
    }
    @media (prefers-reduced-motion:reduce) { .stale-alert { animation:none; } }
    .btn { white-space:normal; }
    .info-button { display:inline-flex; align-items:center; justify-content:center;
                   width:26px; height:26px; min-width:26px; padding:0;
                   margin-left:7px; border-radius:50%%; border:1px solid #b8cbe2;
                   background:#f0f5fc; color:#3267a8; font-size:18px;
                   font-weight:normal; vertical-align:middle; line-height:1; }
    .info-button:hover { background:#dce9f8; color:#224e85; }
    .info-button:focus-visible { outline:2px solid #3267a8; outline-offset:3px; }
    .section-heading { display:flex; align-items:flex-start;
                       justify-content:space-between; gap:8px; }
    .section-heading .info-button { flex-shrink:0; }
    .task-aware { color:#3267a8; }
    .task-process { color:#c77820; }
    .trial-slider { padding:0 8px; margin:8px 0 16px; }
    .trial-slider .shiny-input-container { width:100%% !important; }
    .method-title { min-height:52px; margin-bottom:10px; }
    .primary-result { min-height:90px; }
    .help-row { margin-top:14px; }
    .help-row .info-button { margin-left:0; margin-right:6px; }
    .modal-body { line-height:1.65; }
    .modal-body p:last-child { margin-bottom:0; }
    @media (max-width:767px) { .method-title { min-height:0; } }
  ", ADVANTAGE_COLOUR)))),
  
  titlePanel("Unconscious Priming: How Does the Analysis Method Affect the Results?"),
  div(
    class = "card",
    p("Unconscious priming describes the influence of primes on responses without conscious awareness of these primes. The classic double t-test approach assumes unconscious priming if prime-target congruency speeds up responses significantly while the identification of these primes does not diverge significantly from chance-level."),
    p("Inspired by ",
      tags$a(href = "https://doi.org/10.1037/xge0001065",
             target = "_blank", rel = "noopener noreferrer", "Meyen et al. (2022)"),
      ", this app visualises how sensitivity, participants, and trials affect the double t-test pattern versus a direct comparison of d'.")
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Set the parameters"),
      numericInput("N", "Participants",
                   value = 10, min = 3, max = 200, step = 1),
      h4(class = "task-aware", "Awareness task",
         info_button("info_awareness", "the awareness task")),
      sliderInput("delta_aware", "True mean sensitivity δ",
                  min = -0.5, max = 1.5, value = 0.25, step = 0.05),
      div(class = "trial-slider",
          sliderInput("K_aware", "Trials",
                      min = 50, max = 500, value = 100, step = 10,
                      ticks = FALSE, width = "100%")),
      h4(class = "task-process", "Processing task",
         info_button("info_processing", "the processing task")),
      sliderInput("delta_process", "True mean sensitivity δ",
                  min = -0.5, max = 1.5, value = 0.25, step = 0.05),
      div(class = "trial-slider",
          sliderInput("K_process", "Trials",
                      min = 50, max = 500, value = 400, step = 10,
                      ticks = FALSE, width = "100%")),
      hr(),
      h4("Repeat the experiment"),
      numericInput("B", "Number of experiments",
                   value = 100, min = 20, max = 1000, step = 20),
      numericInput("seed", "Random seed",
                   value = 2026, min = 1, max = 1000000000, step = 1),
      actionButton("run", "Simulate experiments", class = "btn-primary"),
      div(class = "help-row",
          info_button("info_assumptions", "simulation assumptions"),
          span(class = "muted", "Simulation assumptions"))
    ),
    mainPanel(
      width = 9,
      div(
        class = "card truth",
        div(class = "section-heading",
            h3("1 · True sensitivities in the population"),
            info_button("info_population", "true mean sensitivities and the population plot")),
        uiOutput("truth_text"),
        plotOutput("population", height = "240px"),
        p(class = "muted", "True sensitivities are known here because the data are simulated.")
      ),
      div(class = "card",
          uiOutput("repeat_heading"),
          uiOutput("batch_status"), uiOutput("stale_notice")),
      fluidRow(
        column(6, div(
          class = "card",
          div(class = "section-heading",
              h3(class = "method-title", "Double t-test"),
              info_button("info_double", "double t-test outcomes")),
          uiOutput("double_summary"),
          h4("Significant results"),
          plotOutput("double_outcomes", height = "300px"),
          p(strong("Separate significance results do not establish a sensitivity difference."))
        )),
        column(6, div(
          class = "card",
          div(class = "section-heading",
              h3(class = "method-title", "Direct comparison of d′"),
              info_button("info_comparison", "the direct sensitivity comparison")),
          uiOutput("comparison_metric"),
          h4("Significant results"),
          plotOutput("comparison_outcomes", height = "300px"),
          p(strong("This analysis tests the sensitivity difference itself."))
        ))
      ),
      div(
        class = "card truth",
        h3("3 · Interpret the results"),
        uiOutput("interpretation"), uiOutput("disagreement"),
        p(strong("A processing advantage alone does not prove unconscious priming!"))
      ),
      uiOutput("failure_details")
    )
  )
)

server = function(input, output, session) {
  # Keep results separate for each user session.
  batch = reactiveVal(NULL)
  
  for (help_id in names(app_help)) {
    # Give each observer its own ID so buttons open the correct help text.
    local({
      id = help_id
      observeEvent(input[[id]], {
        help = app_help[[id]]
        showModal(modalDialog(
          title = help$title, help$body,
          footer = modalButton("Close"), easyClose = TRUE, size = "m"
        ))
      }, ignoreInit = TRUE)
    })
  }
  
  # Share one settings list between simulation runs and outdated-result checks.
  settings = reactive(list(
    K_aware = input$K_aware, K_process = input$K_process,
    delta_aware = input$delta_aware, delta_process = input$delta_process,
    N = input$N, q2 = Q2, B = input$B, seed = input$seed
  ))
  
  output$repeat_heading = renderUI({
    x = batch()
    # Keep the heading tied to completed results when controls change.
    if (!is.null(x)) {
      return(h3(sprintf("2 · Experiment simulated %s times",
                        format(x$attempted, big.mark = ",", trim = TRUE))))
    }
    b = input$B
    # Inputs can briefly be empty while the user edits them.
    if (length(b) != 1L || !is.finite(b) ||
        b != round(b) || b < 20 || b > 1000) {
      return(h3("2 · Simulate the same experiment"))
    }
    h3(sprintf("2 · Simulate the experiment %s times",
               format(b, big.mark = ",", trim = TRUE)))
  })
  
  # Preview the current controls without running another simulation.
  output$truth_text = renderUI({
    difference = input$delta_process - input$delta_aware
    tagList(
      p(sprintf("Awareness δ = %.2f · Processing δ = %.2f · True difference = %+.2f",
                input$delta_aware, input$delta_process, difference)),
      # Ignore tiny rounding differences when checking equal sensitivities.
      strong(if (abs(difference) < 1e-10)
        "Equal true mean sensitivities: no population processing advantage."
        else if (difference > 0) "A true population processing advantage exists."
        else "Awareness has higher true mean sensitivity: no population processing advantage.")
    )
  })
  
  output$population = renderPlot({
    q = sqrt(Q2)
    x = seq(-0.5 - 4 * q, 1.5 + 4 * q, length.out = 600)
    curves = rbind(
      data.frame(x = x, density = dnorm(x, input$delta_aware, q), task = "Awareness"),
      data.frame(x = x, density = dnorm(x, input$delta_process, q), task = "Processing")
    )
    curves$task = factor(curves$task, levels = c("Awareness", "Processing"))
    means = data.frame(task = c("Awareness", "Processing"),
                       delta = c(input$delta_aware, input$delta_process))
    ggplot(curves, aes(x, density, colour = task, fill = task)) +
      geom_area(alpha = 0.12, position = "identity", show.legend = FALSE) +
      geom_line(aes(linetype = task), linewidth = 1.2) +
      geom_vline(data = means, aes(xintercept = delta, colour = task),
                 linetype = "dashed", linewidth = 0.7, show.legend = FALSE) +
      scale_colour_manual(values = COLS, name = NULL) +
      scale_fill_manual(values = COLS, name = NULL) +
      scale_linetype_manual(values = c(Awareness = "solid", Processing = "dashed"), name = NULL) +
      labs(x = "True individual sensitivity d′", y = "Population density") +
      plot_theme() + theme(legend.position = "top")
  }, res = 110)
  
  # Run expensive simulations only on a button click, not on every slider change.
  observeEvent(input$run, {
    s = isolate(settings())
    # Check inputs on the server because UI limits alone cannot guarantee valid values.
    if (!valid_batch_settings(s)) {
      showNotification(
        "Use 3–200 participants, 20–1000 experiments, even trial counts from 50–500, and an integer seed from 1 to 1,000,000,000.",
        type = "error")
      return()
    }
    result = withProgress(message = "Simulating experiments", value = 0, {
      # Reuse the project pipeline so the app applies the same analysis rules.
      run_batch(s, alpha = ALPHA, on_progress = function(b, B) {
        setProgress(value = b / B, detail = sprintf("%d of %d", b, B))
      })
    })
    # Update all results together only after the batch finishes.
    batch(result)
  }, ignoreInit = TRUE)
  
  # Give dependent outputs useful messages before results are available.
  get_batch = reactive({
    x = batch()
    validate(need(!is.null(x), "Click “Simulate experiments” to see results."))
    x
  })
  get_data = reactive({
    x = get_batch()
    validate(need(!is.null(x$data) && nrow(x$data) > 0,
                  "No experiments could be analysed. Adjust settings and inspect the warning details."))
    x$data
  })
  
  output$batch_status = renderUI({
    x = batch()
    if (is.null(x)) return(p("Choose settings and click “Simulate experiments”."))
    n = if (is.null(x$data)) 0L else nrow(x$data)
    if (!length(x$errors)) return(p(sprintf("%d participants per experiment", x$settings$N)))
    # Make exclusions visible because they change the percentage denominator.
    div(class = "warning",
        strong(sprintf("%d of %d experiments could not be analysed.", length(x$errors), x$attempted)),
        p(if (n > 0) sprintf("Percentages use the remaining %d experiments. See analysis details below.", n)
          else "No results are available for this batch. Change the settings and simulate again."))
  })
  
  output$stale_notice = renderUI({
    if (!is.null(batch()) && !isTRUE(all.equal(settings(), batch()$settings))) {
      div(class = "stale-alert", role = "alert",
          strong("⚠ Settings changed: results still show the previous batch."),
          p("Click “Simulate experiments” to apply the new settings."))
    }
  })
  
  output$failure_details = renderUI({
    x = batch()
    if (is.null(x) || !length(x$errors)) return(NULL)
    tags$details(tags$summary("Analysis details"),
                 div(class = "card", tableOutput("errors"),
                     p(class = "muted", "These are calculation failures, not nonsignificant results. Failed experiments are not replaced. Excluding them can affect the percentages.")))
  })
  
  output$double_outcomes = renderPlot({
    dat = get_data()
    # Keep all four categories visible, even when none fall in a category.
    counts = as.integer(table(factor(dat$outcome, levels = 1:4)))
    chart = data.frame(label = factor(OUTCOMES, levels = OUTCOMES),
                       percentage = 100 * counts / nrow(dat),
                       # Emphasise the pattern traditionally interpreted as unconscious priming.
                       highlight = seq_len(4) == 2L)
    ggplot(chart, aes(label, percentage, fill = highlight)) +
      geom_col(width = 0.65) +
      geom_text(aes(label = sprintf("%.0f%%", percentage)), vjust = -0.5, size = 4) +
      scale_fill_manual(values = c("FALSE" = "#BBC7D5", "TRUE" = "#C77820"), guide = "none") +
      scale_y_continuous(limits = c(0, 110), breaks = seq(0, 100, 25),
                         expand = expansion(mult = c(0, 0.02))) +
      labs(x = NULL, y = "Experiments (%)") + plot_theme() +
      theme(panel.grid.major.x = element_blank(), axis.text.x = element_text(size = 10))
  }, res = 110)
  
  output$double_summary = renderUI({
    dat = get_data()
    div(class = "warning primary-result",
        div(class = "big", sprintf("%.0f%%", 100 * mean(dat$double_processing_advantage))),
        strong("of experiments indicate a processing advantage."))
  })
  
  output$comparison_metric = renderUI({
    dat = get_data()
    div(class = "comparison-result primary-result",
        div(class = "big", sprintf("%.0f%%", 100 * mean(dat$comparison_processing_advantage))),
        strong("of experiments indicate a processing advantage."))
  })
  
  output$comparison_outcomes = renderPlot({
    dat = get_data()
    k = sum(dat$comparison_processing_advantage)
    labels = c("Processing advantage", "No processing advantage")
    chart = data.frame(label = factor(labels, levels = labels),
                       percentage = 100 * c(k, nrow(dat) - k) / nrow(dat))
    ggplot(chart, aes(label, percentage, fill = label)) +
      geom_col(width = 0.55) +
      geom_text(aes(label = sprintf("%.0f%%", percentage)), vjust = -0.5, size = 4) +
      scale_fill_manual(values = c("Processing advantage" = ADVANTAGE_COLOUR,
                                   "No processing advantage" = "#BBC7D5"), guide = "none") +
      scale_x_discrete(labels = c("Processing advantage" = "Processing\nadvantage",
                                  "No processing advantage" = "No processing\nadvantage")) +
      scale_y_continuous(limits = c(0, 110), breaks = seq(0, 100, 25),
                         expand = expansion(mult = c(0, 0.02))) +
      labs(x = NULL, y = "Experiments (%)") + plot_theme() +
      theme(panel.grid.major.x = element_blank())
  }, res = 110)
  
  # Interpret the completed batch, not settings edited since the last run.
  output$interpretation = renderUI({
    get_data()
    s = get_batch()$settings
    truth = s$delta_process - s$delta_aware
    tagList(
      div(
        style = "margin-bottom: 20px;",
        strong(sprintf("True population difference in this batch: %+.2f", truth))
      ),
      p(if (truth > 0)
        "A true processing advantage exists. The highlighted percentage for the double t-test approach shows how often processing is significant while awareness is not. This pattern alone does not establish a processing advantage or an absence of awareness."
        else "No true processing advantage exists. For the double t-test approach, interpreting the highlighted processing-only pattern as a processing advantage would be a false-positive conclusion."),
      p(if (truth > 0)
        "For the direct comparison, significant processing advantage results show how often a true mean difference in sensitivities is detected among analysed experiments."
        else "For the direct comparison of d', significant processing advantage results are also false positives.")
    )
  })
  
  output$disagreement = renderUI({
    dat = get_data()
    p(strong(sprintf("%.0f%% showed the double-test pattern without a significant direct comparison.",
                     100 * mean(dat$double_processing_advantage & !dat$comparison_processing_advantage))))
  })
  
  output$errors = renderTable({
    x = batch()
    req(!is.null(x), length(x$errors) > 0)
    # Group repeated failures so diagnostics stay readable.
    tab = sort(table(x$errors), decreasing = TRUE)
    data.frame(Message = names(tab), Count = as.integer(tab))
  }, striped = TRUE, spacing = "m")
}

# Loading this file should not launch the app automatically.
run_app = function(...) {
  shiny::runApp(shinyApp(ui, server), ...)
}