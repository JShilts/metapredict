#' Make arguments for glmnet.
#'
#' \code{makeGlmnetArgs} makes vectors for foldid and weights to be
#' 	used for leave-one-study-out cross-validation with glmnet.
#'
#' @param metadata data.frame containing a row for each observation.
#' @param foldidColname column to use for grouping observations.
#'
#' @return A named list.
#' \item{foldid}{vector of integers}
#' \item{weights}{vector of weights, such that each study is weighted equally.}
#'
#' @export
makeGlmnetArgs = function(metadata, foldidColname='study') {
	foldid = as.numeric(factor(metadata[,foldidColname], labels=1:length(unique(metadata[,foldidColname]))))
	names(foldid) = rownames(metadata)
	weights = length(unique(foldid)) /
		do.call(c, sapply(sapply(unique(foldid), function(x) sum(foldid==x)), function(n) rep_len(n, n), simplify=FALSE))
	names(weights) = rownames(metadata)
	return(list(foldid=foldid, weights=weights))}


#' Perform cross-validation of merged gene expression data.
#'
#' \code{metapredictCv} runs cross-validation to predict a
#' 	response variable from gene expression data across multiple
#' 	studies. This function is a wrapper around cv.glmnet.
#'
#' @param ematMerged matrix of gene expression for genes by samples.
#' @param sampleMetadata data.frame of sample metadata.
#' @param weights vector of weights.
#' @param alpha vector of values for alpha, the elastic net mixing parameter.
#' @param nFolds number of folds. Ignored, if foldid is not NA.
#' @param foldid vector of values specifying what fold each observation is in.
#' @param nRepeats number of times to perform cross-validation. Ignored, if foldid is not NA.
#' @param yName column in sampleMetadata containing values of the response variable.
#' @param addlFeatureColnames optional vector of column names containing other features
#' 	to be used for predicting the response variable.
#' @param ... Other arguments passed to cv.glmnet.
#'
#' @return A list of cv.glmnet objects.
#'
#' @export
metapredictCv = function(ematMerged, sampleMetadata, weights, alpha, nFolds=10, foldid=NA, nRepeats=3, yName='class',
								 addlFeatureColnames=NA, ...) {
	args = list(...)
	if (!is.null(args[['family']]) & args[['family']]=='cox') {
		y = as.matrix(sampleMetadata[colnames(ematMerged), yName])
		colnames(y) = c('time', 'status')
	} else {
		y = sampleMetadata[colnames(ematMerged), yName]}

	if (is.na(addlFeatureColnames[1])) {
		x = scale(t(ematMerged), center=TRUE, scale=FALSE)
	} else {
		addlFeatureTmp = data.frame(lapply(sampleMetadata[colnames(ematMerged), addlFeatureColnames], factor))
		addlFeatureDummy = model.matrix(~ 0 + ., data=addlFeatureTmp)
		x = cbind(scale(t(ematMerged), center=TRUE, scale=FALSE), addlFeatureDummy)}

	if (is.na(foldid[1])) {
		cvFitList = list()
		for (ii in 1:nRepeats) {
			foldid = sample(rep(seq(nFolds), length=ncol(ematMerged)))
			cvFitList[[ii]] = foreach(alpha=alpha) %do% {
				glmnet::cv.glmnet(x, y, weights=weights[colnames(ematMerged)], foldid=foldid, alpha=alpha, standardize=FALSE, ...)}}
	} else {
		cvFitList = foreach(alpha=alpha) %do% {
			glmnet::cv.glmnet(x, y, weights=weights[colnames(ematMerged)], foldid=foldid[colnames(ematMerged)], alpha=alpha,
									standardize=FALSE, ...)}}
	return(cvFitList)}


