# deps

> Dependency Management with ‘roxygen’-Style Comments

Manage your source code dependencies by decorating your existing R code
with special, ‘roxygen’-style comments.

[![Build
status](https://github.com/analythium/deps/actions/workflows/check.yml/badge.svg)](https://github.com/analythium/deps/actions)
[![CRAN
version](http://www.r-pkg.org/badges/version/deps)](https://CRAN.R-project.org/package=deps)
[![CRAN RStudio mirror
downloads](http://cranlogs.r-pkg.org/badges/grand-total/deps)](https://hub.analythium.io/deps/)

``` r
#' @repo deps https://analythium.r-universe.dev
install.packages("deps", repos = "https://analythium.r-universe.dev")

#' @remote analythium/deps
remotes::install_github("analythium/deps")
```

## Why this package?

There are many similar packages out there, some aimed at reproducibility
([packrat](https://CRAN.R-project.org/package=packrat),
[Require](https://CRAN.R-project.org/package=Require),
[switchr](https://cran.r-project.org/package=switchr),
[versions](https://CRAN.R-project.org/package=versions),
[renv](https://CRAN.R-project.org/package=renv),
[capsule](https://github.com/MilesMcBain/capsule)). Others are focused
on dependency management
([remotes](https://CRAN.R-project.org/package=remotes),
[pak](https://CRAN.R-project.org/package=pak)).

**So why do we need another one?**

Full reproducibility is an important and heavyweight aspiration that
either needs locally cached package libraries, or an accurate snapshot
mirroring the local system (i.e. exactly where the package was installed
from). Full reproducibility is often required for reports, markdown
based documents, scripts. *A loosely defined project that is combined
with strict versioning requirements, often erring on the side of “more
dependencies are safer”.*

As opposed to this, package-based development is the main use case for
dependency management oriented packages. In this case, exact versions
are only managed to the extent of avoiding breaking changes (given that
testing can surface these). *A package focused workflow combined with a
“no breaking changes” philosophy to version requirements, leading to
leaner installation.*

What if you wanted to combine the best of both approaches? *A loosely
defined project with just strict-enough versioning requirements* – and
all this without having to write a `DESCRIPTION` file. Because why would
you need a `DESCRIPTION` file when you have no package? Also, a
`DESCRIPTION` file won’t let you to pin an exact the package version or
to specify alternate CRAN-like repositories…

The answer is deps: **you add comments to your code, deps does the
rest**.

``` r
#' @remote analythium/rconfig@CRAN-v0.1.3
rconfig::config()

#' @repo sf https://r-spatial.r-universe.dev
library(sf)

#' @ver rgl 0.108.3
library(rgl)
```

Once you decorated your code, you can call `deps::create()` to write
your `dependencies.json` file.

Use `deps::install()` to install dependencies based on scanning a
project folder or using and existing `dependencies.json` file.

## What deps does

Required packages are found using the
[`renv::dependencies()`](https://rstudio.github.io/renv/reference/dependencies.html)
function. System dependencies can be specified as well, but are not
actively sought out.

The packages list found by `renv::dependencies()` is refined and
modified by ‘roxygen’-style comments. But the packages need to be
declared/used somewhere in the source code for the comments to take
effect.

If no comment is provided for a given package, its source is assumed to
be a CRAN repository, and its version to be the latest given the
repositories used at the time of installation.

## Tags

Tags are part of the [‘roxygen’-style
comments](https://cran.r-project.org/package=roxygen2):

``` r
#' @<tag> <parameter>
```

where `#'` is followed by space, the tag starting with `@`, space, and
some parameters.

deps implements the following tags:

| Tag       | Description              | Usage                         |
|-----------|--------------------------|-------------------------------|
| `@sys`    | System requirement(s)    | `@sys req1,req2,...`          |
| `@remote` | Remote source(s)         | `@remote remote1,remote2,...` |
| `@local`  | Local source(s)          | `@local path1,path2,...`      |
| `@ver`    | Versioned package        | `@ver pkg version`            |
| `@dev`    | Development package(s)   | `@dev pkg1,pkg2,...`          |
| `@repo`   | CRAN-like source         | `@repo pkg repo`              |
| `@repos`  | Global CRAN-like repo(s) | `@repos repo1,repo2,...`      |
| `@rver`   | R version                | `@rver 4.1.3`                 |

#### System requirements

Known system requirements can be declared using the `@sys` tag, packages
can be separated by commas:

``` r
#' @sys curl,git
```

These packages are added to the list of requirements for the
non-development packages.

#### Remote sources

Remotely sourced packages are declared using the `@remote`tag following
the
[`remotes`](https://CRAN.R-project.org/package=remotes/vignettes/dependencies.html)
specifications:

``` r
#' @remote analythium/rconfig@CRAN-v0.1.3
rconfig::config()
```

This is effectively a version pinning for remotely sourced packages.

#### Local packages

The `@local` tag can be used to provide a path to local directory, or
compressed file (tar, zip, tar.gz, tar.bz2, tgz2, or tbz) to install
packages from:

``` r
#' @local mypackage_0.1.0.tar.gz
library(mypackage)
```

This is effectively the same as:

``` r
#' @remote local::mypackage_0.1.0.tar.gz
library(mypackage)
```

#### Development packages

Dev packages following the `@dev` decorator are excluded from
installation, but are not removed if already installed:

``` r
#' @dev devtools,roxygen2
requireNamespace("devtools")
```

#### Alternative repos

Use the `@repo` tag to specify an alternative CRAN-like repository,
e.g. from the [r-universe](https://r-universe.dev/):

``` r
#' @repo intrval https://psolymos.r-universe.dev
library(intrval)
```

Use the `@repos` tag to set CRAN-like repositories for all package
installation:

``` r
#' @repos http://cran.r-project.org,https://psolymos.r-universe.dev
```

#### Versioned packages

When CRAN packages require specific a version, use the `@ver` tag
according to the
[`remotes::install_version()`](https://remotes.r-lib.org/reference/install_version.html)
function specifications:

``` r
#' @ver mefa4 >= 0.3-0
library(mefa4)
```

#### R version

R version declared using the `@rver` tag is recorded, but this
information is not used during installation. The R version can be a
major (`3`), a major-minor (`3.6`) or a major-minor-patch (`3.6.3`)
version. When the version is partially specified, the highest
minor/patch version will be used. Use dots as separators.

## Usage

The `create()` function will crawl the project directory for package
dependencies. It will amend the dependency list and package sources
based on the comments. The summary is written into the
`dependencies.json` file. Optionally, the system requirements are
written into the `dependencies.json` file as well.

`install()` will look for the `dependencies.json` file in the root of
the project directory and perform dependency installation if the file
exists. If the file does not exist, it uses `create()` to create that
file before attempting installation but removes the `dependencies.json`
file afterwards, leaving no trace.

## deps-cli

A CLI example is given in
[`inst/examples/03-cli`](./inst/examples/03-cli/):

``` bash
cp inst/examples/03-cli/deps-cli.R /usr/local/bin/deps-cli
chmod +x /usr/local/bin/deps-cli
```

You can download the CLI script from the web, it will install deps and
other required R packages on its first usage:

``` bash
curl -fsSL https://hub.analythium.io/deps/deps-cli.R -o /usr/local/bin/deps-cli
chmod +x /usr/local/bin/deps-cli
```

Usage of the CLI as explained in `deps-cli help`:

    🚀 Quickly install R package dependencies on the command line

    👉 MIT (c) Analythium Solutions Inc. 2022-2023
              _                           _ _ 
           __| | ___ _ __  ___        ___| (_)
          / _` |/ _ \ '_ \/ __|_____ / __| | |
         | (_| |  __/ |_) \__ \_____| (__| | |
          \__,_|\___| .__/|___/      \___|_|_|
                    |_|                       

    🔗 See https://github.com/analythium/deps

    deps-cli is based on deps 0.1.2 2023-03-23 

    Usage: deps-cli <command> [options]

    Commands:
      deps-cli help         Print usage and exit
      deps-cli version      Print version and exit
      deps-cli create       Scan DIR and write dependencies.json
      deps-cli sysreqs      Install system requirements
      deps-cli install      Install R package dependencies
      deps-cli all          create & sysreqs & install in one go

    Options:
      --dir DIR             Directory to scan, defaults to .
      --upgrade             Upgrade package dependencies
      --silent              Silent, no info printed

    Examples:
      deps-cli help
      deps-cli version
      deps-cli create
      deps-cli create --silent
      deps-cli sysreqs
      deps-cli install --dir /root/app
      deps-cli all --dir /root/app --upgrade

Analyze dependencies, install system and R dependencies in 1 line:

``` bash
deps all

# same as
deps-cli create && deps-cli sysreqs && deps-cli install
```

`deps-cli install` looks for the following files before attempting to
detect dependencies: `renv.lock`, `pkg.lock`, and `DESCRIPTION`.

In a Dockerfile you can:

``` dockerfile
FROM rocker/r2u:24.04
RUN install.r remotes renv pak rconfig jsonlite yaml deps
RUN installGithub.r analythium/deps
RUN cp -p $(R RHOME)/site-library/deps/examples/03-cli/deps-cli.R /usr/local/bin/deps-cli
RUN chmod +x /usr/local/bin/deps-cli

COPY ... # your files

RUN deps-cli all
...
```

Or simply use the
[`ghcr.io/analythium/deps:latest`](<https://github.com/analythium/deps/pkgs/container/deps>)
as your parent image where the `deps-cli` is already installed:

``` dockerfile
FROM ghcr.io/analythium/deps:latest
...
```

## Examples

See the [`inst/examples`](./inst/examples/) folder for more examples.

## Notes

The deps package uses a 5 minutes timeout for downloads instead of the
default 1 minute (`getOption("timeout")`). When the timeout option or
the `R_DEFAULT_INTERNET_TIMEOUT` environment variable is set to a \>5
minutes value, it will be respected and timeout will be set to the
maximum of the three possible values.

The `create()` function prompts the user asking confirmation before
writing the `dependencies.json` file. Use `create(ask = FALSE)` to
bypass the prompt.

## License

[MIT License](./LICENSE) © 2022-2023 Peter Solymos and Analythium
Solutions Inc.
