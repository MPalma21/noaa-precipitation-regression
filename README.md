# JFK Hourly Precipitation Forecasting

[![Validate Quarto project](https://github.com/MPalma21/noaa-precipitation-regression/actions/workflows/validate.yml/badge.svg)](https://github.com/MPalma21/noaa-precipitation-regression/actions/workflows/validate.yml)

A bilingual, reproducible forecasting case study built with the tidyverse and tidymodels. It treats hourly precipitation as a two-stage problem: an XGBoost classifier estimates rain occurrence and a second XGBoost model estimates precipitation amount during wet observations.

The evaluation design follows time. The earliest 70% selects model hyperparameters through expanding windows, the next 10% calibrates probabilities and amount, and the latest 20% remains untouched until final evaluation.

## Result

Expected precipitation from the two-stage model reaches **0.0430 RMSE**, a **6.2% reduction** from the historical-mean baseline and a **3.2% reduction** from the previous single-stage polynomial benchmark. Rain occurrence reaches **0.564 PR AUC** and **0.918 ROC AUC** on the final holdout.

## What this project demonstrates

- zero-inflated target modeling with an occurrence-and-amount architecture;
- leakage-aware feature engineering using only current weather and past precipitation;
- expanding-window temporal resampling rather than random cross-validation;
- probability calibration and threshold selection outside the final holdout;
- RMSE, MAE, wet-period RMSE, PR AUC, ROC AUC, and Brier score;
- fully visible, self-contained English and Spanish notebooks;
- reproducible dependencies, automated tests, and Quarto publishing metadata.

## Reproduce

```bash
Rscript -e "renv::restore()"
Rscript -e "testthat::test_dir('tests/testthat')"
quarto render
```

The committed snapshot is deterministic. To rebuild it from the documented upstream source, run `Rscript data-raw/prepare-data.R`.

## Project structure

- `index.qmd`: complete English analysis;
- `es/index.qmd`: complete Spanish analysis;
- `data/`: versioned analytical snapshot and provenance;
- `data-raw/prepare-data.R`: source-to-snapshot preparation;
- `tests/testthat/`: data and notebook integrity checks;
- `manifest.json` and `renv.lock`: Posit Connect Cloud and local reproducibility.

## Sources

- NOAA JFK sample distributed by IBM Skills Network; the exact mirror and snapshot date are recorded in `data/SOURCES.txt`.
- [Original publication](https://rpubs.com/MPalmaR19/1300536)

## Español

El [notebook en español](es/index.qmd) contiene el mismo flujo completo y autocontenido, con código visible y evaluación temporal.
