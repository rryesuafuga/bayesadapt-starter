# ADEMP protocol — conjugate MVP

This simulator is organised around the **ADEMP** framework
(Morris, White & Crowther, 2019). Each element maps to part of the UI.

## Aims
Quantify the operating characteristics of a two-arm, binary-outcome Bayesian
adaptive design with a single interim look, and **calibrate the final
superiority threshold** so the type I error under the null meets a target
(commonly 2.5–5%).

## Data-generating mechanism
Independent binomial sampling in each arm: control successes
`X_c ~ Binomial(n, p_control)` and treatment successes
`X_t ~ Binomial(n, p_treat)`. Patients accrue to `n_interim` per arm at the
interim look and to `n_max` per arm at the final look. Set
`p_treat = p_control` for the null (type I error) scenario.

## Estimand
The treatment effect on the log-odds scale:
`beta = logit(p_treat) − logit(p_control)` (the log odds-ratio). Under the null
`beta = 0`.

## Methods
Conjugate Beta-Binomial analysis. With a `Beta(a0, b0)` prior per arm and `x`
successes in `n`, the posterior is `Beta(a0 + x, b0 + n − x)` — closed form, no
MCMC. The decision quantity is the posterior probability of benefit
`p_sup = P(p_treat > p_control | data)`, computed by Monte-Carlo draws from the
two Beta posteriors.

**Prior influence.** The prior's effective sample size (ESS) is `a0 + b0` per
arm — the update shows the prior acts like `a0 + b0` extra patients. The app
reports it as a fraction of the information at each look (ESS / n), so its
larger relative weight at the interim (smaller `n`) is explicit. The default
`Beta(1, 1)` is uniform (ESS 2, negligible against `n = 150`/arm).

Decision rule:

- **Interim (at `n_interim`/arm):** stop for **efficacy** if `p_sup ≥ sup_interim`;
  stop for **futility** if `p_sup ≤ fut_interim`.
- **Final (at `n_max`/arm):** declare **superiority** if `p_sup ≥ sup_final`.

(Predictive-probability futility is the planned upgrade; the MVP uses a
posterior-probability futility rule.)

## Performance measures
Reported with their **Monte-Carlo standard error (MCSE)**:

- Declaration rate — the **type I error** under the null (one-sided by
  construction; the FDA standard target is 2.5%), the **power** under the
  alternative (binomial MCSE `sqrt(p(1−p)/n_sims)`).
- Probability of stopping early for efficacy vs futility.
- Expected total sample size `E[N]` (MCSE `sd(N)/sqrt(n_sims)`).
- **Bias** and **MSE** of the log-OR estimate.
- 95% credible-interval **coverage**.

## Calibration
The cleanest single demonstration of rigour: regenerate the trial under the
null, grid-search `sup_final`, and choose the smallest threshold whose type I
error is at or below the target. Report the achieved value ± MCSE, then read the
power under the alternative at that calibrated threshold. A frequentist
group-sequential benchmark via `rpact` is the planned validation step.

## References
- Morris TP, White IR, Crowther MJ (2019). *Using simulation studies to
  evaluate statistical methods.* Statistics in Medicine 38(11):2074–2102.
  doi:10.1002/sim.8086.
- Granholm A, et al. (2022). *adaptr* (JOSS). doi:10.21105/joss.04284.
