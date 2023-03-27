#!/usr/bin/env Rscript

# Setup:
#     cp inst/examples/03-cli/deps-cli.R /usr/local/bin/deps-cli
#     chmod +x /usr/local/bin/deps-cli
# Now you can use it as explained in deps-cli help, e.g.:
#     deps-cli create && deps-cli sysreqs && deps-cli install

NOW <- Sys.time()

suppressMessages({
    if (!requireNamespace("deps")) {
        install.packages(c("rconfig", "deps", "remotes", "pak", "renv"))
    }
})

CONFIG <- rconfig::rconfig()
CMD <- rconfig::command(CONFIG)
DIR <- rconfig::value(CONFIG[["dir"]], getwd())
UPGRADE <- rconfig::value(CONFIG[["upgrade"]], FALSE)
SILENT <- rconfig::value(CONFIG[["silent"]], FALSE)
FROMFILE <- rconfig::value(CONFIG[["from-file"]], FALSE)

HEADER <- '
🚀 Quickly install R package dependencies on the command line

👉 MIT (c) Analythium Solutions Inc. 2022-2023
          _                           _ _ 
       __| | ___ _ __  ___        ___| (_)
      / _` |/ _ \\ \'_ \\/ __|_____ / __| | |
     | (_| |  __/ |_) \\__ \\_____| (__| | |
      \\__,_|\\___| .__/|___/      \\___|_|_|
                |_|                       

🔗 See https://github.com/analythium/deps
'

FOOTER <- '
🚀 Dependencies successfully installed in %s

'

OPTIONS <- '
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
  --from-file           Install only from lock/dependency file

Examples:
  deps-cli help
  deps-cli version
  deps-cli create
  deps-cli create --silent
  deps-cli sysreqs
  deps-cli install --from-file
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
    try(deps::create(DIR, overwrite = FALSE, ask = FALSE))
    invisible(NULL)
}

sysreqs <- function(DIR, ...) {
    if (!file.exists(file.path(DIR, "dependencies.json"))) {
        try(deps::create(DIR, output = tempdir(), ask = FALSE))
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

install <- function(DIR, UPGRADE, FROMFILE, ...) {
    if (file.exists(file.path(DIR, "dependencies.json"))) {
        try(deps::install(DIR, upgrade = UPGRADE, ask = FALSE)
    } else if (file.exists(file.path(DIR, "renv.lock"))) {
        options(renv.consent = TRUE)
        try(renv::restore(DIR, lockfile = 'renv.lock', prompt = FALSE))
    } else if (file.exists(file.path(DIR, "pkg.lock"))) {
        try(pak::lockfile_install(file.path(DIR, "pkg.lock"), update = UPGRADE))
    } else if (file.exists(file.path(DIR, "DESCRIPTION"))) {
        try(remotes::install_deps(DIR, upgrade = UPGRADE))
    } else {
        if (!FROMFILE)
            try(deps::install(DIR, upgrade = UPGRADE, ask = FALSE)
    }
    invisible(NULL)
}

all <- function(DIR, UPGRADE, FROMFILE, ...) {
    if (!file.exists(file.path(DIR, "dependencies.json")))
        on.exit(unlink(file.path(DIR, "dependencies.json")))
    create(DIR, ask = FALSE)
    sysreqs(DIR)
    install(DIR, UPGRADE, FROMFILE, ask = FALSE, ...)
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

if (!SILENT) {
    cat(HEADER)
    if (CMD == "help") {
        version()
    }
}
FUN[[CMD]](DIR, UPGRADE, FROMFILE)
if (!SILENT && CMD %in% c("sysreqs", "install", "all")) {
    if (CMD != "version") {
        version()
    }
    ELAPSED <- Sys.time() - NOW
    cat(sprintf(FOOTER, format(ELAPSED, digits = 2L)))
}
quit("no", 0, FALSE)
