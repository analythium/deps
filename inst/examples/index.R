# deps examples

i <- "01-basic"

message("Running example ", i)

message("  - Setting up temporary location")
o <- getwd()
dir <- "_tmp"
unlink(dir, recursive = TRUE)
dir.create(dir)

message("  - Copying files")
file.copy(
    file.path(o, "inst", "examples", i),
    file.path(o, dir), 
    recursive = TRUE)
setwd(file.path(o, dir, i))

message("  - Setting lib path")
l <- file.path(o, dir, i, "lib")
dir.create(l)
.libPaths(l)
write(paste0(".libPaths(\"", l, "\")"), ".Rprofile", append = TRUE)

message("  - Install deps")
deps::create(sysreqs = TRUE)
deps::install(upgrade=TRUE)

shiny::runApp()

message("  - Clean up")
setwd(o)
unlink(dir, recursive = TRUE)

q("no")
