library(testthat)
library(tidyverse)
library(here)

notebook_paths <- c(
  here("index.qmd"),
  here("es", "index.qmd")
)

test_that("weather snapshot has valid temporal and numeric fields", {
  weather <- read_csv(
    here("data", "jfk_weather_snapshot.csv"),
    show_col_types = FALSE,
    col_types = cols(date = col_datetime())
  )

  expect_gt(nrow(weather), 4000)
  expect_equal(anyDuplicated(weather$date), 0)
  expect_false(is.unsorted(weather$date))
  expect_true(all(weather$precipitation_in >= 0))
  expect_true(mean(weather$precipitation_in > 0) < 0.15)
})

test_that("notebooks are self-contained tidyverse analyses", {
  notebook_text <- map_chr(notebook_paths, read_file)

  expect_true(all(str_detect(notebook_text, "library\\(tidyverse\\)")))
  expect_true(all(str_detect(notebook_text, "library\\(tidymodels\\)")))
  expect_false(any(str_detect(notebook_text, "source\\(")))
  expect_false(any(str_detect(notebook_text, "<-\\s*function\\s*\\(")))
  expect_false(any(str_detect(notebook_text, "vfold_cv\\(")))
  expect_true(all(str_detect(notebook_text, "rolling_origin\\(")))
})

test_that("every R chunk is named and concise", {
  for (path in notebook_paths) {
    lines <- read_lines(path)
    starts <- which(str_detect(lines, "^```\\{r\\}"))
    ends <- which(lines == "```")

    for (start in starts) {
      end <- ends[ends > start][[1]]
      body <- lines[(start + 1):(end - 1)]
      labels <- body[str_detect(body, "^#\\| label:")]

      expect_length(labels, 1)
      expect_lte(length(body), 25)
    }
  }
})

test_that("temporal partitions do not overlap", {
  weather <- read_csv(
    here("data", "jfk_weather_snapshot.csv"),
    show_col_types = FALSE,
    col_types = cols(date = col_datetime())
  ) |>
    arrange(date)

  final_cut <- floor(0.8 * nrow(weather))
  calibration_cut <- floor(0.875 * final_cut)

  expect_lt(weather$date[[calibration_cut]], weather$date[[calibration_cut + 1]])
  expect_lt(weather$date[[final_cut]], weather$date[[final_cut + 1]])
})

test_that("deployment manifest includes the boosted-tree engine", {
  manifest <- read_file(here("manifest.json"))
  expect_match(manifest, '"xgboost"', fixed = TRUE)
})
