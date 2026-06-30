test_that("plot helpers return ggplot objects", {
  res <- run_trial_simulation(0.3, 0.45, n_max = 100, n_interim = 50,
                              n_sims = 80, n_draws = 300, seed = 2)
  expect_s3_class(plot_sample_size(res$per_trial), "ggplot")
  expect_s3_class(plot_oc_bars(res$oc), "ggplot")

  null_paths <- simulate_paths(0.3, 0.3, n_max = 100, n_interim = 50,
                               n_sims = 200, n_draws = 300, seed = 3)
  cal <- calibrate_threshold(null_paths, target = 0.05,
                             grid = seq(0.9, 0.999, by = 0.01))
  expect_s3_class(plot_calibration(cal), "ggplot")
})
