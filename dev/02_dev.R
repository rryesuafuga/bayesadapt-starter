# dev/02_dev.R -----------------------------------------------------------------
# Day-to-day development loop. Run these lines interactively.

# Add a module / function / utils file (golem scaffolding):
# golem::add_module(name = "single_trial", with_test = TRUE)
# golem::add_fct("engine_adaptr", with_test = TRUE)
# golem::add_utils("priors", with_test = TRUE)

# Document, test, check:
# devtools::document()
# devtools::test()
# devtools::check()

# Run the app in dev:
# golem::run_dev()
# or, without golem's run_dev scaffolding:
# pkgload::load_all(); bayesadapt::run_app()

# After adding a dependency:
# renv::snapshot()
