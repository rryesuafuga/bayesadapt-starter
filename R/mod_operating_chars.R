# Module: operating characteristics ---------------------------------------------
# ADEMP "Performance measures". Value boxes for the headline numbers, a full
# table with MCSE, and the sample-size / OC figures.

#' Operating-characteristics UI
#'
#' @param id Module id.
#' @return A `tagList` of value boxes, figures, and an OC table.
#' @importFrom shiny NS tagList textOutput tableOutput plotOutput
#' @noRd
mod_operating_chars_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::layout_columns(
      col_widths = c(3, 3, 3, 3),
      bslib::value_box(
        title = shiny::textOutput(ns("declare_label")),
        value = shiny::textOutput(ns("vb_declare")),
        shiny::textOutput(ns("vb_declare_mcse")),
        theme = "primary"
      ),
      bslib::value_box(title = "Stop early: efficacy",
                       value = shiny::textOutput(ns("vb_eff"))),
      bslib::value_box(title = "Stop early: futility",
                       value = shiny::textOutput(ns("vb_fut"))),
      bslib::value_box(title = "Expected total N",
                       value = shiny::textOutput(ns("vb_n")))
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        bslib::card_header("Distribution of total sample size"),
        shiny::plotOutput(ns("hist_n"), height = "300px")
      ),
      bslib::card(
        bslib::card_header("Operating characteristics (+/- MCSE)"),
        shiny::plotOutput(ns("oc_bars"), height = "300px")
      )
    ),
    bslib::card(
      bslib::card_header("All operating characteristics"),
      shiny::tableOutput(ns("oc_table"))
    )
  )
}

#' Operating-characteristics server
#'
#' @param id Module id.
#' @param results A reactive returning a [run_trial_simulation()]-style list with
#'   `per_trial` and `oc` elements (or `NULL` before the first run).
#' @return Invisibly `NULL`; renders outputs.
#' @importFrom shiny moduleServer req renderText renderPlot renderTable
#' @noRd
mod_operating_chars_server <- function(id, results) {
  shiny::moduleServer(id, function(input, output, session) {

    oc_value <- function(metric) {
      oc <- results()$oc
      oc[oc$metric == metric, ]
    }

    output$declare_label <- shiny::renderText({
      shiny::req(results())
      oc_value("p_declare")$label
    })
    output$vb_declare <- shiny::renderText({
      shiny::req(results())
      sprintf("%.1f%%", 100 * oc_value("p_declare")$value)
    })
    output$vb_declare_mcse <- shiny::renderText({
      shiny::req(results())
      sprintf("+/- %.1f%% MCSE", 100 * oc_value("p_declare")$mcse)
    })
    output$vb_eff <- shiny::renderText({
      shiny::req(results()); sprintf("%.1f%%", 100 * oc_value("p_stop_efficacy")$value)
    })
    output$vb_fut <- shiny::renderText({
      shiny::req(results()); sprintf("%.1f%%", 100 * oc_value("p_stop_futility")$value)
    })
    output$vb_n <- shiny::renderText({
      shiny::req(results()); sprintf("%.0f", oc_value("e_n")$value)
    })

    output$hist_n <- shiny::renderPlot({
      shiny::req(results())
      plot_sample_size(results()$per_trial)
    })
    output$oc_bars <- shiny::renderPlot({
      shiny::req(results())
      plot_oc_bars(results()$oc)
    })

    output$oc_table <- shiny::renderTable({
      shiny::req(results())
      oc <- results()$oc
      is_pct <- oc$metric != "e_n"
      data.frame(
        Measure = oc$label,
        Estimate = ifelse(is_pct,
                          sprintf("%.1f%%", 100 * oc$value),
                          sprintf("%.0f", oc$value)),
        MCSE = ifelse(is_pct,
                     sprintf("%.2f%%", 100 * oc$mcse),
                     sprintf("%.1f", oc$mcse)),
        check.names = FALSE
      )
    }, striped = TRUE, width = "100%")

    invisible(NULL)
  })
}
