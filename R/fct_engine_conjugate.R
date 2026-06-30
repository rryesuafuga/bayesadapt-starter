# Conjugate Beta-Binomial engine -----------------------------------------------
# Two-arm, binary-outcome Bayesian adaptive design with a single interim look.
# Pure base R (only `stats`) so the identical logic also runs in the browser via
# shinylive / WebAssembly (see inst/shinylive/app.R). No MCMC: the per-arm
# posterior is conjugate Beta, and the two-arm comparison is a quick Monte-Carlo
# draw from the two Beta posteriors.
#
# ADEMP "Methods": Beta(a0, b0) prior per arm; posterior Beta(a0 + x, b0 + n - x);
# decision quantity p_sup = P(p_treatment > p_control | data); estimand the
# log odds-ratio beta = logit(p_t) - logit(p_c).
#
# The design intentionally separates DATA GENERATION (`simulate_paths()`) from the
# DECISION RULE (`apply_decision()`): both the interim and the final posterior
# summaries are simulated for every trial, so thresholds can be swept cheaply
# over a single simulated data set. This is what makes `calibrate_threshold()`
# fast and exact rather than re-simulating per candidate threshold.

#' Posterior probability of benefit and treatment-effect summaries
#'
#' Draws from the two conjugate Beta posteriors and summarises the comparison.
#' For a `Beta(a0, b0)` prior and `x` successes in `n`, the posterior is
#' `Beta(a0 + x, b0 + n - x)`.
#'
#' @param x_c,n_c Successes and sample size in the control arm.
#' @param x_t,n_t Successes and sample size in the treatment arm.
#' @param a0,b0 Beta prior hyper-parameters (default `Beta(1, 1)`, uniform).
#' @param n_draws Number of Monte-Carlo draws from each posterior.
#'
#' @return A list with the posterior probability of benefit
#'   `p_superiority = P(p_t > p_c | data)` and posterior summaries of the
#'   log odds-ratio: `log_or_mean`, and the 2.5%/97.5% credible limits
#'   `log_or_lwr`, `log_or_upr`.
#'
#' @examples
#' posterior_benefit(x_c = 30, n_c = 100, x_t = 45, n_t = 100)
#'
#' @importFrom stats rbeta qlogis quantile
#' @export
posterior_benefit <- function(x_c, n_c, x_t, n_t,
                              a0 = 1, b0 = 1, n_draws = 2000) {
  pc <- rbeta(n_draws, a0 + x_c, b0 + n_c - x_c)
  pt <- rbeta(n_draws, a0 + x_t, b0 + n_t - x_t)
  log_or <- qlogis(pt) - qlogis(pc)
  qs <- quantile(log_or, c(0.025, 0.975), names = FALSE)
  list(
    p_superiority = mean(pt > pc),
    log_or_mean   = mean(log_or),
    log_or_lwr    = qs[1],
    log_or_upr    = qs[2]
  )
}

