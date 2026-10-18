# Shiny app. Requires the project to be loaded first:
# source("src/r/load_all.R")
# Start with run_app()

ui = fluidPage(
  tags$head(
    tags$style(
      HTML("
        body { background:#f5f7fa; color:#253342; font-size:15px; }
        .container-fluid { max-width:1450px; }
        .well { background:white; border:1px solid #dde3eb; box-shadow:none; }
        .card { background:white; border:1px solid #dde3eb; border-radius:8px; padding:18px; margin-bottom:16px; }
        .card h3 { margin-top:0; font-size:21px; font-weight:650; }
        .truth { background:#fff8e9; border:2px solid #d8bd7d; }
        .muted { color:#586575; font-size:13px; }
        .flow { background:#f1f4f8; border-radius:7px; padding:12px; line-height:1.7; margin-top:14px; }
        .big { font-size:32px; font-weight:700; }
        .warning { background:#fff0df; border-left:4px solid #c77820; padding:12px; border-radius:6px; }
        .green { background:#edf6f1; border-left:4px solid #287a59; padding:12px; border-radius:6px; }
        .stale-alert {
          background:#fdecea;
          color:#8a1111;
          border:2px solid #d32f2f;
          border-left:10px solid #d32f2f;
          padding:14px 16px;
          border-radius:6px;
          margin-top:12px;
          font-size:16px;
          animation:stale-pulse 1.6s ease-out 3;
        }
        .stale-alert strong { color:#b71c1c; font-size:17px; }
        .stale-alert p { margin:6px 0 0; color:#8a1111; }
        @keyframes stale-pulse {
          0% { box-shadow:0 0 0 0 rgba(211,47,47,.55); }
          100% { box-shadow:0 0 0 14px rgba(211,47,47,0); }
        }
        .small-metrics { display:flex; flex-wrap:wrap; gap:12px; margin:14px 0; }
        .small-metrics > div { flex:1; min-width:140px; background:#f1f4f8; padding:12px; border-radius:6px; }
        .btn { white-space:normal; }
        .task-aware { color:#3267a8; }
        .task-process { color:#c77820; }
        .plot-key { font-size:13px; line-height:1.6; padding-left:20px; }
        .trial-slider { padding:0 8px; margin:8px 0 16px; }
        .trial-slider .shiny-input-container { width:100% !important; }
        .method-title { min-height:52px; margin-bottom:10px; }
        .primary-result { min-height:110px; }
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
        .assumptions > summary::-webkit-details-marker {
          display:none;
        }
        .assumptions > summary::before {
          content:'▶';
          display:inline-block;
          margin-right:8px;
        }
        .assumptions[open] > summary::before {
          content:'▼';
        }
        .assumptions > summary:hover {
          background:#e2ecf9;
        }
        .assumptions > summary:focus-visible {
          outline:2px solid #3267a8;
          outline-offset:-2px;
        }
        .assumptions .expand-hint {
          display:block;
          margin-top:4px;
          font-size:12px;
          font-weight:400;
        }
        .assumptions .hint-close {
          display:none;
        }
        .assumptions[open] .hint-open {
          display:none;
        }
        .assumptions[open] .hint-close {
          display:block;
        }
        .assumptions-content {
          padding:12px;
          border-top:1px solid #b8cbe2;
          background:white;
        }
        .assumptions-content p:last-child {
          margin-bottom:0;
        }
      ")
    )
  ),
  
  titlePanel("Unconsious Priming: How does the analysis method affect the results?"),
  p(
    "Compare the outcomes of the double t-test approach to a direct comparison of estimated sensitivities."
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Set the parameters"),
      
      numericInput(
        "N",
        "Participants per experiment",
        value = 10,
        min = 3,
        max = 200,
        step = 1
      ),
      
      p(
        class = "muted",
        "The same participants complete both tasks. More participants increase computation time."
      ),
      
      h4(class = "task-aware", "Awareness task"),
      
      sliderInput(
        "delta_aware",
        "True mean sensitivity δ",
        min = -0.5,
        max = 1.5,
        value = 0.25,
        step = 0.05
      ),
      
      div(
        class = "trial-slider",
        sliderInput(
          "K_aware",
          "Trials per participant",
          min = 50,
          max = 500,
          value = 100,
          step = 10,
          ticks = FALSE,
          width = "100%"
        )
      ),
      
      h4(class = "task-process", "Processing task"),
      
      sliderInput(
        "delta_process",
        "True mean sensitivity δ",
        min = -0.5,
        max = 1.5,
        value = 0.25,
        step = 0.05
      ),
      
      div(
        class = "trial-slider",
        sliderInput(
          "K_process",
          "Trials per participant",
          min = 50,
          max = 500,
          value = 400,
          step = 10,
          ticks = FALSE,
          width = "100%"
        )
      ),
      
      p(
        class = "muted",
        sprintf(
          "Between-person SD of true sensitivity: %.3f.",
          sqrt(Q2)
        )
      ),
      
      hr(),
      h4("Repeat the experiment"),
      
      numericInput(
        "B",
        "Number of experiments",
        value = 100,
        min = 20,
        max = 1000,
        step = 20
      ),
      
      numericInput(
        "seed",
        "Random seed",
        value = 2026,
        min = 1,
        max = 1000000000,
        step = 1
      ),
      
      actionButton(
        "run",
        "Simulate experiments",
        class = "btn-primary"
      ),
      
      p(
        class = "muted",
        "Click to run. The same settings and seed reproduce the batch; change the seed for new samples."
      ),
      
      tags$details(
        class = "assumptions",
        
        tags$summary(
          "Simulation assumptions",
          tags$span(
            class = "expand-hint hint-open",
            "Click to expand"
          ),
          tags$span(
            class = "expand-hint hint-close",
            "Click to collapse"
          )
        ),
        
        div(
          class = "assumptions-content",
          p(
            class = "muted",
            "Each experiment samples new participant sensitivities and new trials. True sensitivities are independent across tasks; observed estimates are paired by participant ID. RTs use standardized units."
          ),
          p(
            class = "muted",
            "Tests are two-sided at α = 0.05. Positive processing effects and positive sensitivity differences are required for their respective processing advantage results."
          ),
          p(
            class = "muted",
            "Awareness d′ comes from identification responses. Processing d′ comes from classifying RTs using each participant's observed median. Neither estimate uses true sensitivity."
          )
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
        p(
          class = "muted",
          "Curves show true sensitivities across people. Vertical markers show mean sensitivity δ."
        ),
        strong(
          "In real life, true population sensitivities are unknown and can only be estimated."
        )
      ),
      
      div(
        class = "card",
        uiOutput("repeat_heading"),
        p(
          "Each simulation produces new responses. Both analyses use the same observed data."
        ),
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
            uiOutput("separate_metrics"),
            h4("Significant results"),
            plotOutput("double_outcomes", height = "300px"),
            
            tags$ul(
              class = "plot-key",
              tags$li(
                strong("Both: "),
                "Awareness and positive processing are significant."
              ),
              tags$li(
                strong("Processing only: "),
                "Positive processing is significant, awareness is not. This is the highlighted double-test processing advantage pattern."
              ),
              tags$li(
                strong("Awareness only: "),
                "Awareness is significant, no significant positive processing effect."
              ),
              tags$li(
                strong("Neither: "),
                "Awareness is nonsignificant, no significant positive processing effect."
              )
            ),
            
            p(
              class = "muted",
              "Significant means p < 0.05. Awareness significance includes below-chance results. A significant negative processing effect is not counted as positive processing."
            ),
            p(
              strong("The problem: "),
              "Significant processing plus nonsignificant awareness does not establish a sensitivity difference."
            )
          )
        ),
        
        column(
          6,
          div(
            class = "card",
            h3(class = "method-title", "Direct comparison of d'"),
            uiOutput("comparison_metric"),
            h4("Evidence of processing advantage"),
            plotOutput("comparison_outcomes", height = "300px"),
            
            tags$ul(
              class = "plot-key",
              tags$li(
                strong("Processing advantage: "),
                "Processing sensitivity is higher, the mean estimated difference is positive and significant (p < 0.05)."
              ),
              tags$li(
                strong("No processing advantage: "),
                "The comparison does not support a processing advantage. This includes nonsignificant differences and significant awareness advantages."
              )
            ),
            
            uiOutput("comparison_summary"),
            p(
              strong("The advantage: "),
              "This analysis tests the sensitivity difference itself."
            )
          )
        )
      ),
      
      div(
        class = "card truth",
        h3("3 · Interpret the results"),
        uiOutput("interpretation"),
        uiOutput("disagreement"),
        p(
          class = "muted",
          "With few simulations, percentages can vary noticeably with the seed."
        )
      ),
      
      uiOutput("failure_details")
    )
  )
)

server = function(input, output, session) {
  batch = reactiveVal(NULL)
  
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
    
    if (!is.null(x)) {
      return(
        h3(
          sprintf(
            "2 · Experiment simulated %s times",
            format(x$attempted, big.mark = ",", trim = TRUE)
          )
        )
      )
    }
    
    b = input$B
    
    if (
      length(b) != 1L ||
      !is.finite(b) ||
      b != round(b) ||
      b < 20 ||
      b > 1000
    ) {
      return(h3("2 · Simulate the same experiment"))
    }
    
    h3(
      sprintf(
        "2 · Simulate the experiment %s times",
        format(b, big.mark = ",", trim = TRUE)
      )
    )
  })
  
  output$truth_text = renderUI({
    difference = input$delta_process - input$delta_aware
    
    tagList(
      p(
        sprintf(
          "Awareness δ = %.2f · Processing δ = %.2f · True difference = %+.2f",
          input$delta_aware,
          input$delta_process,
          difference
        )
      ),
      strong(
        if (abs(difference) < 1e-10)
          "Equal true mean sensitivities: no population processing advantage."
        else if (difference > 0)
          "A true population processing advantage exists."
        else
          "Awareness has higher true mean sensitivity: no population processing advantage."
      )
    )
  })
  
  output$population = renderPlot({
    q = sqrt(Q2)
    x = seq(-0.5 - 4 * q, 1.5 + 4 * q, length.out = 600)
    
    curves = rbind(
      data.frame(
        x = x,
        density = dnorm(x, input$delta_aware, q),
        task = "Awareness"
      ),
      data.frame(
        x = x,
        density = dnorm(x, input$delta_process, q),
        task = "Processing"
      )
    )
    
    curves$task = factor(
      curves$task,
      levels = c("Awareness", "Processing")
    )
    
    means = data.frame(
      task = c("Awareness", "Processing"),
      delta = c(input$delta_aware, input$delta_process)
    )
    
    ggplot(curves, aes(x, density, colour = task, fill = task)) +
      geom_area(
        alpha = 0.12,
        position = "identity",
        show.legend = FALSE
      ) +
      geom_line(aes(linetype = task), linewidth = 1.2) +
      geom_vline(
        data = means,
        aes(xintercept = delta, colour = task),
        linetype = "dashed",
        linewidth = 0.7,
        show.legend = FALSE
      ) +
      scale_colour_manual(values = COLS, name = NULL) +
      scale_fill_manual(values = COLS, name = NULL) +
      scale_linetype_manual(
        values = c(Awareness = "solid", Processing = "dashed"),
        name = NULL
      ) +
      labs(
        x = "True individual sensitivity d′",
        y = "Population density"
      ) +
      plot_theme() +
      theme(legend.position = "top")
  }, res = 110)
  
  observeEvent(input$run, {
    s = isolate(settings())
    
    if (!valid_batch_settings(s)) {
      showNotification(
        "Use 3–200 participants, 20–1000 experiments, even trial counts from 50–500, and an integer seed from 1 to 1,000,000,000.",
        type = "error"
      )
      return()
    }
    
    result = withProgress(
      message = "Simulating experiments",
      value = 0,
      {
        run_batch(
          s,
          alpha = ALPHA,
          on_progress = function(b, B) {
            setProgress(
              value = b / B,
              detail = sprintf("%d of %d", b, B)
            )
          }
        )
      }
    )
    
    batch(result)
  }, ignoreInit = TRUE)
  
  get_batch = reactive({
    x = batch()
    
    validate(
      need(
        !is.null(x),
        "Click “Simulate experiments” to see results."
      )
    )
    
    x
  })
  
  get_data = reactive({
    x = get_batch()
    
    validate(
      need(
        !is.null(x$data) && nrow(x$data) > 0,
        "No experiments could be analysed. Adjust settings and inspect the warning details."
      )
    )
    
    x$data
  })
  
  output$batch_status = renderUI({
    x = batch()
    
    if (is.null(x)) {
      return(p("Choose settings and click “Simulate experiments”."))
    }
    
    n = if (is.null(x$data)) 0L else nrow(x$data)
    
    if (!length(x$errors)) {
      return(
        p(sprintf("%d participants per experiment", x$settings$N))
      )
    }
    
    div(
      class = "warning",
      strong(
        sprintf(
          "%d of %d experiments could not be analysed.",
          length(x$errors),
          x$attempted
        )
      ),
      p(
        if (n > 0)
          sprintf(
            "Percentages use the remaining %d experiments. See analysis details below.",
            n
          )
        else
          "No results are available for this batch. Change the settings and simulate again."
      )
    )
  })
  
  output$stale_notice = renderUI({
    if (
      !is.null(batch()) &&
      !isTRUE(all.equal(settings(), batch()$settings))
    ) {
      div(
        class = "stale-alert",
        role = "alert",
        strong(
          "⚠ Settings changed: results still show the previous batch."
        ),
        p(
          "The heading shows the completed batch's repetition count. Click “Simulate experiments” to apply the new settings."
        )
      )
    }
  })
  
  output$failure_details = renderUI({
    x = batch()
    
    if (is.null(x) || !length(x$errors)) {
      return(NULL)
    }
    
    tags$details(
      tags$summary("Analysis details"),
      div(
        class = "card",
        tableOutput("errors"),
        p(
          class = "muted",
          "These are calculation failures, not nonsignificant results. Failed experiments are not replaced. Excluding them can affect the percentages."
        )
      )
    )
  })
  
  output$double_outcomes = renderPlot({
    dat = get_data()
    counts = as.integer(table(factor(dat$outcome, levels = 1:4)))
    
    chart = data.frame(
      label = factor(OUTCOMES, levels = OUTCOMES),
      percentage = 100 * counts / nrow(dat),
      highlight = seq_len(4) == 2L
    )
    
    ggplot(chart, aes(label, percentage, fill = highlight)) +
      geom_col(width = 0.65) +
      geom_text(
        aes(label = sprintf("%.0f%%", percentage)),
        vjust = -0.5,
        size = 4
      ) +
      scale_fill_manual(
        values = c("FALSE" = "#BBC7D5", "TRUE" = "#C77820")
      ) +
      scale_y_continuous(
        limits = c(0, 110),
        breaks = seq(0, 100, 25),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(x = NULL, y = "Experiments (%)") +
      plot_theme() +
      theme(
        panel.grid.major.x = element_blank(),
        axis.text.x = element_text(size = 10)
      )
  }, res = 110)
  
  output$double_summary = renderUI({
    dat = get_data()
    
    div(
      class = "warning primary-result",
      div(
        class = "big",
        sprintf(
          "%.0f%%",
          100 * mean(dat$double_processing_advantage)
        )
      ),
      strong(
        "Suggest a processing advantage from the double-test pattern."
      ),
      div(
        class = "muted",
        "Significant positive processing; nonsignificant awareness."
      )
    )
  })
  
  output$comparison_metric = renderUI({
    dat = get_data()
    
    div(
      class = "green primary-result",
      div(
        class = "big",
        sprintf(
          "%.0f%%",
          100 * mean(dat$comparison_processing_advantage)
        )
      ),
      strong(
        "Support a processing advantage in the sensitivity comparison."
      ),
      div(
        class = "muted",
        "Significant positive estimated sensitivity difference."
      )
    )
  })
  
  output$comparison_outcomes = renderPlot({
    dat = get_data()
    k = sum(dat$comparison_processing_advantage)
    
    chart = data.frame(
      label = factor(
        c("processing advantage", "No processing advantage"),
        levels = c("processing advantage", "No processing advantage")
      ),
      percentage = 100 * c(k, nrow(dat) - k) / nrow(dat)
    )
    
    ggplot(chart, aes(label, percentage, fill = label)) +
      geom_col(width = 0.55) +
      geom_text(
        aes(label = sprintf("%.0f%%", percentage)),
        vjust = -0.5,
        size = 4
      ) +
      scale_fill_manual(
        values = c(
          "processing advantage" = GREEN,
          "No processing advantage" = "#BBC7D5"
        )
      ) +
      scale_x_discrete(
        labels = c(
          "processing advantage" = "Processing\nadvantage",
          "No processing advantage" = "No processing\nadvantage"
        )
      ) +
      scale_y_continuous(
        limits = c(0, 110),
        breaks = seq(0, 100, 25),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(x = NULL, y = "Experiments (%)") +
      plot_theme() +
      theme(panel.grid.major.x = element_blank())
  }, res = 110)
  
  output$interpretation = renderUI({
    get_data()
    s = get_batch()$settings
    truth = s$delta_process - s$delta_aware
    
    tagList(
      strong(
        sprintf(
          "True population difference in this batch: %+.2f",
          truth
        )
      ),
      p(
        if (truth > 0)
          "A genuine processing advantage exists. The sensitivity-comparison percentage estimates how often it is detected. The double-test percentage counts only the separate-test pattern."
        else
          "No true population processing advantage exists."
      )
    )
  })
  
  output$disagreement = renderUI({
    dat = get_data()
    
    p(
      strong(
        sprintf(
          "%.0f%% showed the double t-test processing advantage pattern without support from the direct comparison of the estimated sensitivities.",
          100 * mean(
            dat$double_processing_advantage &
              !dat$comparison_processing_advantage
          )
        )
      )
    )
  })
  
  output$errors = renderTable({
    x = batch()
    req(!is.null(x), length(x$errors) > 0)
    
    tab = sort(table(x$errors), decreasing = TRUE)
    
    data.frame(
      Message = names(tab),
      Count = as.integer(tab)
    )
  }, striped = TRUE, spacing = "m")
}

# Launches the app in the browser/viewer
run_app = function(...) {
  shiny::runApp(shinyApp(ui, server), ...)
}