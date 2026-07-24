# NOAA Precipitation Regression / Regresión de precipitación NOAA

Bilingual Quarto project comparing a baseline, linear, ridge, and polynomial regression with a time-ordered final holdout. It corrects the original use of training errors and reports RMSE, MAE, and R² on unseen observations.

Proyecto bilingüe que compara baseline, regresión lineal, ridge y polinómica con prueba temporal final. Corrige el uso original de errores de entrenamiento.

## Reproduce / Reproducir

```bash
Rscript data-raw/prepare-data.R
Rscript -e "renv::restore(); testthat::test_dir('tests/testthat')"
quarto render
```

## Sources / Fuentes

- NOAA JFK sample distributed by IBM Skills Network; exact mirror and snapshot date are recorded in `data/SOURCES.txt`.
- Original publication: https://rpubs.com/MPalmaR19/1300536
- GitHub: https://github.com/MPalma21/noaa-precipitation-regression
- Posit Connect Cloud: added after deployment.

