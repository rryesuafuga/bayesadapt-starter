# Operating characteristics ----------------------------------------------------
# Summarise per-trial decisions into the ADEMP "Performance measures", each
# reported with its Monte-Carlo standard error (MCSE). The MCSE is the standard
# error of the simulation estimate itself: it tells the reader how much of the
# reported number is noise from a finite number of replicates, and shrinks like
# 1/sqrt(n_sims). Every operating characteristic below carries one.

#' Monte-Carlo standard error of a proportion
#'
#' @param p Estimated proportion.
#' @param n Number of replicates.
#' @return The binomial MCSE `sqrt(p (1 - p) / n)`.
#' @keywords internal
mcse_prop <- function(p, n) sqrt(p * (1 - p) / n)

#' Summarise operating characteristics with Monte-Carlo standard errors
#'
#' @param per_trial A per-trial decision data frame from [apply_decision()],
#'   carrying `true_log_or` / `is_null` attributes.
#'
#' @return A data frame with columns `metric`, `value`, `mcse`, and a short
#'   `label` for display. Proportion metrics use the binomial MCSE; means use
#'   `sd / sqrt(n)`. The declaration rate is the power, or, under the null, the
#'   type I error.
#'
#' @examples
#' res <- run_trial_simulation(0.3, 0.45, n_max = 150, n_interim = 75,
#'                             n_sims = 300)
#' summarise_oc(res$per_trial)
#'
#' @importFrom stats sd
#' @export
summarise_oc <- function(per_trial) {
  n <- nrow(per_trial)
  true_lor <- attr(per_trial, "true_log_or")
  is_null  <- isTRUE(attr(per_trial, "is_null"))

  # --- Decision-rate measures (binomial MCSE) ---
  p_declare <- mean(per_trial$declared)
  p_eff     <- mean(per_trial$decision == "efficacy")        # interim efficacy
  p_fut     <- mean(per_trial$decision == "futility")        # interim futility
  p_eff_fin <- mean(per_trial$decision == "efficacy_final")
  p_inconcl <- mean(per_trial$decision == "inconclusive")
  p_stop_e  <- mean(per_trial$stopped_interim)               # any interim stop

  # --- Sample-size measures (mean MCSE = sd / sqrt(n)) ---
  e_n     <- mean(per_trial$n_used)
  mcse_n  <- sd(per_trial$n_used) / sqrt(n)

  # --- Estimation measures for the log-OR estimand ---
  err     <- per_trial$est_log_or - true_lor
  bias    <- mean(err)
  mcse_b  <- sd(per_trial$est_log_or) / sqrt(n)
  mse     <- mean(err^2)
  mcse_mse <- sd(err^2) / sqrt(n)
  covered <- per_trial$ci_lwr <= true_lor & true_lor <= per_trial$ci_upr
  coverage <- mean(covered)

  declare_label <- if (is_null) "Type I error" else "Power (declares superiority)"

  data.frame(
    metric = c("p_declare", "p_stop_efficacy", "p_stop_futility",
               "p_efficacy_final", "p_inconclusive", "p_stop_early",
               "e_n", "bias_log_or", "mse_log_or", "coverage"),
    label = c(declare_label, "Stop early: efficacy", "Stop early: futility",
              "Declare at final look", "Inconclusive", "Any early stop",
              "Expected total N", "Bias (log-OR)", "MSE (log-OR)",
              "95% CrI coverage"),
    value = c(p_declare, p_eff, p_fut, p_eff_fin, p_inconcl, p_stop_e,
              e_n, bias, mse, coverage),
    mcse  = c(mcse_prop(p_declare, n), mcse_prop(p_eff, n),
              mcse_prop(p_fut, n), mcse_prop(p_eff_fin, n),
              mcse_prop(p_inconcl, n), mcse_prop(p_stop_e, n),
              mcse_n, mcse_b, mcse_mse, mcse_prop(coverage, n)),
    stringsAsFactors = FALSE
  )
}

#' Format an operating characteristic as "value +/- MCSE"
#'
#' @param value,mcse The estimate and its Monte-Carlo standard error.
#' @param pct Whether to render as a percentage.
#' @param digits Decimal places.
#' @return A formatted character string.
#' @keywords internal
fmt_oc <- function(value, mcse, pct = TRUE, digits = 1) {
  if (pct) {
    sprintf("%.*f%% +/- %.*f", digits, 100 * value, digits, 100 * mcse)
  } else {
    sprintf("%.*f +/- %.*f", digits, value, digits, mcse)
  }
}
