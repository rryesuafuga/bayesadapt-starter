# dev/run_dev.R ----------------------------------------------------------------
# Launch the app in development mode (hot-reloading of the package).

options(golem.app.prod = FALSE)
golem::detach_all_attached()
golem::document_and_reload()
run_app()