#' Simulate adaptive-trial sampling paths
#'
#' Generates `n_sims` two-arm trials with one interim look. For every trial both
#' the interim posterior summary (at `n_interim` per arm) and the final posterior
#' summary (at `n_max` per arm) are computed, regardless of whether a real trial
#' would have stopped early. This makes the decision rule a pure function of the
#' thresholds (see [apply_decision()]) and lets [calibrate_threshold()] sweep
#' thresholds over a single simulated data set.
#'
#' @param p_control,p_treat True control / treatment success probabilities. Set
#'   them equal to simulate under the null (the type I error scenario).
#' @param n_max Maximum sample size per arm.
#' @param n_interim Per-arm sample size at the interim analysis (`< n_max`).
#' @param a0,b0 Beta prior hyper-parameters.
#' @param n_sims Number of simulated trials.
#' @param n_draws Posterior Monte-Carlo draws per analysis.
#' @param seed Random seed for reproducibility.
#'
#' @return A data frame with one row per simulated trial and columns
#'   `p_sup_1`, `est_1`, `lwr_1`, `upr_1` (interim) and `p_sup_2`, `est_2`,
#'   `lwr_2`, `upr_2` (final). Attributes `true_log_or`, `is_null`, and the
#'   design (`n_max`, `n_interim`) are attached for downstream use.
#'
#' @examples
#' paths <- simulate_paths(0.3, 0.3, n_max = 150, n_interim = 75, n_sims = 200)
#' attr(paths, "is_null")
#'
#' @importFrom stats rbinom qlogis
#' @export
simulate_paths <- function(p_control, p_treat, n_max, n_interim,
                           a0 = 1, b0 = 1,
                           n_sims = 1000, n_draws = 2000, seed = 1) {
  stopifnot(
    p_control >= 0, p_control <= 1, p_treat >= 0, p_treat <= 1,
    n_interim >= 1, n_max > n_interim,
    n_sims >= 1, n_draws >= 1
  )
  set.seed(as.integer(seed))

  out <- data.frame(
    p_sup_1 = numeric(n_sims), est_1 = numeric(n_sims),
    lwr_1 = numeric(n_sims), upr_1 = numeric(n_sims),
    p_sup_2 = numeric(n_sims), est_2 = numeric(n_sims),
    lwr_2 = numeric(n_sims), upr_2 = numeric(n_sims)
  )

  for (i in seq_len(n_sims)) {
    # Stage 1 (interim): accrue n_interim per arm.
    xc1 <- rbinom(1L, n_interim, p_control)
    xt1 <- rbinom(1L, n_interim, p_treat)
    pb1 <- posterior_benefit(xc1, n_interim, xt1, n_interim, a0, b0, n_draws)

    # Stage 2 (final): accrue the remainder to n_max per arm.
    xc2 <- xc1 + rbinom(1L, n_max - n_interim, p_control)
    xt2 <- xt1 + rbinom(1L, n_max - n_interim, p_treat)
    pb2 <- posterior_benefit(xc2, n_max, xt2, n_max, a0, b0, n_draws)

    out$p_sup_1[i] <- pb1$p_superiority
    out$est_1[i]   <- pb1$log_or_mean
    out$lwr_1[i]   <- pb1$log_or_lwr
    out$upr_1[i]   <- pb1$log_or_upr
    out$p_sup_2[i] <- pb2$p_superiority
    out$est_2[i]   <- pb2$log_or_mean
    out$lwr_2[i]   <- pb2$log_or_lwr
    out$upr_2[i]   <- pb2$log_or_upr
  }

  attr(out, "true_log_or") <- qlogis(p_treat) - qlogis(p_control)
  attr(out, "is_null")     <- isTRUE(all.equal(p_control, p_treat))
  attr(out, "n_max")       <- n_max
  attr(out, "n_interim")   <- n_interim
  out
}

#' Apply the adaptive decision rule to simulated paths
#'
#' Turns simulated paths (see [simulate_paths()]) into per-trial decisions for a
#' given set of posterior-probability thresholds. The interim look can stop for
#' EFFICACY (`p_sup_1 >= sup_interim`) or FUTILITY (`p_sup_1 <= fut_interim`);
#' trials that continue declare SUPERIORITY at the final look when
#' `p_sup_2 >= sup_final`.
#'
#' @param paths A data frame from [simulate_paths()].
#' @param sup_interim Interim efficacy-stopping threshold.
#' @param fut_interim Interim futility-stopping threshold.
#' @param sup_final Final superiority threshold.
#'
#' @return A data frame with one row per trial: `decision` (one of `efficacy`,
#'   `futility`, `efficacy_final`, `inconclusive`), `declared` (logical:
#'   superiority declared at either look), `stopped_interim`, `n_used` (total
#'   patients across both arms), and the treatment-effect estimate `est_log_or`
#'   with credible limits `ci_lwr`, `ci_upr` taken at the stopping analysis.
#'   The `true_log_or` / `is_null` attributes are carried through.
#'
#' @examples
#' paths <- simulate_paths(0.3, 0.45, n_max = 150, n_interim = 75, n_sims = 200)
#' decided <- apply_decision(paths, sup_interim = 0.99,
#'                           fut_interim = 0.10, sup_final = 0.975)
#' table(decided$decision)
#'
#' @export
apply_decision <- function(paths, sup_interim = 0.99,
                           fut_interim = 0.10, sup_final = 0.975) {
  stopifnot(
    is.data.frame(paths),
    fut_interim <= sup_interim, sup_interim <= 1, sup_final <= 1
  )
  n_max     <- attr(paths, "n_max")
  n_interim <- attr(paths, "n_interim")

  stop_eff <- paths$p_sup_1 >= sup_interim
  stop_fut <- paths$p_sup_1 <= fut_interim
  stopped_interim <- stop_eff | stop_fut

  decision <- character(nrow(paths))
  decision[stop_eff] <- "efficacy"
  decision[stop_fut] <- "futility"
  cont <- !stopped_interim
  decision[cont] <- ifelse(paths$p_sup_2[cont] >= sup_final,
                           "efficacy_final", "inconclusive")

  declared <- decision %in% c("efficacy", "efficacy_final")
  n_used   <- ifelse(stopped_interim, 2L * n_interim, 2L * n_max)

  # Estimand reported at the analysis that ended the trial.
  est_log_or <- ifelse(stopped_interim, paths$est_1, paths$est_2)
  ci_lwr     <- ifelse(stopped_interim, paths$lwr_1, paths$lwr_2)
  ci_upr     <- ifelse(stopped_interim, paths$upr_1, paths$upr_2)

  out <- data.frame(
    decision = decision, declared = declared,
    stopped_interim = stopped_interim, n_used = n_used,
    est_log_or = est_log_or, ci_lwr = ci_lwr, ci_upr = ci_upr,
    stringsAsFactors = FALSE
  )
  attr(out, "true_log_or") <- attr(paths, "true_log_or")
  attr(out, "is_null")     <- attr(paths, "is_null")
  out
}

