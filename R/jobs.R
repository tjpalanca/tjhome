#' @title
#' Job Management
#'
#' @description
#' Runs all the jobs needed for home automation.
#'
#' @export
run_jobs <- function() {
  jobs <- list(
    job_maintain_ac_temp()
  )
  Sys.sleep(Inf)
  return(jobs)
}

#' @title
#' Job: Maintain AC Temperature
#'
#' @description
#' This keeps the temperature maintained across a particular range.
#'
#' @export
job_maintain_ac_temp <- function(interval = 60, loop = create_loop()) {
  sensibo_maintain_devices()
  later(
    func  = function() {
      job_maintain_ac_temp(
        interval = interval,
        loop = loop
      )
    },
    delay = interval,
    loop  = loop
  )
  return(loop)
}
