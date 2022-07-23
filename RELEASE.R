# Compile README.md using latest version of package
devtools::build_readme()
# Rd
devtools::document()
# Check/update URLS
urlchecker::url_check()

# Check spelling
dict <- hunspell::dictionary('en_US')
devtools::spell_check()
spelling::update_wordlist()

# local checks
devtools::check()

# multi-arch checks
library(rhub)
#validate_email("peter@analythium.io")
platforms()
f <- c("debian-gcc-devel",
       "debian-gcc-release",
       "macos-highsierra-release-cran",
       "windows-x86_64-devel",
       "windows-x86_64-release",
       "windows-x86_64-oldrel")
check(platform=f)
list_package_checks(".")

# build package to submit
devtools::build()

pkgnews <- function() {
    x <- readLines("NEWS.md")
    x <- x[x != ""]
    h <- which(startsWith(x, "#"))
    i <- (h[1]+1):(h[2]-1)
    paste0(x[i], collapse="\n")
}
cat(sprintf('Dear CRAN Maintainers,

I am submitting the %s version of the deps R extension package to CRAN.

The package passed R CMD check --as-cran without errors/warnings/notes on the following platforms: %s.

I made the following changes since the last release:

%s

Yours,

Peter Solymos
maintainer', read.dcf("DESCRIPTION", fields="Version")[1],
            paste0(f, collapse=", "),
            pkgnews()))