#' Calibrate the final superiority threshold to a target type I error
#'
#' Sweeps the final superiority threshold over a grid and, for each candidate,
#' computes the declaration rate under the supplied (null) paths. Because higher
#' thresholds give lower declaration rates, the calibrated threshold is the
#' smallest grid value whose type I error is at or below the target — the
#' conservative choice. Report the achieved type I error +/- its Monte-Carlo
#' standard error.
#'
#' @param null_paths Paths from [simulate_paths()] generated under the null
#'   (`p_control == p_treat`).
#' @param target Target type I error (e.g. `0.05`).
#' @param grid Grid of candidate final superiority thresholds.
#' @param sup_interim,fut_interim Interim thresholds held fixed during the sweep.
#'
#' @return A list with `curve` (a data frame of `threshold`, `type_i_error`,
#'   `mcse` over the grid), the calibrated `threshold`, and the achieved
#'   `type_i_error` / `mcse` at that threshold.
#'
#' @examples
#' null_paths <- simulate_paths(0.3, 0.3, n_max = 150, n_interim = 75,
#'                              n_sims = 500)
#' cal <- calibrate_threshold(null_paths, target = 0.05)
#' cal$threshold
#'
#' @export
calibrate_threshold <- function(null_paths, target = 0.05,
                                grid = seq(0.9, 0.999, by = 0.001),
                                sup_interim = 0.99, fut_interim = 0.10) {
  stopifnot(target > 0, target < 1, length(grid) >= 1)
  n_sims <- nrow(null_paths)

  type_i <- vapply(grid, function(g) {
    d <- apply_decision(null_paths, sup_interim, fut_interim, sup_final = g)
    mean(d$declared)
  }, numeric(1))
  mcse <- sqrt(type_i * (1 - type_i) / n_sims)

  curve <- data.frame(threshold = grid, type_i_error = type_i, mcse = mcse)

  # Smallest threshold whose type I error is at or below target (conservative).
  ok <- which(type_i <= target)
  idx <- if (length(ok)) ok[which.min(grid[ok])] else which.min(type_i)

  list(
    curve         = curve,
    threshold     = grid[idx],
    type_i_error  = type_i[idx],
    mcse          = mcse[idx],
    target        = target,
    achieved_target = type_i[idx] <= target
  )
}

#' Run a full two-arm conjugate simulation
#'
#' Convenience wrapper that simulates paths, applies the decision rule, and
#' summarises the operating characteristics in one call.
#'
#' @inheritParams simulate_paths
#' @param sup_interim,fut_interim,sup_final Decision thresholds passed to
#'   [apply_decision()].
#'
#' @return A list with `paths` (raw simulated paths), `per_trial` (per-trial
#'   decisions), and `oc` (operating characteristics with MCSE, from
#'   [summarise_oc()]).
#'
#' @examples
#' res <- run_trial_simulation(0.3, 0.45, n_max = 150, n_interim = 75,
#'                             n_sims = 300)
#' res$oc
#'
#' @export
run_trial_simulation <- function(p_control, p_treat, n_max, n_interim,
                                 a0 = 1, b0 = 1,
                                 sup_interim = 0.99, fut_interim = 0.10,
                                 sup_final = 0.975,
                                 n_sims = 1000, n_draws = 2000, seed = 1) {
  paths <- simulate_paths(p_control, p_treat, n_max, n_interim,
                          a0, b0, n_sims, n_draws, seed)
  per_trial <- apply_decision(paths, sup_interim, fut_interim, sup_final)
  list(
    paths     = paths,
    per_trial = per_trial,
    oc        = summarise_oc(per_trial)
  )
}
