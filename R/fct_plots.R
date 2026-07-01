# Publication-quality operating-characteristic figures --------------------------
# ggplot2 figures shared by the modules. Kept free of Shiny so they can be reused
# in reports and tested directly.

#' Minimal ggplot theme for operating-characteristic figures
#' @keywords internal
theme_bayesadapt <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      legend.position = "bottom"
    )
}

#' Histogram of total sample size across simulated trials
#'
#' @param per_trial A per-trial decision data frame from [apply_decision()].
#' @return A ggplot object.
#' @examples
#' res <- run_trial_simulation(0.3, 0.45, n_max = 150, n_interim = 75,
#'                             n_sims = 300)
#' plot_sample_size(res$per_trial)
#' @export
plot_sample_size <- function(per_trial) {
  e_n <- mean(per_trial$n_used)
  ggplot2::ggplot(per_trial, ggplot2::aes(x = .data$n_used)) +
    ggplot2::geom_histogram(bins = 30, fill = "#9FE1CB", colour = "white") +
    ggplot2::geom_vline(xintercept = e_n, linewidth = 1, colour = "#0F6E56") +
    ggplot2::annotate("text", x = e_n, y = Inf, vjust = 1.5, hjust = -0.1,
                      label = sprintf("E[N] = %.0f", e_n), colour = "#0F6E56") +
    ggplot2::labs(x = "Total sample size (both arms)", y = "Simulated trials") +
    theme_bayesadapt()
}

#' Calibration curve: type I error versus final superiority threshold
#'
#' @param calibration A list returned by [calibrate_threshold()].
#' @return A ggplot object with the target and calibrated threshold marked, and
#'   a +/- MCSE ribbon around the curve.
#' @examples
#' null_paths <- simulate_paths(0.3, 0.3, n_max = 150, n_interim = 75,
#'                              n_sims = 400)
#' cal <- calibrate_threshold(null_paths, target = 0.05)
#' plot_calibration(cal)
#' @export
plot_calibration <- function(calibration) {
  curve <- calibration$curve
  ggplot2::ggplot(curve, ggplot2::aes(x = .data$threshold, y = .data$type_i_error)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$type_i_error - .data$mcse,
                   ymax = .data$type_i_error + .data$mcse),
      fill = "#9FE1CB", alpha = 0.5
    ) +
    ggplot2::geom_line(linewidth = 0.8, colour = "#0F6E56") +
    ggplot2::geom_hline(yintercept = calibration$target, linetype = "dashed") +
    ggplot2::geom_vline(xintercept = calibration$threshold, linetype = "dotted") +
    ggplot2::annotate(
      "label", x = calibration$threshold, y = calibration$target,
      label = sprintf("target = %.1f%%\nthreshold = %.3f",
                      100 * calibration$target, calibration$threshold),
      size = 3.2, hjust = 1.05
    ) +
    ggplot2::labs(
      x = "Final superiority threshold  P(benefit) >=",
      y = "Type I error (declaration rate under the null)",
      caption = "Ribbon shows +/- Monte-Carlo standard error"
    ) +
    theme_bayesadapt()
}

#' Operating characteristics as a labelled bar chart with MCSE error bars
#'
#' @param oc An operating-characteristics data frame from [summarise_oc()].
#' @return A ggplot object showing the proportion-type measures.
#' @examples
#' res <- run_trial_simulation(0.3, 0.45, n_max = 150, n_interim = 75,
#'                             n_sims = 300)
#' plot_oc_bars(res$oc)
#' @export
plot_oc_bars <- function(oc) {
  keep <- c("p_declare", "p_stop_efficacy", "p_stop_futility", "p_inconclusive")
  d <- oc[oc$metric %in% keep, ]
  # Reverse the level order so the first metric sits at the top after coord_flip.
  d$label <- factor(d$label, levels = rev(d$label))
  ggplot2::ggplot(d, ggplot2::aes(x = .data$label, y = .data$value)) +
    ggplot2::geom_col(fill = "#9FE1CB", width = 0.7) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = pmax(0, .data$value - .data$mcse),
                   ymax = .data$value + .data$mcse),
      width = 0.2, colour = "#0F6E56"
    ) +
    ggplot2::scale_y_continuous(labels = function(x) paste0(100 * x, "%"),
                                limits = c(0, NA)) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = "Probability") +
    theme_bayesadapt()
}
