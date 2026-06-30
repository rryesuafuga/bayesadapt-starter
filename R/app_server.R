# Application server -------------------------------------------------------------

#' The application server-side
#'
#' Orchestrates the modules: design inputs and simulation controls feed a single
#' gated, cached simulation, whose results drive the operating-characteristics
#' display. The calibration module re-simulates under the null on demand.
#'
#' @param input,output,session Internal parameters for `{shiny}`. DO NOT REMOVE.
#' @return Invisibly `NULL`.
#' @importFrom shiny reactive bindCache bindEvent renderUI withProgress
#' @noRd
app_server <- function(input, output, session) {

  design   <- mod_design_inputs_server("design")
  controls <- mod_sim_controls_server("controls")

  # Gate the (potentially long) simulation behind the Run button and cache it on
  # the full input + seed signature so identical settings are not recomputed.
  # Order matters: bindCache() must precede bindEvent().
  results <- shiny::reactive({
    d <- design()
    s <- controls$settings()
    shiny::withProgress(message = "Simulating trials...", value = 0.5, {
      run_trial_simulation(
        p_control = d$p_control, p_treat = d$p_treat,
        n_max = d$n_max, n_interim = d$n_interim,
        a0 = d$a0, b0 = d$b0,
        sup_interim = s$sup_interim, fut_interim = s$fut_interim,
        sup_final = s$sup_final,
        n_sims = s$n_sims, n_draws = s$n_draws, seed = s$seed
      )
    })
  }) |>
    shiny::bindCache(design(), controls$settings()) |>
    shiny::bindEvent(controls$run(), ignoreNULL = FALSE)

  mod_operating_chars_server("oc", results)
  mod_calibration_server("calibration", design, controls$settings)

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
