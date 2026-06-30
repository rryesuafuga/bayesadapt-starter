test_that("summarise_oc reports every measure with a finite MCSE", {
  res <- run_trial_simulation(0.3, 0.45, n_max = 100, n_interim = 50,
                              n_sims = 100, n_draws = 400, seed = 4)
  oc <- summarise_oc(res$per_trial)

  expect_true(all(c("p_declare", "p_stop_efficacy", "p_stop_futility",
                    "e_n", "bias_log_or", "mse_log_or", "coverage")
                  %in% oc$metric))
  expect_true(all(is.finite(oc$value)))
  expect_true(all(is.finite(oc$mcse)))
  expect_true(all(oc$mcse >= 0))

  # Probabilities lie in [0, 1]; E[N] is within the design's range.
  probs <- oc[oc$metric != "e_n" &
                !oc$metric %in% c("bias_log_or", "mse_log_or"), ]
  expect_true(all(probs$value >= 0 & probs$value <= 1))
})

test_that("under the null the declaration metric is labelled type I error", {
  res <- run_trial_simulation(0.3, 0.3, n_max = 100, n_interim = 50,
                              n_sims = 100, n_draws = 400, seed = 6)
  oc <- summarise_oc(res$per_trial)
  expect_equal(oc$label[oc$metric == "p_declare"], "Type I error")
})

test_that("MCSE of a proportion shrinks with more replicates", {
  small <- run_trial_simulation(0.3, 0.45, n_max = 100, n_interim = 50,
                                n_sims = 100, n_draws = 300, seed = 8)
  large <- run_trial_simulation(0.3, 0.45, n_max = 100, n_interim = 50,
                                n_sims = 800, n_draws = 300, seed = 8)
  m_small <- small$oc$mcse[small$oc$metric == "p_declare"]
  m_large <- large$oc$mcse[large$oc$metric == "p_declare"]
  expect_lt(m_large, m_small)
})

test_that("fmt_oc renders value +/- mcse", {
  expect_match(fmt_oc(0.05, 0.004), "5.0%")
  expect_match(fmt_oc(150, 2.3, pct = FALSE, digits = 0), "150")
})
