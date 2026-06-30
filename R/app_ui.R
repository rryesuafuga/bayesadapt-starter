# Application UI ----------------------------------------------------------------

#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`. DO NOT REMOVE.
#' @return A bslib `page_navbar`.
#' @importFrom shiny tagList
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    golem_add_external_resources(),
    bslib::page_navbar(
      title = "bayesadapt",
      theme = bslib::bs_theme(version = 5, preset = "cosmo"),
      sidebar = bslib::sidebar(
        width = 340,
        mod_design_inputs_ui("design"),
        mod_sim_controls_ui("controls")
      ),
      bslib::nav_panel(
        title = "Operating characteristics",
        mod_operating_chars_ui("oc")
      ),
      bslib::nav_panel(
        title = "Calibration",
        mod_calibration_ui("calibration")
      ),
      bslib::nav_panel(
        title = "Methods (ADEMP)",
        bslib::card(
          bslib::card_body(shiny::uiOutput("methods_note"))
        )
      ),
      bslib::nav_spacer(),
      bslib::nav_item(
        shiny::tags$a("Source", href = "https://github.com/rryesuafuga/bayesadapt-starter",
                      target = "_blank")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external resources inside the Shiny
#' application.
#'
#' @return An HTML `head` tag list.
#' @importFrom shiny tags
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path("www", app_sys("app/www"))
  shiny::tags$head(
    shiny::tags$meta(name = "description",
                     content = "Bayesian adaptive clinical-trial simulator"),
    shiny::tags$title("bayesadapt")
  )
}
