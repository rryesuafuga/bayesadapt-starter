# Module: calibration -----------------------------------------------------------
# ADEMP "Aims": what final superiority threshold controls the type I error at the
# target under the null? Re-simulates under the null (treatment rate forced equal
# to the control rate) and grid-searches the final threshold.

#' Calibration UI
#'
#' @param id Module id.
#' @return A `tagList` with the target control, calibrate button, result value
#'   box, and the calibration curve.
#' @importFrom shiny NS sliderInput numericInput actionButton textOutput plotOutput
#' @noRd
mod_calibration_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::card(
      bslib::card_header("Calibrate the superiority threshold to a target type I error"),
      bslib::card_body(
        shiny::p(
          "Holds the design and interim rule fixed, regenerates the trial under ",
          shiny::strong("the null"), " (treatment rate set equal to control), and ",
          "grid-searches the final superiority threshold. The calibrated value is ",
          "the smallest threshold whose type I error is at or below the target."
        ),
        shiny::helpText(
          "Default 0.025 is the FDA one-sided standard; this design is one-sided ",
          "by construction (superiority is declared only when P(treatment > ",
          "control) is high), so the declaration rate under the null is a ",
          "one-sided error rate. Stricter targets need more null replicates to ",
          "keep the Monte-Carlo error well below the target."
        ),
        bslib::layout_columns(
          col_widths = c(4, 4, 4),
          shiny::sliderInput(ns("target"), "Target type I error (one-sided)",
                             min = 0.01, max = 0.10, value = 0.025, step = 0.005),
          shiny::numericInput(ns("n_sims"), "Replicates (null)",
                              value = 3000, min = 200, max = 50000, step = 500),
          shiny::numericInput(ns("seed"), "Seed",
                              value = 1, min = 1, max = 1e6, step = 1)
        ),
        shiny::actionButton(ns("calibrate"), "Calibrate",
                            class = "btn-primary mt-3")
      )
    ),
    bslib::layout_columns(
      col_widths = c(4, 8),
      bslib::value_box(
        title = "Calibrated final threshold",
        value = shiny::textOutput(ns("vb_threshold")),
        shiny::textOutput(ns("vb_achieved")),
        theme = "primary", min_height = "160px"
      ),
      bslib::card(
        bslib::card_header("Calibration curve"),
        shiny::plotOutput(ns("curve"), height = "320px")
      )
    )
  )
}

#' Calibration server
#'
#' @param id Module id.
#' @param design A reactive of design inputs (from [mod_design_inputs_server()]).
#' @param settings A reactive of simulation settings (interim thresholds, draws).
#' @return A reactive handle to the current calibration result (a list with
#'   `threshold`, `type_i_error`, `mcse`, `target`, `curve`, ...), or `NULL`
#'   before the first calibration completes. The operating-characteristics
#'   module consumes this to read power at the calibrated threshold.
#' @importFrom shiny moduleServer eventReactive req renderText renderPlot withProgress
#' @noRd
mod_calibration_server <- function(id, design, settings) {
  shiny::moduleServer(id, function(input, output, session) {

    # `ignoreNULL = FALSE` makes this fire once on load (button value 0) as well
    # as on every click, so the type-I-error exhibit is populated immediately —
    # a reviewer sees the payoff without hunting for a button.
    cal <- shiny::eventReactive(input$calibrate, {
      d <- design()
      s <- settings()
      shiny::req(d, s)
      shiny::withProgress(message = "Calibrating under the null...", value = 0.5, {
        null_paths <- simulate_paths(
          p_control = d$p_control, p_treat = d$p_control,  # null: equal rates
          n_max = d$n_max, n_interim = d$n_interim,
          a0 = d$a0, b0 = d$b0,
          n_sims = input$n_sims, n_draws = s$n_draws,
          seed = sanitize_seed(input$seed)
        )
        calibrate_threshold(
          null_paths, target = input$target,
          sup_interim = s$sup_interim, fut_interim = s$fut_interim
        )
      })
    }, ignoreNULL = FALSE)

    output$vb_threshold <- shiny::renderText({
      shiny::req(cal())
      sprintf("%.3f", cal()$threshold)
    })
    output$vb_achieved <- shiny::renderText({
      shiny::req(cal())
      sprintf("type I error %s%s",
              fmt_oc(cal()$type_i_error, cal()$mcse),
              if (cal()$achieved_target) "" else "  (target not reachable on grid)")
    })
    output$curve <- shiny::renderPlot({
      shiny::req(cal())
      plot_calibration(cal())
    })

    # Read-only handle returned to the app server for wiring into the OC tab.
    cal
  })
}
