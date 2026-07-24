suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidymodels)
}))

read_weather_snapshot <- function(path = here::here("data", "jfk_weather_snapshot.csv")) {
  data <- read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(date = col_datetime())
  ) |>
    arrange(date)
  validate_weather_data(data)
  data
}

validate_weather_data <- function(data) {
  required <- c(
    "date", "humidity", "temperature_f", "station_pressure",
    "wind_speed_mph", "precipitation_in"
  )
  missing_columns <- setdiff(required, names(data))
  if (length(missing_columns) > 0) {
    stop("Weather data is missing columns: ", paste(missing_columns, collapse = ", "))
  }
  if (anyDuplicated(data$date)) {
    stop("Weather timestamps must be unique")
  }
  if (any(data$precipitation_in < 0, na.rm = TRUE)) {
    stop("Precipitation cannot be negative")
  }
  invisible(TRUE)
}

prediction_metrics <- function(predictions, model_name) {
  tibble(
    model = model_name,
    .metric = c("rmse", "mae", "rsq"),
    .estimate = c(
      rmse_vec(predictions$precipitation_in, predictions$.pred),
      mae_vec(predictions$precipitation_in, predictions$.pred),
      rsq_trad_vec(predictions$precipitation_in, predictions$.pred)
    )
  )
}

fit_weather_models <- function(data, seed = 2026, folds = 5L) {
  set.seed(seed)
  split <- initial_time_split(data, prop = 0.8)
  training_data <- training(split)
  testing_data <- testing(split)
  resamples <- vfold_cv(training_data, v = folds)

  baseline_predictions <- testing_data |>
    transmute(precipitation_in, .pred = mean(training_data$precipitation_in))

  base_recipe <- recipe(
    precipitation_in ~ humidity + temperature_f + station_pressure + wind_speed_mph,
    data = training_data
  ) |>
    step_impute_median(all_numeric_predictors()) |>
    step_normalize(all_numeric_predictors())

  linear_workflow <- workflow() |>
    add_recipe(base_recipe) |>
    add_model(linear_reg() |> set_engine("lm"))
  linear_fit <- fit(linear_workflow, training_data)
  linear_predictions <- bind_cols(
    testing_data |> select(precipitation_in),
    predict(linear_fit, testing_data)
  )

  ridge_workflow <- workflow() |>
    add_recipe(base_recipe) |>
    add_model(linear_reg(penalty = tune(), mixture = 0) |> set_engine("glmnet"))
  ridge_results <- tune_grid(
    ridge_workflow,
    resamples = resamples,
    grid = grid_regular(penalty(range = c(-5, 0)), levels = 8),
    metrics = metric_set(rmse, mae, rsq)
  )
  best_penalty <- select_best(ridge_results, metric = "rmse")
  ridge_fit <- ridge_workflow |>
    finalize_workflow(best_penalty) |>
    fit(training_data)
  ridge_predictions <- bind_cols(
    testing_data |> select(precipitation_in),
    predict(ridge_fit, testing_data)
  )

  polynomial_recipe <- base_recipe |>
    step_poly(temperature_f, humidity, station_pressure, wind_speed_mph, degree = 2)
  polynomial_workflow <- workflow() |>
    add_recipe(polynomial_recipe) |>
    add_model(linear_reg() |> set_engine("lm"))
  polynomial_fit <- fit(polynomial_workflow, training_data)
  polynomial_predictions <- bind_cols(
    testing_data |> select(precipitation_in),
    predict(polynomial_fit, testing_data)
  )

  metrics <- bind_rows(
    prediction_metrics(baseline_predictions, "Mean baseline"),
    prediction_metrics(linear_predictions, "Linear regression"),
    prediction_metrics(ridge_predictions, "Ridge regression"),
    prediction_metrics(polynomial_predictions, "Polynomial regression")
  ) |>
    select(model, .metric, .estimate) |>
    arrange(.metric, .estimate)

  list(
    split = split,
    metrics = metrics,
    best_penalty = best_penalty,
    predictions = list(
      baseline = baseline_predictions,
      linear = linear_predictions,
      ridge = ridge_predictions,
      polynomial = polynomial_predictions
    )
  )
}

plot_precipitation_distribution <- function(data, language = c("en", "es")) {
  language <- match.arg(language)
  labels <- if (language == "en") {
    c(title = "Hourly precipitation is strongly zero-inflated", x = "Precipitation (inches)", y = "Observations")
  } else {
    c(title = "La precipitación horaria contiene una gran proporción de ceros", x = "Precipitación (pulgadas)", y = "Observaciones")
  }
  ggplot(data, aes(precipitation_in)) +
    geom_histogram(binwidth = 0.01, boundary = 0, fill = "#2A9D8F", color = "white") +
    coord_cartesian(xlim = c(0, stats::quantile(data$precipitation_in, 0.995, na.rm = TRUE))) +
    labs(title = labels[["title"]], x = labels[["x"]], y = labels[["y"]]) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"))
}
