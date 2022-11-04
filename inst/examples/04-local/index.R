#' @local ./add
library(add)
message("package loaded")

x <- add(2, 2)
print(x)

stopifnot(x == 4)
message("addition done")
