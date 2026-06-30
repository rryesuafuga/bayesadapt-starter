#' bayesadapt: Bayesian Adaptive Clinical-Trial Simulator
#'
#' An R Shiny (golem) simulator of Bayesian adaptive clinical trials, organised
#' around the ADEMP framework (Aims, Data-generating mechanism, Estimand,
#' Methods, Performance measures). The MVP is a two-arm, binary-outcome design
#' with a conjugate Beta-Binomial backend (no MCMC) and posterior-probability
#' stopping, with calibration of the superiority threshold to a target type I
#' error under the null. Every operating characteristic is reported with its
#' Monte-Carlo standard error.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom stats median qlogis quantile rbeta rbinom sd
#' @importFrom utils globalVariables
## usethis namespace: end
NULL

# Quiet R CMD check note about the `.data` pronoun used in ggplot2 aes().
globalVariables(".data")
