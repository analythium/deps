
# wtite temporary DESCRIPTION with
# * Imports: tb$source=="cran"
# * Remotes:tb$source=="remote"
# --> install_deps will install Imports+Remotes (this will use apt get)
#     this also includes @local using the local:: remote spec
#
# install.packages will install tb$source=="repo"
#
# install_version will install tb$source=="ver"

#' Create a Dependencies JSON File
#'
#' @param dir Path to the directory where the JSON file should be written to.
#' @param file The name of the file to be save, default is `"dependencies.json"`. If the file is not found in `dir`, `create()` is called.
#' @param upgrade Should package dependencies be upgraded? Argument passed to remotes functions.
#' @param cleanup Logical, clean up files created by `create()` when `file` does not exist.
#' @param timeout Integer, timeout for file downloads (default 60 seconds can be short).
#' @param ...  Other argument passed to remotes functions.
#'
#' @examples
#' \dontrun{
#' dir <- system.file("examples/01-basic", package = "deps")
#' out <- tempdir()
#' create(dir, output = out)
#' install(out)
#' unlink(file.path(out, "dependencies.json"))
#' }
#'
#' @return Returns `NULL` invisibly. The side effect is the dependencies installed.
#' @export
install <- function(
    dir = getwd(),
    file = "dependencies.json",
    upgrade = "never",
    cleanup = TRUE,
    timeout = 300L,
    ...
) {
    uto <- suppressWarnings(
        as.integer(Sys.getenv("R_DEFAULT_INTERNET_TIMEOUT")))
    if (is.na(uto))
        uto <- timeout
    oo <- options(timeout = max(uto, timeout, getOption("timeout")))
    on.exit(options(oo), add = TRUE)
    created <- file.exists(file.path(dir, file))
    if (!created) {
        dfile <- create(dir = dir, file = file)
        if (cleanup)
            on.exit(unlink(dfile), add = TRUE)
    }
    d <- jsonlite::fromJSON(readLines(file.path(dir, file)))
    p <- d$packages[!is.na(d$packages$source),]
    r <- p$repos
    if (length(r) > 0L) {
        o <- getOption("repos")
        on.exit(options("repos" = o), add = TRUE)
        options("repos" = c(o, r))
    }
    desc <- c("Imports:\n  ",
        paste(
            sort(p$package[p$source %in% c("cran", "remote")]),
            collapse = ",\n  "))
    if (any(p$source == "remote")) {
        desc <- c(desc, "\nRemotes:\n  ",
            paste(
                sort(p$remote[p$source == "remote"]),
                collapse = ",\n  "),
            "\n")
    }
    desc <- paste0(desc, collapse = "")
    tmpdir <- tempdir()
    writeLines(
        desc,
        file.path(tmpdir, "DESCRIPTION"))
    remotes::install_deps(
        pkgdir = tmpdir,
        upgrade = upgrade,
        ...)

    inst_repo <- p[p$source == "repo",]
    for (re in unique(inst_repo$repo)) {
        remotes::install_cran(
            pkgs = inst_repo$package[inst_repo$repo == re],
            repos = re,
            upgrade = upgrade,
            ...)
    }
    inst_ver <- sort(p$package[p$source == "ver"])
    inst_ver <- p[p$source == "ver",]
    for (i in seq_len(nrow(inst_ver))) {
        remotes::install_version(
            package = inst_ver$package[i],
            version = inst_ver$ver[i],
            upgrade = upgrade,
            ...)
    }
    invisible(NULL)
}
