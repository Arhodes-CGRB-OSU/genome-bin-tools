% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/userAdd.R
\name{userAdd}
\alias{userAdd}
\title{Add custom user annotations to gbt object}
\usage{
userAdd(x, userTab, userSource)
}
\arguments{
\item{x}{Object of class gbt}

\item{userTab}{data.frame with user annotations, see Details}

\item{userSource}{Name for this annotation table}
}
\value{
Object of class gbt
}
\description{
Custom user annotations for each scaffold can be added to existing gbt
objects. The annotations should be in a data.frame, with at least column
"scaffold" that matches scaffold IDs in the gbt object. Pass the name of the
data.frame to the userTab parameter. Give a unique name for this annotation
to the userSource parameter.
}
\seealso{
\code{\link{gbt}} \code{\link{plot.gbt}}
}

