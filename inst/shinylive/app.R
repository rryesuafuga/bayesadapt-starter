# inst/shinylive/app.R ---------------------------------------------------------
# bayesadapt - conjugate MVP (standalone, dependency-light)
#
# A two-arm Bayesian adaptive trial with a single interim analysis, using a
# CONJUGATE Beta-Binomial model (no MCMC) so it runs entirely in the browser via
# shinylive / WebAssembly. This is the fast public demo; the full golem app adds
# the ordinal proportional-odds (Stan) extension and multi-arm RAR.
#
# Decision rule (ADEMP "Methods"):
#   * Outcome: binary (success = good outcome) in each arm.
#   * Prior:   Beta(a0, b0) per arm; posterior is Beta(a0 + x, b0 + n - x).
#   * Decision quantity: posterior probability of benefit
#       p_sup = P(p_treatment > p_control | data), via Monte-Carlo draws.
#   * Interim (at n1/arm): stop for EFFICACY if p_sup >= sup_interim;
#                          stop for FUTILITY if p_sup <= fut_interim.
#   * Final  (at N/arm):   declare SUPERIORITY if p_sup >= sup_final.
#   (Predictive-probability futility is the planned upgrade in the full app.)
# ------------------------------------------------------------------------------

library(shiny)
library(bslib)

# ---- Simulation engine (pure base R) -----------------------------------------

simulate_trials <- function(p_control, p_treat, n_max, n_interim,
                            a0 = 1, b0 = 1,
                            sup_interim = 0.99, fut_interim = 0.10,
                            sup_final = 0.975,
                            n_sims = 1000, n_draws = 1500, seed = 1) {
  set.seed(seed)

  prob_superiority <- function(x_c, n_c, x_t, n_t) {
    pc <- rbeta(n_draws, a0 + x_c, b0 + n_c - x_c)
    pt <- rbeta(n_draws, a0 + x_t, b0 + n_t - x_t)
    mean(pt > pc)
  }

  decision <- character(n_sims)
  n_used   <- integer(n_sims)

  for (i in seq_len(n_sims)) {
    xc1 <- rbinom(1, n_interim, p_control)
    xt1 <- rbinom(1, n_interim, p_treat)
    p_sup <- prob_superiority(xc1, n_interim, xt1, n_interim)

    if (p_sup >= sup_interim) {
      decision[i] <- "efficacy"; n_used[i] <- 2L * n_interim
    } else if (p_sup <= fut_interim) {
      decision[i] <- "futility"; n_used[i] <- 2L * n_interim
    } else {
      xc2 <- xc1 + rbinom(1, n_max - n_interim, p_control)
      xt2 <- xt1 + rbinom(1, n_max - n_interim, p_treat)
      p_sup_f <- prob_superiority(xc2, n_max, xt2, n_max)
      decision[i] <- if (p_sup_f >= sup_final) "efficacy_final" else "inconclusive"
      n_used[i] <- 2L * n_max
    }
  }

  declared <- decision %in% c("efficacy", "efficacy_final")
  phat <- mean(declared)
  list(
    p_declare_sup   = phat,
    mcse_declare    = sqrt(phat * (1 - phat) / n_sims),
    p_stop_efficacy = mean(decision == "efficacy"),
    p_stop_futility = mean(decision == "futility"),
    e_n             = mean(n_used),
    n_used          = n_used,
    null            = isTRUE(all.equal(p_control, p_treat))
  )
}

# ---- UI ----------------------------------------------------------------------

ui <- page_sidebar(
  title = "bayesadapt - conjugate MVP (two-arm, binary)",
  sidebar = sidebar(
    width = 330,
    h6("Data-generating mechanism"),
    sliderInput("p_control", "True control success rate", 0, 1, 0.30, 0.01),
    sliderInput("p_treat",   "True treatment success rate", 0, 1, 0.45, 0.01),
    helpText("Set the two rates equal to read off the type I error."),
    hr(),
    h6("Design"),
    numericInput("n_max", "Max sample size per arm", 200, 20, 2000, 10),
    numericInput("n_interim", "Interim analysis at n/arm", 100, 10, 2000, 10),
    hr(),
    h6("Decision thresholds (posterior P of benefit)"),
    sliderInput("sup_interim", "Efficacy stop if P >=", 0.90, 0.999, 0.990, 0.001),
    sliderInput("fut_interim", "Futility stop if P <=", 0.00, 0.50, 0.10, 0.01),
    sliderInput("sup_final",   "Final superiority if P >=", 0.90, 0.999, 0.975, 0.001),
    hr(),
    h6("Simulation"),
    numericInput("n_sims", "Number of simulated trials", 1000, 200, 5000, 100),
    numericInput("seed", "Random seed", 1, 1, 1e6, 1),
    actionButton("run", "Run simulation", class = "btn-primary w-100")
  ),
  layout_columns(
    col_widths = c(3, 3, 3, 3),
    value_box(title = "Declares superiority", value = textOutput("vb_declare"), theme = "primary"),
    value_box(title = "Stop early: efficacy", value = textOutput("vb_eff")),
    value_box(title = "Stop early: futility", value = textOutput("vb_fut")),
    value_box(title = "Expected total N", value = textOutput("vb_n"))
  ),
  card(
    card_header("Distribution of total sample size"),
    plotOutput("hist_n", height = "260px")
  ),
  card(card_body(htmlOutput("interpretation")))
)

# ---- Server ------------------------------------------------------------------

server <- function(input, output, session) {

  res <- eventReactive(input$run, {
    validate(
      need(input$n_interim < input$n_max,
           "Interim n must be smaller than the max sample size per arm.")
    )
    simulate_trials(
      p_control   = input$p_control,
      p_treat     = input$p_treat,
      n_max       = input$n_max,
      n_interim   = input$n_interim,
      sup_interim = input$sup_interim,
      fut_interim = input$fut_interim,
      sup_final   = input$sup_final,
      n_sims      = input$n_sims,
      seed        = input$seed
    )
  }, ignoreNULL = FALSE)

  output$vb_declare <- renderText(sprintf("%.1f%% (+/-%.1f)",
                                          100 * res()$p_declare_sup,
                                          100 * res()$mcse_declare))
  output$vb_eff <- renderText(sprintf("%.1f%%", 100 * res()$p_stop_efficacy))
  output$vb_fut <- renderText(sprintf("%.1f%%", 100 * res()$p_stop_futility))
  output$vb_n   <- renderText(sprintf("%.0f", res()$e_n))

  output$hist_n <- renderPlot({
    r <- res()
    hist(r$n_used, breaks = 20, col = "#9FE1CB", border = "white",
         main = NULL, xlab = "Total sample size (both arms)",
         ylab = "Simulated trials")
    abline(v = r$e_n, lwd = 2, col = "#0F6E56")
  })

  output$interpretation <- renderUI({
    r <- res()
    label <- if (r$null) "type I error" else "power"
    HTML(sprintf(
      "<p>With these settings the design declares the treatment superior in
       <strong>%.1f%%</strong> of simulated trials (this is the <strong>%s</strong>,
       since the two true rates are %s), using an expected total of
       <strong>%.0f</strong> patients across both arms.</p>
       <p>Workflow: set the two true rates <em>equal</em> and tune the thresholds until the
       type I error sits at your target (e.g. 2.5-5%%); then raise the treatment rate to read
       the power at that calibrated threshold.</p>",
      100 * r$p_declare_sup, label,
      if (r$null) "equal" else "different", r$e_n
    ))
  })
}

shinyApp(ui, server)
