#' Does the file contain Rscript shebang
#'
#' @param file Single file name.
#' 
#' @return Logical.
#' @noRd
is_rscript <- function(
    file
) {
    l1 <- suppressWarnings(readLines(file, 1L))
    isTRUE(startsWith(l1, "#!")) && isTRUE(grepl("Rscript", l1))
}

#' List R files
#'
#' @param path Path.
#' @param ext File extensions, case insensitive.
#' @param shebang Should files with no extension checked for an Rscript shebang.
#'
#' @return Character vector with file names.
#' @noRd
deps_list_r <- function(
    path = ".",
    ext = c("R", "Rmd", "Rnw"),
    shebang = TRUE
) {
    fl <- list.files(path,
        full.names = TRUE,
        recursive = TRUE)
    fl_ext  <- tolower(tools::file_ext(fl))
    i <- fl_ext %in% tolower(ext)
    if (shebang) {
        j <- which(fl_ext == "")
        if (length(j) > 0L) {
            k <- sapply(fl[j], is_rscript)
            i[j[k]] <- TRUE
        }
    }
    fl[i]
}

#' Find tag
#'
#' @param x Character vector from `readLines()`.
#' @param tag Character, the tag to look for, e.g. `"dev"` for `@dev`.
#'
#' @return Character, subset of `x` where the tag was found.
#' @noRd
find_tag <- function(
    x,
    tag
) {
    rg <- sprintf("^#'\\s*@%s(\\s+(.*)$)?", tag)
    x[grep(rg, x)]
}

#' Parse tag
#'
#' @param x Character (length must be 1).
#' @param comma Logical, should commas be treated as separators (`TRUE`).
#'
#' @return Character, the parsed text after the tag.
#' @noRd
parse_tag <- function(
    x,
    comma = TRUE
) {
    u <- if (comma)
        gsub(",", " ", x, fixed = TRUE) else x
    u <- strsplit(u, "\\s")[[1L]]
    u[nzchar(u)][-(1:2)]
}

#' Process tag
#'
#' @param x Character (length must be 1).
#' @param tag Character, the tag to look for, e.g. `"dev"` for `@dev`.
#' @param comma Logical, should commas be treated as separators (`TRUE`).
#'
#' @return A list with parsed results for a given tag, or `NULL`.
#' @noRd
process_tag <- function(
    x,
    tag,
    comma = TRUE
) {
    out <- lapply(find_tag(x, tag), parse_tag, comma = comma)
    if (length(out))
        out else NULL
}

#' Get dependencies
#'
#' @param dir Directory to explore.
#' @param platform Platform for `sysreqs()`.
#' @param installed The `priority` argument for `installed.packages()`.
#' @param dev Logical, include 'development' dependencies as well for `renv::dependencies()`.
#'
#' @return A data frame with a sysreqs attribute.
#' @noRd
get_deps <- function(
    dir = getwd(),
    platform = "DEB",
    installed = c("base", "recommended"),
    dev = TRUE
) {
    rfl <- deps_list_r(dir)
    if (length(rfl) < 1L)
        stop("No R related files found.")
    x <- unlist(lapply(rfl, readLines))
    x <- x[grep("^#'\\s*@", x)]
    tagged_deps <- list(
        local  = process_tag(x, "local"),
        remote = process_tag(x, "remote"),
        sys    = process_tag(x, "sys"),
        ver    = process_tag(x, "ver", comma = FALSE),
        dev    = process_tag(x, "dev"),
        repo   = process_tag(x, "repo", comma = FALSE),
        repos  = process_tag(x, "repos"),
        rver   = process_tag(x, "rver"))
    installed <- rownames(utils::installed.packages(priority = installed))
    dp <- renv::dependencies(path = dir,
        progress = FALSE,
        dev = dev)[,c("Source", "Package")]
    all <- sort(unique(dp$Package))
    tb <- data.frame(package = all)
    rownames(tb) <- all
    #dev <- unique(unlist(tagged_deps$dev))
    #to_install <- setdiff(all, union(dev, installed))
    tb$installed <- all %in% installed
    tb$dev <- all %in% unique(unlist(tagged_deps$dev))
    tb$repo <- NA_character_
    for (i in tagged_deps[["repo"]]) {
        if (i[1L] %in% all)
            tb[i[1L], "repo"] <- i[2L]
    }
    tb$ver <- NA_character_
    for (i in tagged_deps$ver) {
        if (i[1L] %in% all)
            tb[i[1L], "ver"] <- paste0(i[-1L], collapse = " ")
    }

    local <- paste0("local::", unlist(tagged_deps$local))
    rems <- sort(unique(unlist(c(local, tagged_deps$remote))))
    tb$remote <- NA_character_
    for (i in all) {
        if (any(grepl(i, rems))) {
            j <- grep(i, rems)
            if (length(j) > 1L)
                stop("Multiple remotes found for package ", i, call.=FALSE)
            tb[i, "remote"] <- rems[j]
        }
    }
    sysreq <- sysreqs(all[!tb$dev], platform = platform)
    extra_sys <- unique(unlist(tagged_deps$sys))
    sysreqs <- sort(union(sysreq, extra_sys))
    sysreqs <- sysreqs[nzchar(sysreqs)]
    attr(tb, "sysreqs") <- if (is.null(sysreqs))
        character(0) else sysreqs

    attr(tb, "repos") <- if (is.null(tagged_deps[["repos"]]))
        character(0) else sort(unique(unlist(tagged_deps[["repos"]])))

    tb$source <- NA_character_
    tb$source[!tb$installed & !tb$dev & is.na(tb$ver) & is.na(tb$repo)] <- "cran"
    tb$source[!tb$installed & !tb$dev & is.na(tb$ver) & !is.na(tb$repo)] <- "repo"
    tb$source[!tb$installed & !tb$dev & !is.na(tb$ver)] <- "ver"
    if (any(!is.na(tb$remote) & !is.na(tb$ver)))
        stop("@ver and @remote cannot be both provided", call. = FALSE)
    if (any(!is.na(tb$remote) & !is.na(tb$repo)))
        stop("@ver and @repo cannot be both provided", call. = FALSE)
    tb$source[tb$source == "cran" & !is.na(tb$remote)] <- "remote"
    rownames(tb) <- NULL

    attr(tb, "version") <- "1.0"
    if (is.null(tagged_deps$rver)) {
        rver <- paste0(R.version$major, ".", R.version$minor)
    } else {
        rver <- unlist(unique(tagged_deps$rver))
        if (length(rver) != 1L)
            stop("Multiple different R versions not allowed", call. =FALSE)
    }
    rvt <- rversions()
    rvt <- rvt[startsWith(rvt$version, rver),]
    if (nrow(rvt) < 1L)
        warning(paste0("R version not publicly released: ", rver))
    rvt <- rvt[nrow(rvt),]
    attr(tb, "rver") <- rvt$version[1L]
    # attr(tb, "rver") <- rver

    tb
}

