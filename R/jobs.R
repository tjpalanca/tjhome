#' @title
#' Job: Maintain AC Temperature
#'
#' @description
#' This keeps the temperature maintained across a particular range.
#'
#' @param interval polling interval in seconds
#'
#' @export
job_maintain_ac_temp <- function(interval = 5) {
  while(TRUE) {
    sensibo_maintain_devices()
    Sys.sleep(interval)
  }
}
