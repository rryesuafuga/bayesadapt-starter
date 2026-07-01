test_that("mod_sim_controls exposes run and settings reactives", {
  shiny::testServer(mod_sim_controls_server, {
    session$setInputs(
      sup_interim = 0.99, fut_interim = 0.10,
      n_sims = 1000, n_draws = 2000, seed = 7, run = 1
    )
    out <- session$getReturned()
    expect_true(is.list(out))
    expect_true(all(c("run", "settings") %in% names(out)))

    s <- out$settings()
    expect_equal(s$sup_interim, 0.99)
    expect_equal(s$n_sims, 1000)
    expect_null(s$sup_final)       # final threshold now lives on the OC tab
    expect_identical(s$seed, 7L)   # sanitized to integer
  })
})
