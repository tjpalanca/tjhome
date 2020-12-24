#' @title
#' Sensibo
#'
#' @description
#' Sensibo is a device that allows control of air conditioning units.
#'
#' API documentation is [here](https://sensibo.github.io/).
#'
#' @name sensibo
NULL

#' @describeIn sensibo Generic API call, memoised
#' @export
sensibo_call <- function(path, ...,
                         query = list(),
                         verb = "GET",
                         api_key = Sys.getenv("SENSIBO_API_KEY")) {
  RETRY(
    verb  = verb,
    url   = "https://home.sensibo.com/",
    path  = glue("api/v2/{path}"),
    query = append(list(apiKey = api_key), query),
    ...
  ) %>%
    stop_for_status() %>%
    content(as = "parsed") %$%
    result
}

#' @describeIn sensibo Get all the data as a tibble
sensibo_info <- memoise(function() {
  sensibo_call("users/me/pods", query = list(fields = "*")) %>%
    tibble(sensibo = .) %>%
    unnest_wider(sensibo)
})

#' @describeIn sensibo Parse sensibo information into usable format
#' @export
sensibo_devices <- function() {
  sensibo_info()  %>%
    transmute(
      device_id = id,
      room_name = map_chr(room, "name"),
      is_powered_on = map_lgl(acState, "on"),
      fan_speed = map_chr(acState, "fanLevel"),
      temperature = map2_dbl(
        temperatureUnit,
        measurements,
        function(unit, measurements) {
          if (unit != "C") {
            if (unit == "F") {
              temp <- (measurements$temperature - 32) * 5 / 9
            } else {
              temp <- NA
            }
          } else {
            temp <- measurements$temperature
          }
          return(temp)
        }
      )
    )
}

#' @describeIn sensibo maintains the temperature by adjusting the fan speed
#' @param device_id device ID
#' @param cur_temp current temperature reading
#' @param max_temp maximum temperature allowed
#' @param min_temp minimum temperature allowed
#' @param curr_fan_speed current fan speed
#' @param cool_fan_speed fan speed if the room is too cool
#' @param norm_fan_speed fan speed if the room is within range
#' @param warm_fan_speed fan speed if the room is too warm
#' @export
sensibo_maintain_fan_speed <- function(device_id,
                             cur_temp,
                             min_temp,
                             max_temp,
                             curr_fan_speed,
                             cool_fan_speed = "medium_low",
                             norm_fan_speed = "medium",
                             warm_fan_speed = "high") {

  assert_that(is.string(device_id))
  assert_that(is.number(cur_temp))
  assert_that(is.number(min_temp))
  assert_that(is.number(max_temp))
  assert_that(max_temp > min_temp)
  assert_that(is.string(curr_fan_speed))

  target_fan_speed <- if (cur_temp > max_temp) {
    warm_fan_speed
  } else if (cur_temp < min_temp) {
    cool_fan_speed
  } else {
    norm_fan_speed
  }

  if (curr_fan_speed != target_fan_speed) {
    sensibo_set_fan_speed(device_id, target_fan_speed)
  }

}

#' @describeIn sensibo Sets the fan speed of a sensibo device
#' @param device_id device ID
#' @param fan_speed fan speed string setting
#' @export
sensibo_set_fan_speed <- function(device_id, fan_speed) {

  assert_that(is.string(device_id))
  assert_that(is.string(fan_speed))

  sensibo_call(
    verb = "PATCH",
    path = glue("pods/{device_id}/acStates/fanLevel"),
    body = list(newValue = fan_speed),
    encode = "json"
  )

}

#' @describeIn sensibo configuration for the maintenance job
#' @export
sensibo_config <- function() {
  tribble(
    ~device_id, ~min_temp, ~max_temp,
    "vuBuhh96", 23.5, 24.5
  )
}

#' @describeIn sensibo maintains devices according to the configuration
#' @export
sensibo_maintain_devices <- function() {
  sensibo_devices() %>%
    inner_join(sensibo_config(), by = "device_id") %>%
    filter(is_powered_on) %>%
    mutate(
      maintain_fan_speed = pmap(
        list(device_id, fan_speed, temperature, min_temp, max_temp),
        ~sensibo_maintain_fan_speed(
          device_id = ..1,
          cur_temp = ..3,
          min_temp = ..4,
          max_temp = ..5,
          curr_fan_speed = ..2
        )
      )
    )
}

