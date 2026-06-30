# Module: simulation controls ---------------------------------------------------
# Decision thresholds, replicate count, seed, and the Run button. Long runs are
# gated behind the button via `eventReactive` so the app never recomputes on
# incidental input changes.

#' Simulation-controls UI
#'
#' @param id Module id.
#' @return A bslib `card` of decision thresholds and simulation controls.
#' @importFrom shiny NS sliderInput numericInput actionButton hr
#' @noRd
mod_sim_controls_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    bslib::card_header("Methods - decision rule & simulation"),
    bslib::card_body(
      shiny::h6("Decision thresholds  P(benefit)"),
      shiny::sliderInput(ns("sup_interim"), "Efficacy stop if P >=",
                         min = 0.90, max = 0.999, value = 0.99, step = 0.001),
      shiny::sliderInput(ns("fut_interim"), "Futility stop if P <=",
                         min = 0.00, max = 0.50, value = 0.10, step = 0.01),
      shiny::sliderInput(ns("sup_final"), "Final superiority if P >=",
                         min = 0.90, max = 0.999, value = 0.975, step = 0.001),
      shiny::hr(),
      shiny::h6("Monte-Carlo simulation"),
      shiny::numericInput(ns("n_sims"), "Number of simulated trials",
                          value = 1000, min = 100, max = 20000, step = 100),
      shiny::numericInput(ns("n_draws"), "Posterior draws per analysis",
                          value = 2000, min = 200, max = 20000, step = 500),
      shiny::numericInput(ns("seed"), "Random seed",
                          value = 1, min = 1, max = 1e6, step = 1),
      shiny::actionButton(ns("run"), "Run simulation",
                          class = "btn-primary w-100")
    )
  )
}

#' Simulation-controls server
#'
#' @param id Module id.
#' @return A list with `run` (the action-button reactive) and `settings`
#'   (a reactive list of thresholds and Monte-Carlo settings).
#' @importFrom shiny moduleServer reactive
#' @noRd
mod_sim_controls_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    list(
      run = shiny::reactive(input$run),
      settings = shiny::reactive({
        list(
          sup_interim = input$sup_interim,
          fut_interim = input$fut_interim,
          sup_final   = input$sup_final,
          n_sims      = input$n_sims,
          n_draws     = input$n_draws,
          seed        = sanitize_seed(input$seed)
        )
      })
    )
  })
}
