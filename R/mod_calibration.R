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
        bslib::layout_columns(
          col_widths = c(4, 4, 4),
          shiny::sliderInput(ns("target"), "Target type I error",
                             min = 0.01, max = 0.10, value = 0.05, step = 0.005),
          shiny::numericInput(ns("n_sims"), "Replicates (null)",
                              value = 2000, min = 200, max = 50000, step = 500),
          shiny::numericInput(ns("seed"), "Seed",
                              value = 1, min = 1, max = 1e6, step = 1)
        ),
        shiny::actionButton(ns("calibrate"), "Calibrate",
                            class = "btn-primary")
      )
    ),
    bslib::layout_columns(
      col_widths = c(4, 8),
      bslib::value_box(
        title = "Calibrated final threshold",
        value = shiny::textOutput(ns("vb_threshold")),
        shiny::textOutput(ns("vb_achieved")),
        theme = "primary"
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
#' @return Invisibly `NULL`; renders outputs.
#' @importFrom shiny moduleServer eventReactive req renderText renderPlot withProgress
#' @noRd
mod_calibration_server <- function(id, design, settings) {
  shiny::moduleServer(id, function(input, output, session) {

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
    })

    has_run <- shiny::reactive(isTRUE(shiny::isTruthy(input$calibrate)) &&
                                 input$calibrate > 0)

    output$vb_threshold <- shiny::renderText({
      if (!has_run()) return("--")
      sprintf("%.3f", cal()$threshold)
    })
    output$vb_achieved <- shiny::renderText({
      if (!has_run()) return("Click Calibrate to run under the null.")
      sprintf("type I error %s%s",
              fmt_oc(cal()$type_i_error, cal()$mcse),
              if (cal()$achieved_target) "" else "  (target not reachable on grid)")
    })
    output$curve <- shiny::renderPlot({
      if (!has_run()) {
        return(
          ggplot2::ggplot() +
            ggplot2::annotate("text", x = 0, y = 0,
                              label = "Press Calibrate to simulate under the null\nand grid-search the superiority threshold.",
                              size = 5, colour = "#6c757d") +
            ggplot2::theme_void()
        )
      }
      plot_calibration(cal())
    })

    invisible(NULL)
  })
}
