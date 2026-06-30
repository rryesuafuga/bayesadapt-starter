# dev/03_deploy.R --------------------------------------------------------------
# Deployment helpers. Run these lines INTERACTIVELY. Never commit secrets:
# put SHINYAPPS_* in ~/.Renviron (git-ignored) - see .Renviron.example.

# 1) shinyapps.io - full app (server-backed) -----------------------------------
# Credentials: https://www.shinyapps.io  ->  Account  ->  Tokens  ->  Show.
rsconnect::setAccountInfo(
  name   = Sys.getenv("SHINYAPPS_NAME"),
  token  = Sys.getenv("SHINYAPPS_TOKEN"),
  secret = Sys.getenv("SHINYAPPS_SECRET")
)
rsconnect::deployApp(appName = "bayesadapt", forceUpdate = TRUE)

# 2) GitHub Pages (shinylive) - fast conjugate MVP, runs in the browser --------
# Builds the static WASM site from the standalone MVP in inst/shinylive/.
# CI does this automatically (.github/workflows/deploy-pages.yml); to preview
# locally:
# shinylive::export("inst/shinylive", "_site")
# httpuv::runStaticServer("_site")   # then open the printed URL

# 3) Optional golem helpers ----------------------------------------------------
# golem::add_shinyappsio_file()   # generates an app.R tailored for shinyapps.io
