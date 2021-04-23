#' @title
#' Job: Maintain AC Temperature
#'
#' @description
#' This keeps the temperature maintained across a particular range.
#'
#' @param interval polling interval in seconds
#' @param test_mode testing mode
#'
#' @export
job_maintain_ac_temp <- function(interval = 5, test_mode = FALSE) {
  while (TRUE) {
    sensibo_maintain_devices()
    Sys.sleep(interval)
    if (test_mode) break
  }
}