#' Write dependencies into JSON file
#'
#' @param x A dependency table from `get_deps()`.
#' @param dir Directory to save the file into.
#' @param file The file name to use.
#' @param overwrite Should the file be overwritten if exists.
#'
#' @return `NULL` invisible. A file created as a side effect.
#' @noRd
write_deps <- function(
    x,
    dir,
    file = "dependencies.json",
    overwrite = TRUE
) {
    l <- list(
        version = jsonlite::unbox(attr(x, "version")),
        rver = jsonlite::unbox(attr(x, "rver")),
        repos = attr(x, "repos"),
        sysreqs = attr(x, "sysreqs"),
        packages = x)
    if (file.exists(file.path(dir, file)) && !overwrite) {
        invisible(NULL)
    } else {
        writeLines(jsonlite::toJSON(l, pretty = TRUE), file.path(dir, file))
    }
}

#' Get System Requirements
#'
#' @param pkg Character, packages for which system requirements are needed.
#' @param platform Character, the platform to be filtered for (e.g. `"DEB"`, `"RPM`, etc. see <https://sysreqs.r-hub.io/>). Can be `NULL` or `NA` in which case no system requirements are returned.
#'
#' @examples
#' sysreqs("igraph")
#' sysreqs("igraph", platform = "RPM")
#'
#' @return A character vector.
#' @noRd
sysreqs <- function(pkg, platform = "DEB") {
    if (missing(pkg) || is.null(platform) || is.na(platform))
        return(character(0))
    j <- jsonlite::fromJSON(
        sprintf("https://sysreqs.r-hub.io/pkg/%s",
            paste0(as.character(pkg), collapse = ",")),
        simplifyVector = FALSE)
    v <- unlist(j)
    s <- sort(unique(unname(v[grep(paste0("\\.", platform), names(v))])))
    if (!is.null(s)) {
        s <- unlist(strsplit(s, "[[:space:]]"))
        s <- sort(unique(unname(s[nchar(s) > 0])))
    }
    s
}

