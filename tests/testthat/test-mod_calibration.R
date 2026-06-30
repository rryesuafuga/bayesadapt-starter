test_that("mod_calibration calibrates on demand under the null", {
  design <- shiny::reactive(list(
    p_control = 0.3, p_treat = 0.45,
    n_max = 100, n_interim = 50, a0 = 1, b0 = 1
  ))
  settings <- shiny::reactive(list(
    sup_interim = 0.99, fut_interim = 0.10, sup_final = 0.975,
    n_sims = 1000, n_draws = 300, seed = 1
  ))
  shiny::testServer(
    mod_calibration_server,
    args = list(design = design, settings = settings),
    {
      session$setInputs(target = 0.05, n_sims = 400, seed = 1, calibrate = 1)
      expect_match(output$vb_threshold, "^0\\.[0-9]+$")
      expect_match(output$vb_achieved, "type I error")
    }
  )
})
