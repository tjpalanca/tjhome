test_that("Sensibo API works", {

  # Info
  info <- expect_error(sensibo_info(), NA)
  expect_s3_class(info, "tbl_df")

  # Devices
  devices <- expect_error(sensibo_devices(), NA)
  expect_s3_class(devices, "tbl_df")

  # Config
  config <- expect_error(sensibo_config(), NA)
  expect_s3_class(devices, "tbl_df")

  # Temperature Chart
  chart <- expect_error(sensibo_temperature_chart(), NA)
  expect_s3_class(chart, "ggplot")

  # Historical measurements
  measurements <- expect_error(
    sensibo_historical_measurements(devices$device_id[[1]]),
    NA
  )
  expect_s3_class(measurements, "tbl_df")

  # Maintain devices
  expect_error(sensibo_set_fan_speed(devices$device_id[[1]], "high"), NA)
  expect_error(sensibo_maintain_devices(), NA)
  expect_error(sensibo_maintain_fan_speed(
    device_id = devices$device_id[[1]],
    cur_temp = devices$temperature[[1]],
    min_temp = 16,
    max_temp = 18,
    curr_fan_speed = devices$fan_speed[[1]]
  ), NA)

})
