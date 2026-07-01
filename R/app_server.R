# Application server -------------------------------------------------------------

#' The application server-side
#'
#' Orchestrates the modules and threads the calibrated threshold through so the
#' two tabs tell one story. The calibration module calibrates the final
#' superiority threshold to a target type I error under the null (auto-run on
#' load) and returns a handle; the operating-characteristics module reads power
#' at that same threshold under the alternative.
#'
#' @param input,output,session Internal parameters for `{shiny}`. DO NOT REMOVE.
#' @return Invisibly `NULL`.
#' @importFrom shiny renderUI
#' @noRd
app_server <- function(input, output, session) {

  design   <- mod_design_inputs_server("design")
  controls <- mod_sim_controls_server("controls")

  # Calibration returns a reactive handle to the calibrated threshold, which the
  # operating-characteristics module consumes to close the loop.
  calibrated <- mod_calibration_server("calibration", design, controls$settings)
  mod_operating_chars_server("oc", design, controls, calibrated)

  output$methods_note <- shiny::renderUI({
    path <- app_sys("methods", "ADEMP.md")
    if (file.exists(path) && requireNamespace("commonmark", quietly = TRUE)) {
      shiny::HTML(commonmark::markdown_html(paste(readLines(path), collapse = "\n")))
    } else if (file.exists(path)) {
      shiny::tags$pre(paste(readLines(path), collapse = "\n"))
    } else {
      shiny::p("ADEMP protocol not found.")
    }
  })

  invisible(NULL)
}
