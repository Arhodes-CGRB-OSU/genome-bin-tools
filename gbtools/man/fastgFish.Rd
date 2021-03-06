% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/fastgFish.R
\name{fastgFish}
\alias{fastgFish}
\title{Perform connectivity fishing with Fastg and paths files from SPAdes 3.6.2+}
\usage{
fastgFish(x, bin, fastg.file, paths.file, fasta.file, depth, save, file,
  script.path)
}
\arguments{
\item{x}{Object of class gbt (parent object of the gbtbin object)}

\item{bin}{Object of class gbtbin, derived from x above}

\item{fastg.file}{Fastg formatted assembly graph from SPAdes (assembly_graph.fastg)}

\item{paths.file}{Paths file mapping assembly graph edge names to scaffold/contig names (scaffolds.paths or contigs.paths)}

\item{fasta.file}{Fasta file containing scaffolds/contigs of this assembly (scaffolds.fasta or contigs.fasta)}

\item{save}{Logical: Save list of fished contigs to external file? (Default: No)}

\item{file}{File name to save list of fished contigs, if save=TRUE}
}
\value{
Object of class gbtbin
}
\description{
Find contigs connected to a given gbtbin and report a new gbtbin object
Requires Fastg and paths files produced by SPAdes 3.6.2+; older versions of
SPAdes produces different format.
}

