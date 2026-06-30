test_that("mod_design_inputs returns validated inputs", {
  shiny::testServer(mod_design_inputs_server, {
    session$setInputs(
      p_control = 0.3, p_treat = 0.45,
      n_max = 150, n_interim = 75, a0 = 1, b0 = 1
    )
    d <- session$getReturned()()
    expect_equal(d$p_control, 0.3)
    expect_equal(d$n_max, 150)
    expect_equal(d$n_interim, 75)
  })
})

test_that("mod_design_inputs errors when interim >= max", {
  shiny::testServer(mod_design_inputs_server, {
    session$setInputs(
      p_control = 0.3, p_treat = 0.45,
      n_max = 50, n_interim = 75, a0 = 1, b0 = 1
    )
    expect_error(session$getReturned()())
  })
})
