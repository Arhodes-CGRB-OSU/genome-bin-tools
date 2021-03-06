% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/choosebin.gbt.R
\name{choosebin.gbt}
\alias{choosebin.gbt}
\title{Choose bin interactively from plot of gbt object}
\usage{
\method{choosebin}{gbt}(x, slice, taxon = "Class", num.points = 6,
  draw.polygon = TRUE, save = FALSE, file = "interactive_bin.list")
}
\arguments{
\item{x}{Object of class gbt, used to generate the plot}

\item{slice}{The same slice parameter used to generate the plot}

\item{num.points}{Number of points in polygon (integer)}

\item{draw.polygon}{Draw polygon as overlay on plot (logical)}
}
\value{
Object of class gbtbin
}
\description{
Choose genome bin from GC-coverage or differential coverage plot of a
gbt object
}
\seealso{
\code{\link{plot.gbt}}
}

