#' Run the Shiny Application
#'
#' Launches the bayesadapt Bayesian adaptive clinical-trial simulator.
#'
#' @param onStart A function that will be called before the app is actually run.
#' @param options A named list of options passed to [shiny::shinyApp()].
#' @param enableBookmarking Bookmarking setting passed to [shiny::shinyApp()].
#' @param uiPattern A regular expression that will be applied to each `GET`
#'   request to determine whether the `ui` should be used to handle the request.
#' @param ... arguments to pass to golem_opts. See `?golem::get_golem_options`.
#'
#' @return A Shiny application object (invisibly when run interactively).
#' @export
#' @importFrom shiny shinyApp
run_app <- function(onStart = NULL,
                    options = list(),
                    enableBookmarking = NULL,
                    uiPattern = "/",
                    ...) {
  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}
