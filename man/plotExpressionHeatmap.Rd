% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metapredict_plot.R
\name{plotExpressionHeatmap}
\alias{plotExpressionHeatmap}
\title{Plot heatmap of merged gene expression data.}
\usage{
plotExpressionHeatmap(fitResult, lambda, ematMerged, sampleMetadata, annoLevels,
  annoColors = NA, clusterTogether = FALSE, geneIdOrder = NA,
  className = "class", classLevels = NA, org = "org.Hs.eg", maxVal = 3,
  ...)
}
\arguments{
\item{fitResult}{glmnet object.}

\item{lambda}{value of lambda to use in \code{fitResult}.}

\item{ematMerged}{matrix of gene expression for genes by samples.}

\item{sampleMetadata}{data.frame of sample metadata.}

\item{annoLevels}{Named list used to make the \code{annotation}
argument passed to \code{pheatmap::pheatmap}. Each name must correspond
to a column name in \code{sampleMetadata}, and each item in the
list must be a vector of values found in that particular column.}

\item{annoColors}{Passed to \code{annotation_colors} argument of
\code{pheatmap::pheatmap}.}

\item{clusterTogether}{logical indicating whether to cluster the samples
from each dataset together or separately.}

\item{geneIdOrder}{Optional character array of Entrez Gene IDs specifying the order
of genes. If \code{NA} (default), the order from \code{makeCoefDf} is used.}

\item{className}{column in sampleMetadata containing values of the response variable.}

\item{classLevels}{Order of classes for the column annotations.}

\item{org}{Name of package for mapping Entrez Gene IDs to gene symbols,
passed to \code{data} argument of \code{annotate::lookUp}.}

\item{maxVal}{Maximum absolute value of scaled and centered gene expression, used
to control dynamic range of color in the heatmap.}

\item{...}{Additional arguments passed to \code{pheatmap::pheatmap}.}
}
\value{
A pheatmap object.
}
\description{
\code{plotExpressionHeatmap} generates a heatmap of gene expression
from multiple datasets. This function calls \code{pheatmap::pheatmap}.
}
