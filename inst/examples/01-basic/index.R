## This is a basic example for the deps package

a = 2
b <- a + 2

#' @param z A value.
f <- function(z) {
    z+2
}

## Packages are listed based on
## <https://rstudio.github.io/renv/reference/dependencies.html>

## System requirements are declared using the @sys tag
#' @sys curl,git

## Remote sourced packages are declared using the @remote tag
## follow the {remotes} specifications:
## <https://cloud.r-project.org/web/packages/remotes/vignettes/dependencies.html>
#' @remote analythium/rconfig@CRAN-v0.1.3
## You cna also use local::package_0.1.0.tar.gz
## or use the `@local package_0.1.0.tar.gz` for the same effect
rconfig::rconfig()

## Development packages following the @dev tag are excluded
#' @dev devtools,roxygen2
requireNamespace("devtools")

## Use the @repo tag to specify an alternative CRAN-like repository
#' @repo intrval https://psolymos.r-universe.dev
library(intrval)

## Use the @repos tag to globally specify CRAN-like repositories
#' @repos https://r-spatial.r-universe.dev,https://psolymos.r-universe.dev

## When CRAN packages require specific version, use the @ver tag
#' @ver mefa4 >= 0.3-0
library(mefa4)

## This is a recommended package and is likely installed already
library(MASS)
