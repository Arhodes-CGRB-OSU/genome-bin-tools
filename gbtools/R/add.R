#' Take union of two gbtbin objects
#'
#' Take union of two gbtbin objects. Equivalent to the R union function
#'
#' Self explanatory...
#' 
#' @param x1 Object of class gbtbin
#' @param x2 Object of class gbtbin
#'
#' @return Object of class gbtbin
#'
#' @seealso \code{\link{lej}}
#' @export
add <- function(x1, x2) UseMethod("add")
