# Create a Dependencies JSON File

Discover dependencies and write a `dependencies.json` file.

## Usage

``` r
create(
  dir = getwd(),
  file = "dependencies.json",
  output = dir,
  installed = c("base", "recommended"),
  overwrite = TRUE,
  ask = TRUE
)
```

## Arguments

- dir:

  Path to the directory where the files to be scanned are located.

- file:

  The name of the file to be save, default is `"dependencies.json"`.

- output:

  Path to the directory where JSON file should be written to.

- installed:

  The `priority` argument for
  [`installed.packages()`](https://rdrr.io/r/utils/installed.packages.html)
  for packages to be excluded.

- overwrite:

  Logical, should the `file` in the `output` directory be overwritten if
  exists?

- ask:

  Logical, asking confirmation before writing the `dependencies.json`
  file.

## Value

Invisibly returns the list of file names that were created. The side
effect is a JSON (and possibly a text for system requirements) file
written to the hard drive. The function fails when there are no R
related files in `dir`.

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
#>       "package": "MASS",
#>       "installed": true,
#>       "dev": false
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
unlink(file.path(out, "dependencies.json"))
```