#' R versions
#'
#' Based on `rversions::r_versions()`.
#'
#' @return A data frame.
#' @noRd
# dput(rversions::r_versions()[,1:2])
rversions <- function() {
    structure(list(version = c("0.60", "0.61", "0.61.1", "0.61.2",
    "0.61.3", "0.62", "0.62.1", "0.62.2", "0.62.3", "0.62.4", "0.63",
    "0.63.1", "0.63.2", "0.63.3", "0.64", "0.64.1", "0.64.2", "0.65",
    "0.65.1", "0.90", "0.90.1", "0.99", "1.0", "1.0.1", "1.1", "1.1.1",
    "1.2", "1.2.1", "1.2.2", "1.2.3", "1.3", "1.3.1", "1.4", "1.4.1",
    "1.5.0", "1.5.1", "1.6.0", "1.6.1", "1.6.2", "1.7.0", "1.7.1",
    "1.8.0", "1.8.1", "1.9.0", "1.9.1", "2.0.0", "2.0.1", "2.1.0",
    "2.1.1", "2.2.0", "2.2.1", "2.3.0", "2.3.1", "2.4.0", "2.4.1",
    "2.5.0", "2.5.1", "2.6.0", "2.6.1", "2.6.2", "2.7.0", "2.7.1",
    "2.7.2", "2.8.0", "2.8.1", "2.9.0", "2.9.1", "2.9.2", "2.10.0",
    "2.10.1", "2.11.0", "2.11.1", "2.12.0", "2.12.1", "2.12.2", "2.13.0",
    "2.13.1", "2.13.2", "2.14.0", "2.14.1", "2.14.2", "2.15.0", "2.15.1",
    "2.15.2", "2.15.3", "3.0.0", "3.0.1", "3.0.2", "3.0.3", "3.1.0",
    "3.1.1", "3.1.2", "3.1.3", "3.2.0", "3.2.1", "3.2.2", "3.2.3",
    "3.2.4", "3.2.5", "3.3.0", "3.3.1", "3.3.2", "3.3.3", "3.4.0",
    "3.4.1", "3.4.2", "3.4.3", "3.4.4", "3.5.0", "3.5.1", "3.5.2",
    "3.5.3", "3.6.0", "3.6.1", "3.6.2", "3.6.3", "4.0.0", "4.0.1",
    "4.0.2", "4.0.3", "4.0.4", "4.0.5", "4.1.0", "4.1.1", "4.1.2",
    "4.1.3", "4.2.0", "4.2.1"),
    date = structure(c(881225278, 882709762,
    884392315, 889903555, 894095897, 897828980, 897862405, 900069225,
    904294939, 909144521, 910967839, 912776788, 916059350, 920644034,
    923491181, 926083543, 930918195, 935749769, 939211984, 943273514,
    945260947, 949922690, 951814523, 955701858, 961058601, 966329658,
    976875565, 979553881, 983191405, 988284587, 993206462, 999261952,
    1008756894, 1012391855, 1020074486, 1024312833, 1033466791, 1036146797,
    1042212874, 1050497887, 1055757279, 1065611639, 1069416021, 1081766198,
    1087816179, 1096899878, 1100528190, 1113863193, 1119259633, 1128594134,
    1135074921, 1145875040, 1149150333, 1159870504, 1166435363, 1177407703,
    1183029426, 1191402173, 1196086444, 1202469005, 1208850329, 1214207072,
    1219654436, 1224494641, 1229936597, 1239957168, 1246018257, 1251102154,
    1256547742, 1260786504, 1271923881, 1275293425, 1287132117, 1292490724,
    1298632039, 1302683487, 1310117828, 1317366356, 1320048549, 1324541418,
    1330503010, 1333091765, 1340348984, 1351235476, 1362126509, 1364973156,
    1368688293, 1380093069, 1394093553, 1397113870, 1404976269, 1414743092,
    1425888740, 1429168413, 1434611704, 1439536398, 1449735188, 1457597745,
    1460649578, 1462259608, 1466493698, 1477901595, 1488788191, 1492758885,
    1498806251, 1506582275, 1512029105, 1521101067, 1524467078, 1530515071,
    1545293080, 1552291489, 1556262303, 1562310303, 1576137903, 1582963516,
    1587711934, 1591427116, 1592809519, 1602313524, 1613376313, 1617174315,
    1621321522, 1628579106, 1635753912, 1646899538, 1650611141, 1655967933),
    class = c("POSIXct", "POSIXt"), tzone = "UTC")),
    class = "data.frame",
    row.names = c(NA, -128L))
}

install_any <- function(x, ...) {
  ## parse installation sources: (source, pkg)
  x <- strsplit(x, "::")
  for (i in which(sapply(x, length) < 2L)) {
    if (grepl("/", x[[i]])) {
      x[[i]] <- c("github", x[[i]])
    } else {
      if (grepl("@", x[[i]])) {
        tmp <- strsplit(x[[i]], "@")[[1L]]
        x[[i]] <- c("version", tmp[1L])
        attr(x[[i]], "version") <- tmp[2L]
      } else {
        x[[i]] <- c("cran", x[[i]])
      }
    }
  }
  ## install packages
  f <- function(z, ...) {
    switch(z[1L],
      "cran" = remotes::install_cran(z[2L], ...),
      "version" = remotes::install_version(z[2L], attr(z, "version"), ...),
      "github" = remotes::install_github(z[2L], ...),
      "dev" = remotes::install_dev(z[2L], ...),
      "bioc" = remotes::install_bioc(z[2L], ...),
      "bitbucket" = remotes::install_bitbucket(z[2L], ...),
      "gitlab" = remotes::install_gitlab(z[2L], ...),
      "git" = remotes::install_git(z[2L], ...),
      "local" = remotes::install_local(z[2L], ...),
      "svn" = remotes::install_svn(z[2L], ...),
      "url" = remotes::install_url(z[2L], ...),
      stop(sprintf("unsupported installation sources: %s", z[1L])))
  }
  lapply(x, f, ...)
  invisible(NULL)
}
