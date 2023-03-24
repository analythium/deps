#' Create a Dependencies JSON File
#'
#' Discover dependencies and write a `dependencies.json` file.
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
#' @param ask Logical, asking confirmation before writing the `dependencies.json` file.
#'
#' @examples
#' dir <- system.file("examples/01-basic", package = "deps")
#' out <- tempdir()
#' create(dir, output = out, ask = interactive())
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
    overwrite = TRUE,
    ask = TRUE
) {
    if (ask) {
        cat("Do you want the dependencies.json file to be saved?")
        if (utils::menu(c("Yes", "No")) != 1L){
            return(invisible())
        }
    }
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
