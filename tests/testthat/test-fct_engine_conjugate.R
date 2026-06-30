test_that("posterior_benefit returns a coherent superiority probability", {
  set.seed(1)
  # Strong treatment effect -> posterior probability of benefit near 1.
  pb <- posterior_benefit(x_c = 20, n_c = 100, x_t = 60, n_t = 100)
  expect_true(pb$p_superiority > 0.99)
  expect_true(pb$log_or_mean > 0)
  expect_true(pb$log_or_lwr < pb$log_or_upr)

  # No difference -> probability near 0.5.
  set.seed(2)
  pb0 <- posterior_benefit(x_c = 40, n_c = 100, x_t = 40, n_t = 100)
  expect_gt(pb0$p_superiority, 0.3)
  expect_lt(pb0$p_superiority, 0.7)
})

test_that("simulate_paths returns the expected shape and attributes", {
  paths <- simulate_paths(0.3, 0.45, n_max = 100, n_interim = 50,
                          n_sims = 50, n_draws = 500, seed = 1)
  expect_s3_class(paths, "data.frame")
  expect_equal(nrow(paths), 50)
  expect_setequal(
    names(paths),
    c("p_sup_1", "est_1", "lwr_1", "upr_1",
      "p_sup_2", "est_2", "lwr_2", "upr_2")
  )
  expect_true(all(paths$p_sup_1 >= 0 & paths$p_sup_1 <= 1))
  expect_false(attr(paths, "is_null"))
  expect_equal(attr(paths, "n_max"), 100)
})

test_that("simulate_paths flags the null and is reproducible by seed", {
  p1 <- simulate_paths(0.3, 0.3, n_max = 100, n_interim = 50,
                       n_sims = 30, n_draws = 300, seed = 7)
  p2 <- simulate_paths(0.3, 0.3, n_max = 100, n_interim = 50,
                       n_sims = 30, n_draws = 300, seed = 7)
  expect_true(attr(p1, "is_null"))
  expect_equal(attr(p1, "true_log_or"), 0)
  expect_identical(p1$p_sup_1, p2$p_sup_1)  # same seed -> identical
})

test_that("simulate_paths validates the interim < max constraint", {
  expect_error(
    simulate_paths(0.3, 0.45, n_max = 50, n_interim = 50, n_sims = 5),
    regexp = "n_max > n_interim"
  )
})

test_that("apply_decision partitions every trial into one decision", {
  paths <- simulate_paths(0.3, 0.45, n_max = 100, n_interim = 50,
                          n_sims = 80, n_draws = 500, seed = 3)
  d <- apply_decision(paths, sup_interim = 0.99,
                      fut_interim = 0.10, sup_final = 0.975)
  expect_setequal(
    unique(d$decision),
    intersect(unique(d$decision),
              c("efficacy", "futility", "efficacy_final", "inconclusive"))
  )
  expect_equal(nrow(d), 80)
  # declared == efficacy OR efficacy_final.
  expect_equal(d$declared,
               d$decision %in% c("efficacy", "efficacy_final"))
  # Interim stops use half the patients of a full trial.
  expect_true(all(d$n_used[d$stopped_interim] == 2 * 50))
  expect_true(all(d$n_used[!d$stopped_interim] == 2 * 100))
})

test_that("a higher final threshold never increases declarations", {
  paths <- simulate_paths(0.3, 0.45, n_max = 120, n_interim = 60,
                          n_sims = 200, n_draws = 500, seed = 5)
  lo <- mean(apply_decision(paths, 0.99, 0.10, 0.95)$declared)
  hi <- mean(apply_decision(paths, 0.99, 0.10, 0.999)$declared)
  expect_gte(lo, hi)
})

test_that("calibrate_threshold controls type I error under the null", {
  null_paths <- simulate_paths(0.3, 0.3, n_max = 120, n_interim = 60,
                               n_sims = 800, n_draws = 600, seed = 11)
  cal <- calibrate_threshold(null_paths, target = 0.05,
                             grid = seq(0.9, 0.999, by = 0.005),
                             sup_interim = 0.99, fut_interim = 0.10)
  expect_true(cal$threshold %in% seq(0.9, 0.999, by = 0.005))
  # Achieved type I error should be at or below target (within MCSE tolerance).
  expect_lte(cal$type_i_error, cal$target + 3 * cal$mcse)
  # The curve is monotone non-increasing in the threshold.
  expect_true(all(diff(cal$curve$type_i_error) <= 1e-8))
})

test_that("run_trial_simulation bundles paths, per_trial and oc", {
  res <- run_trial_simulation(0.3, 0.45, n_max = 100, n_interim = 50,
                              n_sims = 60, n_draws = 400, seed = 9)
  expect_named(res, c("paths", "per_trial", "oc"))
  expect_s3_class(res$oc, "data.frame")
  expect_true("p_declare" %in% res$oc$metric)
})
