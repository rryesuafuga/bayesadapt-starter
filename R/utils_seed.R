# Seed / reproducibility helpers ------------------------------------------------

#' Coerce a user-supplied value to a valid integer seed
#'
#' Shiny `numericInput`s can yield `NA`, non-integers, or `NULL`; this normalises
#' them to a single positive integer so simulation runs are reproducible.
#'
#' @param x A value from a seed input.
#' @param default Fallback seed when `x` is missing or invalid.
#' @return A length-one integer.
#' @keywords internal
sanitize_seed <- function(x, default = 1L) {
  if (is.null(x) || length(x) != 1 || is.na(x) || !is.finite(x)) {
    return(as.integer(default))
  }
  as.integer(abs(round(x)))
}
