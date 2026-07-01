# Module: operating characteristics ---------------------------------------------
# ADEMP "Performance measures". Owns the (gated, cached) trial simulation and
# reports power / early-stopping / expected N / estimation measures, each with
# MCSE. Crucially, the FINAL superiority threshold used here can be the value
# calibrated on the Calibration tab, so the two tabs tell one story: "here is the
# threshold calibrated to 5% type I error under the null, and here is the power
# that same threshold buys under the alternative."

#' Operating-characteristics UI
#'
#' @param id Module id.
#' @return A `tagList` of the threshold selector, value boxes, figures, and table.
#' @importFrom shiny NS tagList textOutput tableOutput plotOutput uiOutput
#'   radioButtons conditionalPanel sliderInput
#' @noRd
mod_operating_chars_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::card(
      bslib::card_body(
        class = "py-2",
        bslib::layout_columns(
          col_widths = c(4, 5, 3),
          shiny::radioButtons(
            ns("thr_source"), "Final superiority threshold",
            choices = c("Calibrated to target type I error" = "cal",
                        "Manual" = "manual"),
            selected = "cal"
          ),
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'manual'", ns("thr_source")),
            shiny::sliderInput(ns("sup_final_manual"), "Manual threshold  P >=",
                               min = 0.90, max = 0.999, value = 0.975,
                               step = 0.001)
          ),
          shiny::uiOutput(ns("thr_badge"))
        )
      )
    ),
    bslib::layout_columns(
      col_widths = c(3, 3, 3, 3),
      bslib::value_box(
        title = shiny::textOutput(ns("declare_label")),
        value = shiny::textOutput(ns("vb_declare")),
        shiny::textOutput(ns("vb_declare_mcse")),
        theme = "primary", min_height = "150px"
      ),
      bslib::value_box(title = "Stop early: efficacy",
                       value = shiny::textOutput(ns("vb_eff")),
                       min_height = "150px"),
      bslib::value_box(title = "Stop early: futility",
                       value = shiny::textOutput(ns("vb_fut")),
                       min_height = "150px"),
      bslib::value_box(title = "Expected total N",
                       value = shiny::textOutput(ns("vb_n")),
                       min_height = "150px")
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
#' @param design A reactive of design inputs (from [mod_design_inputs_server()]).
#' @param controls The list returned by [mod_sim_controls_server()] (`run`,
#'   `settings`).
#' @param calibrated A reactive handle to the calibration result (from
#'   [mod_calibration_server()]); `NULL` until the first calibration completes.
#' @return Invisibly `NULL`; renders outputs.
#' @importFrom shiny moduleServer reactive req renderText renderUI renderPlot
#'   renderTable bindCache bindEvent withProgress tags
#' @noRd
mod_operating_chars_server <- function(id, design, controls, calibrated) {
  shiny::moduleServer(id, function(input, output, session) {

    # Single source of truth for the final threshold the engine uses.
    effective_threshold <- shiny::reactive({
      cal <- calibrated()
      if (identical(input$thr_source, "cal") && !is.null(cal)) {
        cal$threshold
      } else {
        input$sup_final_manual
      }
    })

    # Tell the reviewer which threshold is in force and where it came from.
    output$thr_badge <- shiny::renderUI({
      cal <- calibrated()
      if (identical(input$thr_source, "cal") && !is.null(cal)) {
        shiny::tags$span(
          class = "badge bg-success",
          sprintf("threshold %.3f  (calibrated to type I error %.1f%%, achieved %.1f%%)",
                  cal$threshold, 100 * cal$target, 100 * cal$type_i_error)
        )
      } else if (identical(input$thr_source, "cal")) {
        shiny::tags$span(class = "badge bg-warning text-dark",
                         "calibrating under the null...")
      } else {
        shiny::tags$span(class = "badge bg-secondary",
                         sprintf("threshold %.3f  (manual)", input$sup_final_manual))
      }
    })

    # Gated, cached simulation. Re-runs on the Run button OR when the effective
    # threshold changes (switching calibrated/manual, or a fresh calibration
    # landing) so the power shown always matches the threshold in the badge.
    # ignoreNULL = FALSE runs it once on load. bindCache must precede bindEvent.
    results <- shiny::reactive({
      d <- design()
      s <- controls$settings()
      shiny::req(d, s)
      shiny::withProgress(message = "Simulating trials...", value = 0.5, {
        run_trial_simulation(
          p_control = d$p_control, p_treat = d$p_treat,
          n_max = d$n_max, n_interim = d$n_interim,
          a0 = d$a0, b0 = d$b0,
          sup_interim = s$sup_interim, fut_interim = s$fut_interim,
          sup_final = effective_threshold(),
          n_sims = s$n_sims, n_draws = s$n_draws, seed = s$seed
        )
      })
    }) |>
      shiny::bindCache(design(), controls$settings(), effective_threshold()) |>
      shiny::bindEvent(controls$run(), effective_threshold(), ignoreNULL = FALSE)

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
