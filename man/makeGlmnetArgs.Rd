% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metapredict_predict.R
\name{makeGlmnetArgs}
\alias{makeGlmnetArgs}
\title{Make arguments for glmnet.}
\usage{
makeGlmnetArgs(metadata, foldidColname = "study", sampleColname = "sample")
}
\arguments{
\item{metadata}{data.frame containing a row for each observation.}

\item{foldidColname}{column to use for grouping observations.}

\item{sampleColname}{column that contains sample names.}
}
\value{
A named list.
\item{foldid}{vector of integers}
\item{weights}{vector of weights, such that each study is weighted equally.}
}
\description{
\code{makeGlmnetArgs} makes vectors for foldid and weights to be
	used for leave-one-study-out cross-validation with glmnet.
}
