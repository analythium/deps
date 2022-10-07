#' Create a Dependencies JSON File
#'
#' @param dir Path to the directory where the files to be scanned are located.
#' @param file The name of the file to be save, default is `"dependencies.json"`.
#' @param sysreqs Logical, should system requirements be written in a separate file? Default same as `file` with `.txt` extension, i.e. `"dependencies.txt"`.
#' @param output Path to the directory where JSON file should be written to.
#' @param platform The platform supplied to `sysreqs()`. Can be `NULL` or `NA` in which case no system requirements are returned.
#' @param installed The `priority` argument for `installed.packages()` for packages to be excluded.
#' @param overwrite Logical, should the `file` in the `output` directory be overwritten if exists?
#'
#' @examples
#' dir <- system.file("examples/01-basic", package = "deps")
#' out <- tempdir()
#' create(dir, output = out)
#' cat(readLines(file.path(out, "dependencies.json")), sep = "\n")
#' unlink(file.path(out, "dependencies.json"))
#'
#' @return Invisibly returns the list of file names that were created. The side effect is a JSON (and possibly a text for system requirements) file written to the hard drive.
#' @export
create <- function(
    dir = getwd(),
    file = "dependencies.json",
    sysreqs = FALSE,
    output = dir,
    platform = "DEB",
    installed = c("base", "recommended"),
    overwrite = TRUE
) {
    o <- character(0L)
    d <- get_deps(
        dir = dir,
        platform = platform,
        installed = installed)
    write_deps(
        d,
        dir = output,
        file = file,
        overwrite = overwrite)
    o <- c(o, file.path(output, file))
    if (sysreqs) {
        tmp <- strsplit(file, "\\.")[[1L]]
        file2 <- paste0(paste(tmp[-length(tmp)], sep="."), ".txt")
        write_sysreqs(
            d,
            dir = output,
            file = file2,
            overwrite = overwrite)
        o <- c(o, file.path(output, file2))
    }
    invisible(o)
}
