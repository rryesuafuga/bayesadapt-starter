# bayesadapt — architecture &amp; methodology

A Bayesian adaptive clinical-trial simulator in R Shiny, built as a golem package and
organised around the **ADEMP** framework. This document is the design reference; `CLAUDE.md`
is the short operational guide.

## 1. Goal and audience
An interactive, statistically rigorous simulator of Bayesian adaptive trials, suitable as a
portfolio piece for a methods-focused biostatistics group. Priorities, in order: correctness,
reproducibility, clarity of operating-characteristics output, then polish.

## 2. Stack
- **golem** — the app is an R package (gives `R CMD check`, roxygen2 docs, testthat/shinytest2
  scaffolding, renv + deployment discipline).
- **shiny + bslib** — Bootstrap 5 UI: `page_sidebar`/`page_navbar`, `card`, `value_box`,
  `layout_columns`.
- **ggplot2** for operating-characteristic figures; **plotly** only where interactive hover/zoom
  genuinely helps (e.g. single-trial trajectories).
- **Engines:** conjugate Beta-Binomial (base R, MVP) -> `adaptr` (multi-arm, RAR, calibration)
  -> `rstanarm`/`rmsb` precompiled Stan (ordinal proportional-odds extension only).
- **renv** for dependencies; **testthat** + **shinytest2** for tests.

## 3. File structure (golem)
```
bayesadapt/
  DESCRIPTION, NAMESPACE, LICENSE, README.md
  renv.lock, .Rprofile
  app.R                          # launcher -> run_app()
  R/
    app_ui.R, app_server.R, run_app.R, app_config.R
    mod_design_inputs.R          # arms, true rates/odds, accrual, looks
    mod_prior_spec.R             # FEATURED: treatment-effect & cut-point prior pickers + prior plots
    mod_sim_controls.R           # n_rep, seed, workers, Run button (ExtendedTask)
    mod_operating_chars.R        # value boxes + ggplot OC tables/plots
    mod_single_trial.R           # trajectory of one simulated trial
    mod_calibration.R            # calibrate type I error under the null
    mod_report.R                 # download design spec + results + methods note
    fct_engine_conjugate.R       # beta-binomial / normal-normal closed form (from inst/shinylive)
    fct_engine_adaptr.R          # adaptr wrappers
    fct_engine_ordinal.R         # rstanarm/rmsb PO models (extension)
    fct_operating_chars.R, fct_plots.R
    utils_seed.R, utils_priors.R
  inst/
    shinylive/app.R              # standalone conjugate MVP (runs in-browser via WASM)
    methods/ADEMP.md             # written ADEMP protocol shown in-app
  tests/testthat/
  dev/01_start.R, 02_dev.R, 03_deploy.R
  .devcontainer/                 # cloud R workspace (Codespaces)
  .github/workflows/             # deploy to shinyapps.io + GitHub Pages
```

