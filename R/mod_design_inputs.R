# Module: design inputs ---------------------------------------------------------
# ADEMP "Data-generating mechanism" + "Methods" (prior). Captures the true arm
# rates, the accrual / interim schedule, and the conjugate Beta prior.

#' Design-inputs UI
#'
#' @param id Module id.
#' @return A bslib `card` of design controls.
#' @importFrom shiny NS sliderInput numericInput helpText hr tagList uiOutput
#' @noRd
mod_design_inputs_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    bslib::card_header("Design - data-generating mechanism & prior"),
    bslib::card_body(
      shiny::h6("True success rates"),
      shiny::sliderInput(ns("p_control"), "Control success rate",
                         min = 0.01, max = 0.99, value = 0.30, step = 0.01),
      shiny::sliderInput(ns("p_treat"), "Treatment success rate",
                         min = 0.01, max = 0.99, value = 0.45, step = 0.01),
      shiny::helpText("Set the two rates equal to simulate under the null and read off the type I error."),
      shiny::hr(),
      shiny::h6("Accrual & interim schedule"),
      shiny::numericInput(ns("n_max"), "Max sample size per arm",
                          value = 150, min = 20, max = 2000, step = 10),
      shiny::numericInput(ns("n_interim"), "Interim analysis at n / arm",
                          value = 75, min = 10, max = 2000, step = 10),
      shiny::hr(),
      shiny::h6("Prior  Beta(a0, b0)  per arm"),
      # Pseudo-observation convention: the prior contributes a0 pseudo-successes
      # and b0 pseudo-failures, so Beta(1, 1) is the uniform prior with ESS 2.
      shiny::numericInput(ns("a0"), "a0 (prior pseudo-successes)",
                          value = 1, min = 0.01, max = 100, step = 0.5),
      shiny::numericInput(ns("b0"), "b0 (prior pseudo-failures)",
                          value = 1, min = 0.01, max = 100, step = 0.5),
      shiny::uiOutput(ns("prior_ess"))
    )
  )
}

#' Design-inputs server
#'
#' @param id Module id.
#' @return A reactive list of validated design inputs.
#' @importFrom shiny moduleServer reactive req validate need renderUI tags
#' @noRd
mod_design_inputs_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {

    # Prior effective sample size (ESS). For a conjugate Beta(a0, b0) prior the
    # posterior is Beta(a0 + x, b0 + n - x), so the prior behaves exactly like
    # a0 + b0 extra patients per arm. Report it as a fraction of the information
    # at each look (ESS / n), which is why the prior bites harder at the interim.
    output$prior_ess <- shiny::renderUI({
      shiny::req(input$a0, input$b0, input$n_max, input$n_interim)
      ess <- input$a0 + input$b0
      pct_final   <- 100 * ess / input$n_max
      pct_interim <- 100 * ess / input$n_interim
      shiny::tags$p(
        class = "text-muted small mt-1",
        shiny::tags$strong(sprintf("Prior ESS per arm = a0 + b0 = %.1f", ess)),
        sprintf(" -- about %.1f%% of the information at the final look (n = %d/arm), %.1f%% at the interim (n = %d/arm).",
                pct_final, as.integer(input$n_max),
                pct_interim, as.integer(input$n_interim))
      )
    })

    shiny::reactive({
      shiny::req(input$n_max, input$n_interim, input$a0, input$b0)
      shiny::validate(
        shiny::need(input$n_interim < input$n_max,
                    "Interim n must be smaller than the max sample size per arm.")
      )
      list(
        p_control = input$p_control,
        p_treat   = input$p_treat,
        n_max     = input$n_max,
        n_interim = input$n_interim,
        a0        = input$a0,
        b0        = input$b0
      )
    })
  })
}
