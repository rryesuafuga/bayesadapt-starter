# Launcher for shinyapps.io / rsconnect and local `shiny::runApp()`.
# Restores the renv library if present, then starts the golem app.
if (file.exists("renv/activate.R")) source("renv/activate.R")
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
bayesadapt::run_app()
