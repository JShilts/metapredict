% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metapredict_plot.R
\name{plotClassProbsValidation}
\alias{plotClassProbsValidation}
\title{Plot class probabilities for samples from multiple validation datasets.}
\usage{
plotClassProbsValidation(predsList, sampleMetadata, className, classLevels,
  size = 1.5, ggplotArgs = NA)
}
\arguments{
\item{predsList}{Result from \code{metapredict}.}

\item{sampleMetadata}{data.frame of sample metadata.}

\item{className}{column in sampleMetadata containing values of the response variable.}

\item{classLevels}{Preferred order of classes.}

\item{size}{Point size, passed to \code{geom_point}.}

\item{ggplotArgs}{List of additional arguments to add to each ggplot.}
}
\value{
A gtable from \code{gridExtra::arrangeGrob}.
}
\description{
\code{plotClassProbsValidation} generates a gtable consisting of multiple
ggplots, one for each validation dataset. Within each class, samples are
sorted by the probability of the true class.
}