## 4. ADEMP mapping (the organising spine)
- **Aims** — what design question each run answers (e.g. "what superiority threshold controls
  type I error at 5% for this design?").
- **Data-generating mechanism** — true control/treatment rates (or ordinal category
  probabilities), sample size, accrual, number of arms, interim schedule.
- **Estimand** — the treatment effect: log odds-ratio (proportional log-OR for ordinal outcomes).
- **Methods** — analysis model + prior + decision rule.
- **Performance measures** — see section 6. Always reported with **MCSE**.

Map each ADEMP element to one Shiny module so the UI itself teaches the framework.

## 5. Decision quantities
- **Posterior probability of benefit**, `P(theta_treat > theta_control | data)`.
  Binary outcome with a `Beta(a0, b0)` prior and `x` successes in `n`: posterior is
  `Beta(a0 + x, b0 + n - x)` — closed form, no MCMC. The two-arm comparison is a quick
  Monte-Carlo draw from the two Beta posteriors. Declare superiority when this exceeds a
  threshold (commonly 0.95-0.99).
- **Predictive probability of success** — the probability the trial would meet its success
  criterion if enrolled to the maximum N. For binary outcomes the posterior-predictive of future
  responses is **Beta-Binomial** (closed form). Used for futility stopping and to inform RAR.
  (The MVP uses a posterior-probability futility rule; predictive-probability futility is the
  planned upgrade.)

## 6. Operating characteristics
Type I error (declaration rate under the null — the calibration target), power, expected and
distribution of sample size, probability of stopping early for efficacy vs futility, bias and
relative bias of the treatment-effect estimate, 95% credible-interval coverage, MSE, and (multi-
arm) probability of correct arm selection. Report each with MCSE; show metric stability vs n_rep.

## 7. Calibration / validation
Calibrate the stopping threshold to a target type I error under the primary null (`adaptr`
provides Gaussian-process calibration; the conjugate MVP can grid-search). The cleanest single
demonstration of rigour: calibrate to 5% under the null, report the achieved value +/- MCSE, then
show power under the alternative. Benchmark against a frequentist group-sequential design via
`rpact`.

## 8. Featured capability — prior specification for ordinal outcomes
The proportional-odds model is `logit[P(Y >= j)] = alpha_j + beta * x`, with `beta` the
proportional log-OR (the estimand) and `alpha` the cumulative-logit cut-points. The prior-
specification module lets users choose:

- **Priors on the treatment effect beta:** Normal(0, 100^2) (diffuse), Normal(0, 2.5^2)
  (weakly-informative), Student-t df=1 (Cauchy), Laplace, and the **R-squared prior**
  (rstanarm-style R^2 / Beta(0.5, 0.5) — label precisely; this is NOT a full R2D2 decomposition).
- **Priors on the cut-points alpha:** Dirichlet at concentration 1 (uniform), 0.5 (reference),
  near-zero (diffuse), 1/J, or independent Normals.

Reproduce the published findings as a built-in case study (paraphrased here, verify magnitudes
against the authors' public code before quoting exact numbers in-app): prior choice can bias the
treatment-effect estimate, especially when control-arm probabilities are right-skewed; the
R-squared prior tends to give the smallest bias and stops early appropriately when an effect
exists, but is more biased under U-shaped control distributions with an early-stopping rule;
near-zero Dirichlet cut-point priors minimise bias under right-skew but can stop early
inappropriately under the null. Bias grows with the number of ordinal categories. Recommendation
to surface in-app: choose priors with reference to the expected control-arm distribution, and
pre-specify prior sensitivity analyses.

Backend for this module: precompiled Stan via `rstanarm` (`stan_polr`) or `rmsb::blrm` (QR
reparametrisation), summarised with the `posterior` package. Full MCMC is too slow for click-by-
click interactivity at scale — precompute a results grid or use a "deep run" mode.

## 9. Packages
Core: `golem`, `shiny`, `bslib`, `ggplot2`, `adaptr`, `renv`, `testthat`, `shinytest2`,
`shinylive`, `rsconnect`. Extension: `rstanarm`, `rmsb`, `posterior` (and optionally `brms`,
`RBesT` for historical borrowing). Benchmark: `rpact` (frequentist group-sequential — treat as a
benchmark only, not a Bayesian engine).

## 10. Performance
Prefer conjugate / closed-form updating for interactive speed (orders of magnitude faster than
MCMC and exact for the MVP). Reserve full MCMC for the ordinal extension and there use precompiled
Stan. Parallelise replicates with `future`/`furrr`/`mirai`. Gate simulation behind a Run button;
cache results on inputs + seed.

## 11. References
- Morris, White &amp; Crowther (2019), *Using simulation studies to evaluate statistical methods*,
  Statistics in Medicine 38(11):2074-2102. DOI 10.1002/sim.8086.
- Granholm, Jensen, Lange &amp; Kaas-Hansen (2022), *adaptr* (JOSS). DOI 10.21105/joss.04284;
  practical guide: Granholm et al. (2025), Pharmaceutical Statistics, DOI 10.1002/pst.70042.
- CEBU / AusTriM proportional-odds prior-specification papers (Selman, Lee et al., 2025).

## 12. Caveats
- The ordinal PO extension needs user-defined outcome- and posterior-draw functions if wired
  through `adaptr` — the most demanding coding task; budget for it.
- Keep the MVP engine pure base R so it runs in shinylive/WASM; Stan does NOT run in WASM.
- `rpact` is a validated frequentist benchmark, not a Bayesian engine.
- Verify any quoted bias / early-stopping percentages against the authors' public code.
