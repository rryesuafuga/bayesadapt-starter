# bayesadapt

A Bayesian adaptive clinical-trial simulator in R Shiny, built as a
[golem](https://thinkr-open.github.io/golem/) package and organised around the
**ADEMP** framework (Aims, Data-generating mechanism, Estimand, Methods,
Performance measures). Statistical rigour is the point: correctness,
reproducibility, and clean operating-characteristics output — every operating
characteristic is reported with its **Monte-Carlo standard error (MCSE)**.

The design rationale lives in [`docs/architecture.md`](docs/architecture.md);
the operational guide is [`CLAUDE.md`](CLAUDE.md).

## What's here (Phase 1 — MVP)

A two-arm, binary-outcome adaptive design with a single interim look, using a
**conjugate Beta-Binomial** model (no MCMC). With a `Beta(a0, b0)` prior per arm
and `x` successes in `n`, the posterior is `Beta(a0 + x, b0 + n - x)`; the
decision quantity is the posterior probability of benefit
`P(p_treat > p_control | data)`. The interim look stops for efficacy or
futility; the final look declares superiority. The app:

- reports power / type I error, early-stopping probabilities, expected sample
  size, and bias / MSE / 95% CrI coverage of the log-odds-ratio estimand — each
  with MCSE;
- **calibrates** the final superiority threshold to a target type I error under
  the null and reports the achieved value ± MCSE.

The engine (`R/fct_engine_conjugate.R`) is pure base R so the same logic runs
in the browser via [shinylive](https://posit-dev.github.io/r-shinylive/)
(`inst/shinylive/app.R`).

### Roadmap

2. **Ordinal / proportional-odds extension** — a prior-specification module and
   an `rstanarm`/`rmsb` PO backend (the featured capability).
3. **Multi-arm / RAR** — response-adaptive randomisation and arm-dropping via
   `adaptr`.

## Run it

```r
# install dependencies (renv)
renv::restore()

# launch the full app
pkgload::load_all(); bayesadapt::run_app()
# or, in development:  golem::run_dev()
```

## Develop

```r
devtools::document()   # roxygen2 -> NAMESPACE + man/
devtools::test()       # testthat
devtools::check()      # R CMD check
```

The package layout, the ADEMP mapping, the decision quantities, and the
validation expectations are documented in
[`docs/architecture.md`](docs/architecture.md).

## Deployment

Already wired (see `CLAUDE.md`): pushing to `main` deploys the full app to
**shinyapps.io** and publishes the in-browser conjugate MVP to **GitHub Pages**
via shinylive.

## References

- Morris TP, White IR, Crowther MJ (2019). *Using simulation studies to
  evaluate statistical methods.* Statistics in Medicine 38(11):2074–2102.
  doi:10.1002/sim.8086.
- Granholm A, et al. (2022). *adaptr* (JOSS). doi:10.21105/joss.04284.
