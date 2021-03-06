% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/winnowMark.R
\name{winnowMark}
\alias{winnowMark}
\title{Subset a gbt or gbtbin object by marker gene taxonomy}
\usage{
winnowMark(x, marksource, param, value, save, file)
}
\arguments{
\item{x}{Object of class gbt or gbtbin}

\item{param}{Taxonomic level to make subset (default "Class")}

\item{value}{Value of the taxon to make subset (default
"Gammaproteobacteria")}

\item{save}{Save list of contigs to external file? (logical, defautl FALSE)}

\item{file}{File name for export of contig list.}
}
\value{
Object of class gbtbin
}
\description{
Subset a gbt or gbtbin object by marker gene taxonomy
}
\seealso{
\code{\link{winnow}}, \code{\link{gbt}}
}

