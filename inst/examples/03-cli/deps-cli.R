#!/usr/bin/env Rscript

# Setup:
#     cp inst/examples/03-cli/deps-cli.R /usr/local/bin/deps-cli
#     chmod +x /usr/local/bin/deps-cli
# Now you can use it as explained in deps-cli help, e.g.:
#     deps-cli create && deps-cli sysreqs && deps-cli install

if (!requireNamespace("deps")) {
    install.packages(c("rconfig", "deps", "remotes", "pak", "renv"),
        repos = c("https://cloud.r-project.org", "https://analythium.r-universe.dev"))
}

CONFIG <- rconfig::rconfig()
CMD <- rconfig::command(CONFIG)
DIR <- rconfig::value(CONFIG$dir, getwd())
UPGRADE <- rconfig::value(CONFIG$upgrade, FALSE)

OPTIONS <- '

Quickly install dependencies on the command line

    MIT (c) Analythium Solutions Inc. 2022
          _                           _ _ 
       __| | ___ _ __  ___        ___| (_)
      / _` |/ _ \\ \'_ \\/ __|_____ / __| | |
     | (_| |  __/ |_) \\__ \\_____| (__| | |
      \\__,_|\\___| .__/|___/      \\___|_|_|
                |_|                       

Usage: deps-cli <command> [options]

Commands:
  deps-cli help         Print usage and exit
  deps-cli version      Print version and exit
  deps-cli create       Scan DIR and write dependencies.json
  deps-cli sysreqs      Install system requirements
  deps-cli install      Install R package dependencies
  deps-cli all          create+sysreqs+install in one

Options:
  --dir DIR             Directory to scan, defaults to .
  --upgrade             Upgrade package dependencies

Examples:
  deps-cli help
  deps-cli version
  deps-cli create
  deps-cli sysreqs
  deps-cli install --dir /root/app
  deps-cli all --dir /root/app --upgrade

'

help <- function(...) {
    cat(OPTIONS)
    invisible(NULL)
}

version <- function(...) {
    ver <- read.dcf(
        file = system.file("DESCRIPTION", package = "deps"),
        fields=c("Version", "Date"))
    cat("\ndeps-cli is based on deps", ver, "\n")
    invisible(NULL)
}

create <- function(DIR, ...) {
    deps::create(DIR, overwrite = FALSE)
    invisible(NULL)
}

sysreqs <- function(DIR, ...) {
    if (!file.exists(file.path(DIR, "dependencies.json"))) {
        deps::create(DIR, output = tempdir())
        depsfile <- file.path(tempdir(), "dependencies.json")
    } else {
        depsfile <- file.path(DIR, "dependencies.json")
    }
    reqs <- jsonlite::fromJSON(depsfile)[["sysreqs"]]
    if (!is.null(reqs) && length(reqs) > 0L) {
        system2("apt-get", "update")
        system2("apt-get", sprintf(
            "install -y --no-install-recommends %s",
            paste0(as.character(reqs), collapse = " ")))
        system2("rm", "-rf /var/lib/apt/lists/*")
    }
    invisible(NULL)
}

install <- function(DIR, UPGRADE, ...) {
    if (file.exists(file.path(DIR, "renv.lock"))) {
        options(renv.consent = TRUE)
        renv::restore(DIR, lockfile = 'renv.lock', prompt = FALSE)
    } else if (file.exists(file.path(DIR, "pkg.lock"))) {
        pak::lockfile_install(file.path(DIR, "pkg.lock"), update = UPGRADE)
    } else if (file.exists(file.path(DIR, "DESCRIPTION"))) {
        remotes::install_deps(DIR, upgrade = UPGRADE)
    } else {
        deps::install(DIR, upgrade = UPGRADE)
    }
    invisible(NULL)
}

all <- function(DIR, UPGRADE, ...) {
    if (!file.exists(file.path(DIR, "dependencies.json")))
        on.exit(unlink(file.exists(file.path(DIR, "dependencies.json"))))
    create(DIR)
    sysreqs(DIR)
    install(DIR, UPGRADE, ...)
    invisible(NULL)
}

FUN <- list(
    "help"    = help,
    "version" = version,
    "create"  = create,
    "sysreqs" = sysreqs,
    "install" = install,
    "all"     = all)

if (length(CMD) != 1L || !(CMD %in% names(FUN)))
    stop("\nCommand not found, see deps-cli help for available commands.\n",
        call. = FALSE)

FUN[[CMD]](DIR, UPGRADE)

quit("no", 0, FALSE)
