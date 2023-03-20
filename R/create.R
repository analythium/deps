#' Create a Dependencies JSON File
#'
#' @param dir Path to the directory where the files to be scanned are located.
#' @param file The name of the file to be save, default is `"dependencies.json"`.
#' @param output Path to the directory where JSON file should be written to.
#' @param platform The platform supplied to `sysreqs()`.
#'   It can be `NULL` when the value of the R_DEPS_PLATFORM environment variable is used when set,
#'   defaults to `"DEB"` when R_DEPS_PLATFORM is unset.
#'   It can be `NA` in which case no system requirements are returned.
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
#' @return Invisibly returns the list of file names that were created. The side effect is a JSON (and possibly a text for system requirements) file written to the hard drive. The function fails when there are no R related files in `dir`.
#' 
#' @export
create <- function(
    dir = getwd(),
    file = "dependencies.json",
    output = dir,
    platform = NULL,
    installed = c("base", "recommended"),
    overwrite = TRUE
) {
    d <- get_deps(
        dir = dir,
        platform = platform,
        installed = installed)
    write_deps(
        d,
        dir = output,
        file = file,
        overwrite = overwrite)
    invisible(file.path(output, file))
}
