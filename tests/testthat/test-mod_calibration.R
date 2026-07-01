test_that("mod_calibration auto-calibrates on load and returns a handle", {
  design <- shiny::reactive(list(
    p_control = 0.3, p_treat = 0.45,
    n_max = 100, n_interim = 50, a0 = 1, b0 = 1
  ))
  settings <- shiny::reactive(list(
    sup_interim = 0.99, fut_interim = 0.10,
    n_sims = 1000, n_draws = 300, seed = 1
  ))
  shiny::testServer(
    mod_calibration_server,
    args = list(design = design, settings = settings),
    {
      # No Calibrate click: auto-run on load populates the exhibit.
      session$setInputs(target = 0.05, n_sims = 400, seed = 1)
      expect_match(output$vb_threshold, "^0\\.[0-9]+$")
      expect_match(output$vb_achieved, "type I error")

      # The module returns a read-only reactive handle to the result.
      handle <- session$getReturned()
      expect_true(shiny::is.reactive(handle))
      expect_true(is.list(handle()))
      expect_true(is.numeric(handle()$threshold))
      expect_true(handle()$threshold >= 0.9 && handle()$threshold <= 0.999)

      # Re-calibrating on click still works.
      session$setInputs(target = 0.025, calibrate = 1)
      expect_match(output$vb_threshold, "^0\\.[0-9]+$")
    }
  )
})
