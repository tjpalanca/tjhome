test_that("Jobs work", {
  expect_error(job_maintain_ac_temp(interval = 1, test_mode = TRUE), NA)
})
