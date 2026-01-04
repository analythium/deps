## Silently read files
read_lines <- function(...) {
    # v <- try(suppressWarnings(readLines(...)))
    # if (inherits(v, "try-error"))
    #     "" else v
    suppressWarnings(readLines(...))
}

#' Does the file contain Rscript shebang
#'
#' @param file Single file name.
#'
#' @return Logical.
#' @noRd
is_rscript <- function(
    file
) {
    l1 <- read_lines(file, 1L)
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
    ext = c("R", "Rmd", "Rnw", "qmd"),
    shebang = TRUE
) {
    if (!dir.exists(path)) {
        stop(sprintf("Path %s invalid or does not exist.", path), call. = FALSE)
    }
    fl <- list.files(path, full.names = TRUE, recursive = TRUE)
    fl_ext <- tolower(tools::file_ext(fl))
    i <- fl_ext %in% tolower(ext)
    if (shebang) {
        j <- which(fl_ext == "")
        if (length(j) > 0L) {
            k <- sapply(fl[j], is_rscript)
            i[j[k]] <- TRUE
        }
    }
    fl <- fl[i]
    if (any(c("rmd", "qmd") %in% tolower(tools::file_ext(fl)))) {
        if (!("rmarkdown" %in% rownames(utils::installed.packages()))) {
            stop(
                "The 'rmarkdown' package is required in to crawl dependencies in R Markdown and Quarto files.",
                call. = FALSE
            )
        }
    }
    fl
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
    u <- if (comma) {
        gsub(",", " ", x, fixed = TRUE)
    } else {
        x
    }
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
    if (length(out)) {
        out
    } else {
        NULL
    }
}

