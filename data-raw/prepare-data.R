suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

source_url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/ENn4iRKnW2szuR-zPKslwg/noaa-weather-sample-data-tar.gz"
archive <- tempfile(fileext = ".tar.gz")
extract_dir <- tempfile()
dir.create(extract_dir)
download.file(source_url, archive, mode = "wb", quiet = TRUE)
untar(archive, exdir = extract_dir)

source_file <- list.files(
  extract_dir,
  pattern = "jfk_weather_sample[.]csv$",
  recursive = TRUE,
  full.names = TRUE
)
if (length(source_file) != 1) {
  stop("Expected exactly one JFK weather CSV in the archive")
}

raw <- read_csv(source_file, show_col_types = FALSE, col_types = cols(.default = col_character()))
clean_number <- function(value) {
  suppressWarnings(parse_number(str_replace_all(value, "[s*]", "")))
}

weather <- tibble(
  date = as.POSIXct(raw$DATE, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  humidity = clean_number(raw$HOURLYRelativeHumidity),
  temperature_f = clean_number(raw$HOURLYDRYBULBTEMPF),
  station_pressure = clean_number(raw$HOURLYStationPressure),
  wind_speed_mph = clean_number(raw$HOURLYWindSpeed),
  precipitation_in = if_else(
    str_to_upper(str_squish(raw$HOURLYPrecip)) == "T",
    0,
    clean_number(raw$HOURLYPrecip)
  )
) |>
  filter(!is.na(date), !is.na(precipitation_in)) |>
  arrange(date)

if (nrow(weather) < 4000 || any(weather$precipitation_in < 0, na.rm = TRUE)) {
  stop("Cleaned NOAA data failed validation")
}

dir.create("data", showWarnings = FALSE, recursive = TRUE)
write_csv(weather, file.path("data", "jfk_weather_snapshot.csv"), na = "")
writeLines(
  c(
    paste("snapshot_date:", Sys.Date()),
    paste("source:", source_url),
    "station: John F. Kennedy International Airport",
    "trace_precipitation_rule: T converted to 0 inches"
  ),
  file.path("data", "SOURCES.txt")
)
