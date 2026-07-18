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

test_that("mod_design_inputs reports prior ESS = a0 + b0 with context", {
  shiny::testServer(mod_design_inputs_server, {
    session$setInputs(
      p_control = 0.3, p_treat = 0.45,
      n_max = 150, n_interim = 75, a0 = 1, b0 = 1
    )
    ess_html <- as.character(output$prior_ess$html)
    expect_match(ess_html, "Prior ESS per arm = a0 \\+ b0 = 2")
    expect_match(ess_html, "1.3% of the information at the final look")
    expect_match(ess_html, "2.7% at the interim")

    # Scales with the hyper-parameters.
    session$setInputs(a0 = 5, b0 = 5)
    expect_match(as.character(output$prior_ess$html), "= 10")
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