#' Get dependencies
#'
#' @param dir Directory to explore.
#' @param installed The `priority` argument for `installed.packages()`.
#' @param dev Logical, include 'development' dependencies as well for `renv::dependencies()`.
#'
#' @return A data frame with a sysreqs attribute.
#' @noRd
get_deps <- function(
    dir = getwd(),
    installed = c("base", "recommended"),
    dev = TRUE
) {
    rfl <- deps_list_r(dir)
    if (length(rfl) < 1L) {
        stop("No R related files found.")
    }
    x <- unlist(lapply(rfl, read_lines))
    x <- x[grep("^#'\\s*@", x)]
    tagged_deps <- list(
        local = process_tag(x, "local"),
        remote = process_tag(x, "remote"),
        sys = process_tag(x, "sys"),
        ver = process_tag(x, "ver", comma = FALSE),
        dev = process_tag(x, "dev"),
        repo = process_tag(x, "repo", comma = FALSE),
        repos = process_tag(x, "repos"),
        rver = process_tag(x, "rver")
    )
    installed <- rownames(utils::installed.packages(priority = installed))
    dp <- renv::dependencies(
        path = dir,
        root = NULL,
        progress = FALSE,
        dev = dev
    )[, c("Source", "Package")]
    all <- sort(unique(dp$Package))
    tb <- data.frame(package = all)
    rownames(tb) <- all
    #dev <- unique(unlist(tagged_deps$dev))
    #to_install <- setdiff(all, union(dev, installed))
    tb$installed <- all %in% installed
    tb$dev <- all %in% unique(unlist(tagged_deps$dev))
    tb$repo <- rep(NA_character_, nrow(tb))
    for (i in tagged_deps[["repo"]]) {
        if (i[1L] %in% all) {
            tb[i[1L], "repo"] <- i[2L]
        }
    }
    tb$ver <- rep(NA_character_, nrow(tb))
    for (i in tagged_deps$ver) {
        if (i[1L] %in% all) {
            tb[i[1L], "ver"] <- paste0(i[-1L], collapse = " ")
        }
    }

    local <- paste0("local::", unlist(tagged_deps$local))
    rems <- sort(unique(unlist(c(local, tagged_deps$remote))))
    tb$remote <- rep(NA_character_, nrow(tb))
    for (i in all) {
        if (any(grepl(i, rems))) {
            j <- grep(i, rems)
            if (length(j) > 1L) {
                stop("Multiple remotes found for package ", i, call. = FALSE)
            }
            tb[i, "remote"] <- rems[j]
        }
    }
    sysreqs <- sort(unique(unlist(tagged_deps$sys)))
    sysreqs <- sysreqs[nzchar(sysreqs)]
    attr(tb, "sysreqs") <- if (is.null(sysreqs)) {
        character(0)
    } else {
        sysreqs
    }

    attr(tb, "repos") <- if (is.null(tagged_deps[["repos"]])) {
        character(0)
    } else {
        sort(unique(unlist(tagged_deps[["repos"]])))
    }

    tb$source <- rep(NA_character_, nrow(tb))
    tb$source[
        !tb$installed & !tb$dev & is.na(tb$ver) & is.na(tb$repo)
    ] <- "cran"
    tb$source[
        !tb$installed & !tb$dev & is.na(tb$ver) & !is.na(tb$repo)
    ] <- "repo"
    tb$source[!tb$installed & !tb$dev & !is.na(tb$ver)] <- "ver"
    check_remote_ver <- !is.na(tb$remote) & !is.na(tb$ver)
    if (any(check_remote_ver)) {
        stop(
            sprintf(
                "@ver and @remote cannot be both provided: %s",
                paste0(rownames(tb)[check_remote_ver], collapse = ", ")
            ),
            call. = FALSE
        )
    }
    check_remote_repo <- !is.na(tb$remote) & !is.na(tb$repo)
    if (any(check_remote_repo)) {
        stop(
            sprintf(
                "@repo and @remote cannot be both provided: %s",
                paste0(rownames(tb)[check_remote_repo], collapse = ", ")
            ),
            call. = FALSE
        )
    }
    tb$source[tb$source == "cran" & !is.na(tb$remote)] <- "remote"
    rownames(tb) <- NULL

    attr(tb, "version") <- "1.0"
    if (is.null(tagged_deps$rver)) {
        rver <- paste0(R.version$major, ".", R.version$minor)
    } else {
        rver <- unlist(unique(tagged_deps$rver))
        if (length(rver) != 1L) {
            stop("Multiple different R versions not allowed", call. = FALSE)
        }
    }
    rvt <- rversions()
    rvt <- rvt[startsWith(rvt$version, rver), ]
    if (nrow(rvt) < 1L) {
        # warning(paste0("R version not publicly released: ", rver))
        attr(tb, "rver") <- rver
    } else {
        rvt <- rvt[nrow(rvt), ]
        attr(tb, "rver") <- rvt$version[1L]
    }

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
        packages = x
    )
    if (file.exists(file.path(dir, file)) && !overwrite) {
        invisible(NULL)
    } else {
        writeLines(jsonlite::toJSON(l, pretty = TRUE), file.path(dir, file))
    }
}

#' R versions
#'
#' Based on `rversions::r_versions()`.
#'
#' @return A data frame.
#' @noRd
# dput(rversions::r_versions()[,1:2])
rversions <- function() {
    # rversions::r_versions()[, 1:2]
    v <- jsonlite::fromJSON("https://api.r-hub.io/rversions/r-versions")
    d <- as.data.frame(v)[, c("version", "date")]
    d$date <- as.Date(substr(d$date, 1L, 10L))
    d
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
        switch(
            z[1L],
            "cran" = remotes::install_cran(z[2L], ...),
            "version" = remotes::install_version(
                z[2L],
                attr(z, "version"),
                ...
            ),
            "github" = remotes::install_github(z[2L], ...),
            "dev" = remotes::install_dev(z[2L], ...),
            "bioc" = remotes::install_bioc(z[2L], ...),
            "bitbucket" = remotes::install_bitbucket(z[2L], ...),
            "gitlab" = remotes::install_gitlab(z[2L], ...),
            "git" = remotes::install_git(z[2L], ...),
            "local" = remotes::install_local(z[2L], ...),
            "svn" = remotes::install_svn(z[2L], ...),
            "url" = remotes::install_url(z[2L], ...),
            stop(sprintf("unsupported installation sources: %s", z[1L]))
        )
    }
    lapply(x, f, ...)
    invisible(NULL)
}
