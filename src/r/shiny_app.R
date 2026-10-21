# Shiny app to visualise how parameter settings change analysis outcomes.

# Run from the project root:
# source("src/r/load_all.R")
# run_app()

ui = fluidPage(
  tags$head(
    tags$style(HTML("
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
      .stale-alert {
        background:#fdecea;
        color:#8a1111;
        border:2px solid #d32f2f;
        border-left:10px solid #d32f2f;
        padding:14px 16px;
        border-radius:6px;
        margin-top:12px;
        font-size:16px;
        /* A brief pulse draws attention without continuous animation. */
        animation:stale-pulse 1.6s ease-out 3;
      }
      .stale-alert strong { color:#b71c1c; font-size:17px; }
      .stale-alert p { margin:6px 0 0; color:#8a1111; }
      @keyframes stale-pulse {
        0% { box-shadow:0 0 0 0 rgba(211,47,47,.55); }
        100% { box-shadow:0 0 0 14px rgba(211,47,47,0); }
      }
      .btn { white-space:normal; }
      .task-aware { color:#3267a8; }
      .task-process { color:#c77820; }
      .plot-key { font-size:13px; line-height:1.6; padding-left:20px; }
      .trial-slider { padding:0 8px; margin:8px 0 16px; }
      .trial-slider .shiny-input-container { width:100% !important; }
      /* Minimum heights align the method cards despite different text lengths. 
      */
      .method-title { min-height:52px; margin-bottom:10px; }
      .primary-result { min-height:110px; }
      /* Stacked cards no longer need aligned title heights on narrow screens. 
      */
      @media (max-width:767px) { .method-title { min-height:0; } }
      .assumptions {
        margin-top:16px;
        border:1px solid #b8cbe2;
        border-radius:7px;
        background:#f0f5fc;
        overflow:hidden;
      }
      .assumptions > summary {
        display:block;
        padding:12px;
        cursor:pointer;
        color:#3267a8;
        font-weight:600;
        list-style:none;
      }
      /* Custom arrows keep the disclosure indicator consistent across browsers.
      */
      .assumptions > summary::-webkit-details-marker { display:none; }
      .assumptions > summary::before { content:'▶'; display:inline-block; 
      margin-right:8px; }
      .assumptions[open] > summary::before { content:'▼'; }
      .assumptions > summary:hover { background:#e2ecf9; }
      .assumptions > summary:focus-visible { outline:2px solid #3267a8; 
      outline-offset:-2px; }
      .assumptions .expand-hint { display:block; margin-top:4px; font-size:12px; 
      font-weight:400; }
      .assumptions .hint-close { display:none; }
      .assumptions[open] .hint-open { display:none; }
      .assumptions[open] .hint-close { display:block; }
      .assumptions-content { padding:12px; border-top:1px solid #b8cbe2; 
      background:white; }
      .assumptions-content p:last-child { margin-bottom:0; }
    ")),
    # Use the shared colour constant to keep the result card and plot consistent.
    tags$style(HTML(sprintf(
      ".comparison-result {
        background:#edf6f1;
        border-left:4px solid %s;
        padding:12px;
        border-radius:6px;
      }",
      ADVANTAGE_COLOUR
    )))
  ),
  
  titlePanel("Unconscious Priming: How does the analysis method affect 
             the results?"),
  p("Compare the outcomes of the double t-test approach to a direct comparison 
    of estimated sensitivities."),
  div(
    class = "card",
    h3("The problem of using double t-tests to detect unconscious priming"),
    p(
      "Classic masked-priming experiments (e.g., Dehaene et al., 1998) report
      faster responses to targets following congruent primes but chance-level
      performance of identifying those primes. This double t-test pattern was 
      interpreted as evidence of ",
      strong("unconscious priming:"),
      " Participants are unaware of
  the primes but process them unconsciously."
    ),
    p(
      "However, a nonsignificant awareness test does not establish an absence of 
    awareness and may reflect low power. More observations in the 
    processing task can make even a small priming effect easier to detect, 
    without establishing that processing sensitivity is greater than awareness 
    sensitivity."
    ),
    p(
      "Inspired by ",
      tags$a(
        href = "https://doi.org/10.1037/xge0001065",
        target = "_blank", rel = "noopener noreferrer",
        "Meyen et al. (2022)"
      ),
      ", this app contrasts the double t-test approach with a direct comparison 
      of estimated processing and awareness sensitivities. The new approach uses 
      each participant’s median response time to separate faster from slower 
      responses and measures how well these distinguish congruent from 
      incongruent trials. This yields processing sensitivity on the same d′ 
      scale as awareness, allowing a direct comparison. Change mean population 
      sensitivities, number of participants, and number of trials to see how 
      often the methods give different answers regarding a processing advantage. 
      Keep in mind that a processing advantage alone does not prove unconscious 
      processing!"
    )
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Set the parameters"),
      numericInput("N", "Participants per experiment", value = 10,
                   min = 3, max = 200, step = 1),
      p(class = "muted",
        "The same participants complete both tasks. More participants increase 
        computation time."),
      
      h4(class = "task-aware", "Awareness task"),
      sliderInput("delta_aware", "True mean sensitivity δ",
                  min = -0.5, max = 1.5, value = 0.25, step = 0.05),
      div(
        class = "trial-slider",
        # Even trial counts allow balanced allocation to the two conditions.
        sliderInput("K_aware", "Trials per participant",
                    min = 50, max = 500, value = 100, step = 10,
                    ticks = FALSE, width = "100%")
      ),
      
      h4(class = "task-process", "Processing task"),
      sliderInput("delta_process", "True mean sensitivity δ",
                  min = -0.5, max = 1.5, value = 0.25, step = 0.05),
      div(
        class = "trial-slider",
        sliderInput("K_process", "Trials per participant",
                    min = 50, max = 500, value = 400, step = 10,
                    ticks = FALSE, width = "100%")
      ),
      p(class = "muted",
        sprintf("Between-person SD of true sensitivity: %.3f.", sqrt(Q2))),
      
      hr(),
      h4("Repeat the experiment"),
      numericInput("B", "Number of experiments", value = 100,
                   min = 20, max = 1000, step = 20),
      numericInput("seed", "Random seed", value = 2026,
                   min = 1, max = 1000000000, step = 1),
      actionButton("run", "Simulate experiments", class = "btn-primary"),
      p(
        class = "muted",
        style = "margin-top: 10px;",
        "Click to run. The same settings and seed reproduce the batch; change 
        the seed for new samples."
      ),
      
      # Native disclosure keeps assumptions accessible without extra reactive state.
      tags$details(
        class = "assumptions",
        tags$summary(
          "Simulation assumptions",
          tags$span(class = "expand-hint hint-open", "Click to expand"),
          tags$span(class = "expand-hint hint-close", "Click to collapse")
        ),
        div(
          class = "assumptions-content",
          p(class = "muted",
            "Each experiment samples new participant sensitivities and new 
            trials. True sensitivities are independent across tasks; observed 
            estimates are paired by participant ID. 
            RTs use standardized units."),
          # Derive the displayed threshold from the value used for classification.
          p(class = "muted", sprintf(
            "All classifications use α = %g. Awareness accuracy is tested 
            two-sided against chance (0.5). The processing RT effect is tested 
            one-sided: incongruent RT minus congruent RT is greater than zero. 
            The direct sensitivity comparison is also one-sided: processing d′ 
            minus awareness d′ is greater than zero.",
            ALPHA
          )),
          p(class = "muted",
            "Awareness d′ comes from identification responses. Processing d′ 
            comes from classifying RTs using each participant's observed median. 
            Congruent trials are labelled 'con'; incongruent trials are labelled 
            'incon'. Neither estimate uses true sensitivity.")
        )
      )
    ),
    
    mainPanel(
      width = 9,
      div(
        class = "card truth",
        h3("1 · True sensitivities in the population"),
        uiOutput("truth_text"),
        plotOutput("population", height = "240px"),
        p(class = "muted",
          "Curves show true sensitivities across people. Vertical markers show 
          mean sensitivity δ."),
        strong("In real life, true population sensitivities are unknown and can 
               only be estimated.")
      ),
      div(
        class = "card",
        uiOutput("repeat_heading"),
        p("Each simulation produces new responses. Both analyses use the same
          observed data."),
        uiOutput("batch_status"),
        uiOutput("stale_notice")
      ),
      
      fluidRow(
        column(
          6,
          div(
            class = "card",
            h3(class = "method-title", "Double t-test"),
            uiOutput("double_summary"),
            h4("Significant results"),
            plotOutput("double_outcomes", height = "300px"),
            tags$ul(
              class = "plot-key",
              tags$li(strong("Both: "),
                      "Awareness differs significantly from chance, and 
                      congruent RTs are significantly faster than 
                      incongruent RTs."),
              tags$li(strong("Processing only: "),
                      "Congruent RTs are significantly faster; awareness does 
                      not differ significantly from chance. This is the 
                      highlighted double-test processing advantage pattern."),
              tags$li(strong("Awareness only: "),
                      "Awareness differs significantly from chance, but the 
                      one-sided RT test is not significant."),
              tags$li(strong("Neither: "),
                      "Neither the two-sided awareness test nor the one-sided 
                      RT test is significant.")
            ),
            p(class = "muted", sprintf(
              "Significant means p < %g. Awareness significance includes above- 
              and below-chance results. The one-sided RT test only provides 
              evidence for faster congruent responses, not for the reverse 
              effect.",
              ALPHA
            )),
            p(class = "muted",
              "Nonsignificant awareness does not establish an absence of 
              awareness."),
            p(strong("The problem: "),
              "Significant processing plus nonsignificant awareness does not 
              establish a sensitivity difference.")
          )
        ),
        column(
          6,
          div(
            class = "card",
            h3(class = "method-title", "Direct comparison of d′"),
            uiOutput("comparison_metric"),
            h4("Evidence of processing advantage"),
            plotOutput("comparison_outcomes", height = "300px"),
            tags$ul(
              class = "plot-key",
              tags$li(strong("Processing advantage: "), sprintf(
                "The one-sided paired sensitivity comparison provides 
                significant evidence that processing sensitivity exceeds 
                awareness sensitivity (p < %g).",
                ALPHA
              )),
              tags$li(strong("No processing advantage: "),
                      "The one-sided comparison does not provide significant 
                      evidence that processing sensitivity exceeds awareness 
                      sensitivity. This does not establish equality or an 
                      awareness advantage.")
            ),
            p(strong("The advantage: "),
              "This analysis tests the sensitivity difference itself.")
          )
        )
      ),
      
      div(
        class = "card truth",
        h3("3 · Interpret the results"),
        uiOutput("interpretation"),
        uiOutput("disagreement"),
        p(class = "muted",
          "With few simulations, percentages can vary noticeably with the 
          seed.")
      ),
      uiOutput("failure_details")
    )
  )
)

server = function(input, output, session) {
  # Session-local storage prevents one user's simulation from replacing another's.
  batch = reactiveVal(NULL)
  
  # Centralise settings so execution and stale-result checks use the same inputs.
  settings = reactive(
    list(
      K_aware = input$K_aware,
      K_process = input$K_process,
      delta_aware = input$delta_aware,
      delta_process = input$delta_process,
      N = input$N,
      q2 = Q2,
      B = input$B,
      seed = input$seed
    )
  )
  
  output$repeat_heading = renderUI({
    x = batch()
    # Use the completed batch count so edited controls do not relabel existing results.
    if (!is.null(x)) {
      return(h3(sprintf(
        "2 · Experiment simulated %s times",
        format(x$attempted, big.mark = ",", trim = TRUE)
      )))
    }
    
    b = input$B
    # Numeric inputs may be temporarily empty or invalid while being edited.
    if (length(b) != 1L || !is.finite(b) ||
        b != round(b) || b < 20 || b > 1000) {
      return(h3("2 · Simulate the same experiment"))
    }
    
    h3(sprintf(
      "2 · Simulate the experiment %s times",
      format(b, big.mark = ",", trim = TRUE)
    ))
  })
  
  output$truth_text = renderUI({
    # Live inputs provide a preview without rerunning the simulations.
    difference = input$delta_process - input$delta_aware
    tagList(
      p(sprintf(
        "Awareness δ = %.2f · Processing δ = %.2f · True difference = %+.2f",
        input$delta_aware, input$delta_process, difference
      )),
      strong(
        # A tolerance avoids treating floating-point rounding as a real difference.
        if (abs(difference) < 1e-10)
          "Equal true mean sensitivities: no population processing advantage."
        else if (difference > 0)
          "A true population processing advantage exists."
        else
          "Awareness has higher true mean sensitivity: no population processing 
        advantage."
      )
    )
  })
  
  output$population = renderPlot({
    q = sqrt(Q2)
    # Four SDs beyond the slider range retain nearly all density at either extreme.
    x = seq(-0.5 - 4 * q, 1.5 + 4 * q, length.out = 600)
    curves = rbind(
      data.frame(x = x, density = dnorm(x, input$delta_aware, q),
                 task = "Awareness"),
      data.frame(x = x, density = dnorm(x, input$delta_process, q),
                 task = "Processing")
    )
    # Explicit levels preserve the intended legend order rather than alphabetical order.
    curves$task = factor(curves$task, levels = c("Awareness", "Processing"))
    means = data.frame(
      task = c("Awareness", "Processing"),
      delta = c(input$delta_aware, input$delta_process)
    )
    
    ggplot(curves, aes(x, density, colour = task, fill = task)) +
      # Overlap the densities instead of stacking distributions from different tasks.
      geom_area(alpha = 0.12, position = "identity", show.legend = FALSE) +
      geom_line(aes(linetype = task), linewidth = 1.2) +
      geom_vline(
        data = means,
        aes(xintercept = delta, colour = task),
        linetype = "dashed", linewidth = 0.7, show.legend = FALSE
      ) +
      scale_colour_manual(values = COLS, name = NULL) +
      scale_fill_manual(values = COLS, name = NULL) +
      # Different line types help distinguish tasks when their densities overlap.
      scale_linetype_manual(
        values = c(Awareness = "solid", Processing = "dashed"), name = NULL
      ) +
      labs(x = "True individual sensitivity d′", y = "Population density") +
      plot_theme() +
      theme(legend.position = "top")
  }, res = 110)
  
  # Button-triggered execution avoids expensive reruns whenever a slider changes.
  observeEvent(input$run, {
    # Explicit isolation documents that settings are sampled only for this run.
    s = isolate(settings())
    # Server-side validation catches invalid values that UI bounds cannot prevent.
    if (!valid_batch_settings(s)) {
      showNotification(
        "Use 3–200 participants, 20–1000 experiments, even trial counts from 
        50–500, and an integer seed from 1 to 1,000,000,000.",
        type = "error"
      )
      return()
    }
    
    # Reuse the analysis pipeline so app and report apply identical test rules.
    result = withProgress(
      message = "Simulating experiments",
      value = 0,
      {
        run_batch(
          s,
          alpha = ALPHA,
          # A callback reports progress without making run_batch() depend on Shiny.
          on_progress = function(b, B) {
            setProgress(value = b / B, detail = sprintf("%d of %d", b, B))
          }
        )
      }
    )
    # Publish results only after the batch completes to keep outputs consistent.
    batch(result)
  }, ignoreInit = TRUE)
  
  # Shared validation gives dependent outputs a useful message before the first run.
  get_batch = reactive({
    x = batch()
    validate(need(!is.null(x), "Click “Simulate experiments” to see results."))
    x
  })
  
  get_data = reactive({
    x = get_batch()
    # Empty batches cannot supply meaningful percentages or outcome plots.
    validate(need(
      !is.null(x$data) && nrow(x$data) > 0,
      "No experiments could be analysed. Adjust settings and inspect the warning 
      details."
    ))
    x$data
  })
  
  output$batch_status = renderUI({
    x = batch()
    if (is.null(x))
      return(p("Choose settings and click “Simulate experiments”."))
    
    n = if (is.null(x$data)) 0L else nrow(x$data)
    if (!length(x$errors))
      return(p(sprintf("%d participants per experiment", x$settings$N)))
    
    # Report exclusions because failed analyses change the percentage denominator.
    div(
      class = "warning",
      strong(sprintf(
        "%d of %d experiments could not be analysed.",
        length(x$errors), x$attempted
      )),
      p(
        if (n > 0)
          sprintf("Percentages use the remaining %d experiments. See analysis 
                  details below.", n)
        else
          "No results are available for this batch. Change the settings and 
        simulate again."
      )
    )
  })
  
  output$stale_notice = renderUI({
    # all.equal() can return text, so isTRUE() converts its result to one boolean.
    if (!is.null(batch()) &&
        !isTRUE(all.equal(settings(), batch()$settings))) {
      div(
        class = "stale-alert",
        role = "alert",
        strong("⚠ Settings changed: results still show the previous batch."),
        p("The heading shows the completed batch's repetition count. Click 
          “Simulate experiments” to apply the new settings.")
      )
    }
  })
  
  output$failure_details = renderUI({
    x = batch()
    if (is.null(x) || !length(x$errors))
      return(NULL)
    
    # Collapse diagnostics to preserve the layout while retaining transparency.
    tags$details(
      tags$summary("Analysis details"),
      div(
        class = "card",
        tableOutput("errors"),
        p(class = "muted",
          "These are calculation failures, not nonsignificant results. 
          Failed experiments are not replaced. Excluding them can affect the 
          percentages.")
      )
    )
  })
  
  output$double_outcomes = renderPlot({
    dat = get_data()
    # Fixed levels retain all four categories even when one has zero results.
    counts = as.integer(table(factor(dat$outcome, levels = 1:4)))
    chart = data.frame(
      label = factor(OUTCOMES, levels = OUTCOMES),
      percentage = 100 * counts / nrow(dat),
      # Category 2 is the processing-only pattern defined by classify_experiment().
      highlight = seq_len(4) == 2L
    )
    
    ggplot(chart, aes(label, percentage, fill = highlight)) +
      geom_col(width = 0.65) +
      geom_text(aes(label = sprintf("%.0f%%", percentage)),
                vjust = -0.5, size = 4) +
      scale_fill_manual(values = c("FALSE" = "#BBC7D5", "TRUE" = "#C77820"),
                        guide = "none") +
      # Extra headroom keeps labels visible when a bar reaches 100 percent.
      scale_y_continuous(
        limits = c(0, 110), breaks = seq(0, 100, 25),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(x = NULL, y = "Experiments (%)") +
      plot_theme() +
      theme(panel.grid.major.x = element_blank(),
            axis.text.x = element_text(size = 10))
  }, res = 110)
  
  output$double_summary = renderUI({
    dat = get_data()
    div(
      class = "warning primary-result",
      # The mean of a logical flag gives its proportion of TRUE results.
      div(class = "big", sprintf(
        "%.0f%%", 100 * mean(dat$double_processing_advantage)
      )),
      strong("Show the double-test processing advantage pattern."),
      div(class = "muted",
          "One-sided RT test significant; two-sided awareness test 
          nonsignificant.")
    )
  })
  
  output$comparison_metric = renderUI({
    dat = get_data()
    div(
      class = "comparison-result primary-result",
      div(class = "big", sprintf(
        "%.0f%%", 100 * mean(dat$comparison_processing_advantage)
      )),
      strong("Support a processing advantage in the sensitivity comparison."),
      div(class = "muted",
          "One-sided paired comparison: processing d′ exceeds awareness d′.")
    )
  })
  
  output$comparison_outcomes = renderPlot({
    dat = get_data()
    k = sum(dat$comparison_processing_advantage)
    labels = c("Processing advantage", "No processing advantage")
    chart = data.frame(
      # Explicit levels preserve the intended display order rather than alphabetical order.
      label = factor(labels, levels = labels),
      percentage = 100 * c(k, nrow(dat) - k) / nrow(dat)
    )
    
    ggplot(chart, aes(label, percentage, fill = label)) +
      geom_col(width = 0.55) +
      geom_text(aes(label = sprintf("%.0f%%", percentage)),
                vjust = -0.5, size = 4) +
      scale_fill_manual(
        values = c("Processing advantage" = ADVANTAGE_COLOUR,
                   "No processing advantage" = "#BBC7D5"),
        guide = "none"
      ) +
      scale_x_discrete(labels = c(
        "Processing advantage" = "Processing\nadvantage",
        "No processing advantage" = "No processing\nadvantage"
      )) +
      scale_y_continuous(
        limits = c(0, 110), breaks = seq(0, 100, 25),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(x = NULL, y = "Experiments (%)") +
      plot_theme() +
      theme(panel.grid.major.x = element_blank())
  }, res = 110)
  
  output$interpretation = renderUI({
    # Require analysable results before interpreting detection percentages.
    get_data()
    # Interpret the completed batch rather than the live parameter preview.
    s = get_batch()$settings
    truth = s$delta_process - s$delta_aware
    tagList(
      strong(sprintf("True population difference in this batch: %+.2f", truth)),
      p(
        if (truth > 0)
          "A genuine population processing advantage exists. The 
        sensitivity-comparison percentage estimates how often the method 
        detects it among successfully analysed experiments. The double-test 
        percentage counts only the separate-test pattern."
        else
          "No true population processing advantage exists. Any significant 
        processing-advantage result from the direct comparison is a false 
        positive. The double-test pattern does not establish a difference 
        between tasks."
      )
    )
  })
  
  output$disagreement = renderUI({
    dat = get_data()
    # Compare flags within experiments because both methods use the same simulated data.
    p(strong(sprintf(
      "%.0f%% showed the double t-test processing advantage pattern without 
      support from the direct comparison of the estimated sensitivities.",
      100 * mean(dat$double_processing_advantage &
                   !dat$comparison_processing_advantage)
    )))
  })
  
  output$errors = renderTable({
    x = batch()
    req(!is.null(x), length(x$errors) > 0)
    # Group repeated messages so frequent failures are easy to identify.
    tab = sort(table(x$errors), decreasing = TRUE)
    data.frame(Message = names(tab), Count = as.integer(tab))
  }, striped = TRUE, spacing = "m")
}

# Defer launching so loading project functions does not start an interactive session.
run_app = function(...) {
  shiny::runApp(shinyApp(ui, server), ...)
}