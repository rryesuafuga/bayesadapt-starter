test_that("mod_operating_chars renders headline outputs", {
  res <- run_trial_simulation(0.3, 0.45, n_max = 100, n_interim = 50,
                              n_sims = 80, n_draws = 300, seed = 1)
  shiny::testServer(
    mod_operating_chars_server,
    args = list(results = shiny::reactive(res)),
    {
      expect_type(output$vb_declare, "character")
      expect_match(output$vb_declare, "^[0-9.]+%$")  # value only, e.g. "79.6%"
      expect_match(output$vb_declare_mcse, "MCSE")   # MCSE in its own slot
      expect_match(output$vb_n, "^[0-9]+$")          # expected N, integer string
      expect_true(nchar(output$declare_label) > 0)
    }
  )
})
