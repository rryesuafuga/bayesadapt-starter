# CLAUDE.md — project guide for Claude Code

## What this project is
`bayesadapt` is an R Shiny **Bayesian adaptive clinical-trial simulator**, built as a
**golem package**. It is a portfolio / demonstration piece aimed at a senior academic
biostatistics group that works on Bayesian adaptive trial methods. Statistical rigour is
the point: a trial statistician should see correctness, reproducibility, and clean
operating-characteristics output immediately. The full design rationale is in
`docs/architecture.md` — read it before scaffolding.

## Golden rules
- Build the app as an **R package** using **golem**. One Shiny module per file in `R/`.
- Organise everything around the **ADEMP** framework (Aims, Data-generating mechanisms,
  Estimands, Methods, Performance measures).
- **Report Monte Carlo standard error (MCSE)** next to every operating characteristic.
- Work in **phases** (below). Do not start a later phase until the current one runs and is tested.
- **Never commit secrets.** shinyapps.io credentials live in environment variables / GitHub
  secrets, never in the repo.

## Tech stack
- golem, shiny, bslib (Bootstrap 5 UI: `page_sidebar`/`page_navbar`, `card`, `value_box`,
  `layout_columns`).
- Simulation engine: conjugate Beta-Binomial (base R) for the MVP; `adaptr` as the established
  multi-arm engine; `rstanarm` / `rmsb` (precompiled Stan) for the ordinal extension ONLY.
- ggplot2 for publication-quality operating-characteristic figures.
- Long runs: gate simulation behind a Run button with `eventReactive`; use Shiny `ExtendedTask`
  + `mirai`/`future` for non-blocking execution; `bindCache` keyed on inputs + seed.
- renv for dependencies; testthat + shinytest2 for tests.

## Build phases
1. **MVP (do this first).** Two-arm, binary outcome, **conjugate Beta-Binomial** backend
   (no MCMC). Modules: design inputs, simulation controls, operating characteristics,
   calibration. Posterior-probability stopping. Calibrate the superiority threshold to a target
   type I error under the null and report it +/- MCSE.
   A reference implementation already exists at `inst/shinylive/app.R` — fold its engine into
   `R/fct_engine_conjugate.R` and wire it through the golem modules. Keep this engine pure base R
   so the conjugate app can also run in the browser via shinylive.
2. **Ordinal / proportional-odds extension.** Add the **prior-specification module** (the
   featured capability) and an `rstanarm`/`rmsb` PO backend. Let the user compare priors on the
   treatment effect (Normal at varying SD, Cauchy, Laplace, R-squared/Beta) and on the cut-points
   (Dirichlet at varying concentration), and watch treatment-effect bias and early-stopping
   probabilities change. Reproduce the published bias / early-stopping findings as a built-in case
   study. Use precompiled Stan; cache fits; reserve full MCMC for a "deep run" mode.
3. **Multi-arm / RAR.** Wrap `adaptr`'s response-adaptive randomisation and arm-dropping; add
   probability of correct arm selection.

## Conventions
- Use `golem::add_module()`, `golem::add_fct()`, `golem::add_utils()` to create files.
- roxygen2 docs on every exported function; a test alongside every module (`with_test = TRUE`).
- After adding any dependency: `renv::snapshot()` and commit `renv.lock`.
- Conventional-commit messages; small, logical commits.

## Commands
- Run the app in dev:        `golem::run_dev()`
- Tests:                     `devtools::test()`  /  `shinytest2::test_app()`
- Package check:             `devtools::check()`
- Build the shinylive demo:  `shinylive::export("inst/shinylive", "_site")`
- Snapshot deps:             `renv::snapshot()`

## Deployment (already wired — do not rebuild this)
- **shinyapps.io** (full app): push to `main` triggers `.github/workflows/deploy-shinyapps.yml`,
  which deploys via `rsconnect::deployApp()` using repo secrets `SHINYAPPS_NAME` /
  `SHINYAPPS_TOKEN` / `SHINYAPPS_SECRET`. (Requires `renv.lock` to exist.)
- **GitHub Pages** (fast conjugate MVP, runs in-browser via shinylive):
  `.github/workflows/deploy-pages.yml` exports `inst/shinylive/` and publishes to Pages.
- Local / direct deploy helper: `dev/03_deploy.R`.

## Validation expectations
- Type I error under the null within MCSE of the calibrated target.
- Benchmark the Bayesian design against a frequentist group-sequential design via `rpact`.
- Label the R-squared prior precisely: it is the rstanarm-style R^2 / Beta(0.5, 0.5) prior,
  NOT a full multi-parameter R2D2 decomposition. Cite Morris, White & Crowther (2019) and the
  CEBU proportional-odds papers in-app.
