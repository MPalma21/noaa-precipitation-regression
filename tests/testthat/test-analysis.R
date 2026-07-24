source(here::here("R", "analysis.R"))

test_that("weather snapshot has valid temporal and numeric fields", {
  weather <- read_weather_snapshot()
  expect_true(nrow(weather) > 4000)
  expect_false(anyDuplicated(weather$date) > 0)
  expect_true(all(weather$precipitation_in >= 0))
  expect_true(is.unsorted(weather$date) == FALSE)
})

test_that("model evaluation uses a holdout and returns all metrics", {
  weather <- read_weather_snapshot() |>
    slice_head(n = 1200)
  results <- fit_weather_models(weather, folds = 3)
  expect_setequal(
    unique(results$metrics$model),
    c("Mean baseline", "Linear regression", "Ridge regression", "Polynomial regression")
  )
  expect_setequal(unique(results$metrics$.metric), c("rmse", "mae", "rsq"))
  expect_true(all(is.finite(results$metrics$.estimate)))
  expect_true(nrow(testing(results$split)) > 0)
})

test_that("negative precipitation is rejected", {
  weather <- read_weather_snapshot()
  weather$precipitation_in[[1]] <- -1
  expect_error(validate_weather_data(weather), "cannot be negative")
})
