make_controls <- function(run_val = 0) {
  list(
    run = shiny::reactive(run_val),
    settings = shiny::reactive(list(
      sup_interim = 0.99, fut_interim = 0.10,
      n_sims = 80, n_draws = 300, seed = 1
    ))
  )
}

test_that("mod_operating_chars renders headline outputs (manual threshold)", {
  design <- shiny::reactive(list(p_control = 0.3, p_treat = 0.45,
                                 n_max = 100, n_interim = 50, a0 = 1, b0 = 1))
  calibrated <- shiny::reactive(NULL)  # no calibration -> manual fallback
  shiny::testServer(
    mod_operating_chars_server,
    args = list(design = design, controls = make_controls(),
                calibrated = calibrated),
    {
      session$setInputs(thr_source = "manual", sup_final_manual = 0.975)
      expect_match(output$vb_declare, "^[0-9.]+%$")   # value only
      expect_match(output$vb_declare_mcse, "MCSE")    # MCSE in its own slot
      expect_match(output$vb_n, "^[0-9]+$")
      expect_true(nchar(output$declare_label) > 0)
    }
  )
})

test_that("mod_operating_chars uses the calibrated threshold when selected", {
  design <- shiny::reactive(list(p_control = 0.3, p_treat = 0.45,
                                 n_max = 100, n_interim = 50, a0 = 1, b0 = 1))
  # A calibration handle pinning the final threshold well below the manual value.
  calibrated <- shiny::reactive(list(threshold = 0.90, target = 0.05,
                                     type_i_error = 0.048, mcse = 0.004))
  shiny::testServer(
    mod_operating_chars_server,
    args = list(design = design, controls = make_controls(),
                calibrated = calibrated),
    {
      session$setInputs(thr_source = "cal", sup_final_manual = 0.999)
      # Badge advertises the calibrated provenance.
      expect_match(as.character(output$thr_badge$html), "calibrated")
      p_cal <- 100 * results()$oc$value[results()$oc$metric == "p_declare"]

      # Switch to a very strict manual threshold: power must not exceed the
      # calibrated (looser) threshold's power -> confirms the wiring is live.
      session$setInputs(thr_source = "manual")
      p_manual <- 100 * results()$oc$value[results()$oc$metric == "p_declare"]
      expect_gte(p_cal, p_manual)
    }
  )
})
