# Install Dependencies

Install dependencies from an existing `dependencies.json` file or after
discovering the dependencies.

## Usage

``` r
install(
  dir = getwd(),
  file = "dependencies.json",
  upgrade = "never",
  cleanup = TRUE,
  timeout = 300L,
  ask = TRUE,
  ...
)
```

## Arguments

- dir:

  Path to the directory where the JSON file should be written to.

- file:

  The name of the file to be save, default is `"dependencies.json"`. If
  the file is not found in `dir`,
  [`create()`](https://hub.analythium.io/deps/reference/create.md) is
  called.

- upgrade:

  Should package dependencies be upgraded? Argument passed to remotes
  functions.

- cleanup:

  Logical, clean up files created by
  [`create()`](https://hub.analythium.io/deps/reference/create.md) when
  `file` does not exist.

- timeout:

  Integer, timeout for file downloads (default 60 seconds can be short).

- ask:

  Logical, asking confirmation before writing the `dependencies.json`
  file.

- ...:

  Other argument passed to remotes functions.

## Value

Returns `NULL` invisibly. The side effect is the dependencies installed.

## Examples

``` r
dir <- system.file("examples/01-basic", package = "deps")
out <- tempdir()
create(dir, output = out, ask = interactive())
cat(readLines(file.path(out, "dependencies.json")), sep = "\n")
#> {
#>   "version": "1.0",
#>   "rver": "4.5.2",
#>   "repos": ["https://psolymos.r-universe.dev", "https://r-spatial.r-universe.dev"],
#>   "sysreqs": ["curl", "git"],
#>   "packages": [
#>     {
#>       "package": "MASS",
#>       "installed": true,
#>       "dev": false
#>     },
#>     {
#>       "package": "devtools",
#>       "installed": false,
#>       "dev": true
#>     },
#>     {
#>       "package": "intrval",
#>       "installed": false,
#>       "dev": false,
#>       "repo": "https://psolymos.r-universe.dev",
#>       "source": "repo"
#>     },
#>     {
#>       "package": "mefa4",
#>       "installed": false,
#>       "dev": false,
#>       "ver": ">= 0.3-0",
#>       "source": "ver"
#>     },
#>     {
#>       "package": "rconfig",
#>       "installed": false,
#>       "dev": false,
#>       "remote": "analythium/rconfig@CRAN-v0.1.3",
#>       "source": "remote"
#>     }
#>   ]
#> }
if (FALSE) { # \dontrun{
install(out)
} # }
unlink(file.path(out, "dependencies.json"))
```