#' Predict the response variable in validation datasets.
#'
#' \code{metapredict} independently merges the discovery datasets
#' 	with each validation dataset, trains a glmnet model on the samples
#' 	from the discovery datasets, then predicts the response variable
#' 	for the samples in the respective validation dataset. This function
#' 	is a wrapper around glmnet.
#'
#' @param ematList .
#' @param studyMetadata data.frame of study metadata.
#' @param sampleMetadata data.frame of sample metadata.
#' @param discoveryStudyNames vector of study names for training.
#' @param alpha value of alpha for the elastic net mixing parameter.
#' @param lambda value of regularization parameter.
#' @param weights vector of weights for training the glmnet model.
#' @param batchColname column in sampleMetadata containing
#' 	batch information for ComBat.
#' @param covariateName column in sampleMetadata containing
#' 	additional covariates for ComBat besides batch.
#' @param className column in sampleMetadata containing values of the response variable.
#' @param type type of prediction to make (passed to \code{predict.glmnet}).
#' @param ... Other arguments passed to \code{glmnet}.
#'
#' @return A named list of objects from \code{predict.glmnet}.
#'
#' @export
metapredict = function(ematList, studyMetadata, sampleMetadata, discoveryStudyNames, alpha, lambda, weights,
							  batchColname='study', covariateName=NA, className='class', type='response', ...) {

	discoverySampleNames = sampleMetadata[sampleMetadata[,'study'] %in% discoveryStudyNames, 'sample']
	validationStudyNames = setdiff(sort(unique(sampleMetadata[,'study'])), discoveryStudyNames)

	predsList = foreach(validationStudyName=validationStudyNames) %do% {
		validationSampleNames = sampleMetadata[sampleMetadata[,'study']==validationStudyName, 'sample']

		ematListNow = ematList[c(discoveryStudyNames, validationStudyName)]
		ematMergedDiscVal = mergeStudyData(ematListNow, sampleMetadata, batchColname=batchColname, covariateName=covariateName)
		ematMergedDisc = ematMergedDiscVal[,discoverySampleNames]

		fitResult = glmnet::glmnet(t(ematMergedDisc), sampleMetadata[discoverySampleNames, className], alpha=alpha,
											lambda=lambda, weights=weights[discoverySampleNames], standardize=FALSE, ...)
		preds = predict(fitResult, newx=t(ematMergedDiscVal[,validationSampleNames]), s=lambda, type=type)}

	names(predsList) = validationStudyNames
	return(predsList)}


#' Make data.frame of non-zero coefficients from a glmnet model.
#'
#' \code{makeCoefDf} makes a sorted data.frame of the non-zero
#' 	coefficients of a logistic or multinomial glmnet model.
#'
#' @param fitResult glmnet object.
#' @param lambda value of lambda for which to obtain coefficients.
#' @param decreasing logical passed to \code{order}.
#' @param classLevels order of columns in resulting data.frame.
#'
#' @return A data.frame.
#'
#' @export
makeCoefDf = function(fitResult, lambda, decreasing=TRUE, classLevels=NA) {
	coefResult = coef(fitResult, s=lambda)

	if (is.list(coefResult)) {
		coefResultNonzero = foreach(coefSparse=coefResult) %do% {
			x = data.frame(rownames(coefSparse)[(coefSparse@i)+1], coefSparse[(coefSparse@i)+1], stringsAsFactors=FALSE)
			colnames(x) = c('geneId', 'coefficient')
			return(x)}
		names(coefResultNonzero) = names(coefResult)
		if (!is.na(classLevels[1])) {
			coefResult = coefResult[classLevels]
			coefResultNonzero = coefResultNonzero[classLevels]}

		for (ii in 1:length(coefResult)) {
			colnames(coefResultNonzero[[ii]])[2] = names(coefResult)[ii]}
		coefDf = Reduce(function(x, y) merge(x, y, by='geneId', all=TRUE), coefResultNonzero)
		idx = do.call(order, c(coefDf[,2:ncol(coefDf)], list(decreasing=decreasing)))
		coefDf = coefDf[idx,]
		coefDf[is.na(coefDf)] = 0

	} else {
		coefDf = data.frame(names(coefResult[(coefResult@i)+1,]), coefResult[(coefResult@i)+1,], stringsAsFactors=FALSE)
		colnames(coefDf) = c('geneId', 'coefficient')
		coefDf = coefDf[order(coefDf[,'coefficient'], decreasing=decreasing),]}
	rownames(coefDf) = NULL
	return(coefDf)}