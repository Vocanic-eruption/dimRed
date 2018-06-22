#' Umap embedding
#'
#' An S4 Class implementing the UMAP algorithm
#'
#' Uniform Manifold Approximation is a gradient descend based algorithm that
#' gives results similar to t-SNE, but scales better with the number of points.
#'
#' @template dimRedMethodSlots
#'
#' @template dimRedMethodGeneralUsage
#'
#' @section Parameters:
#'
#' UMAP can take the follwing parameters:
#' \describe{
#'   \item{}{}
#'   \item{}{}
#' }
#'
#' @section Implementation:
#'
#' The dimRed package wraps the \code{\link[umap]{umap}} packages which provides
#' an implementation in pure R and also a wrapper around the original python
#' package \code{umap-learn} (https://github.com/lmcinnes/umap/)
#'
#' @references
#'
#' McInnes, Leland, and John Healy.
#' "UMAP: Uniform Manifold Approximation and Projection for Dimension Reduction."
#' https://arxiv.org/abs/1802.03426
#'
#' @examples
#' dat <- loadDataSet("3D S Curve", n = 500)
#'
#' ## use the S4 Class directly:
#' umap <- Isomap()
#' emb <- umap@fun(dat, umap@stdpars)
#'
#' ## or simpler, use embed():
#' samp <- sample(nrow(dat), size = 200)
#' emb2 <- embed(dat[samp], "UMAP", mute = NULL, knn = 10)
#' emb3 <- emb2@apply(dat[-samp])
#'
#' plot(emb2, type = "2vars")
#' plot(emb3, type = "2vars")
#'
#' @include dimRedResult-class.R
#' @include dimRedMethod-class.R
#' @family dimensionality reduction methods
#' @export UMAP
#' @exportClass UMAP
UMAP <- setClass(
  "UMAP",
  contains = "dimRedMethod",
  prototype = list(
    stdpars = list(
      knn = 15,
      ndim = 2,
      d = "euclidean",
      method = "naive"
    ),
    fun = function (data, pars,
                    keep.org.data = TRUE) {
      chckpkg("umap")
      if (pars$method == "python") {
        chckpkg("reticulate")
        if (!reticulate::py_module_available("umap"))
          stop("cannot find python umap, install with `pip install umap-learn`")
      }

      meta <- data@meta
      orgdata <- if (keep.org.data) data@data else NULL
      indata <- data@data

      ## Create config
      umap_pars <- umap::umap.defaults
      umap_pars$n.neighbors  <- pars$knn
      umap_pars$n.components <- pars$ndim
      umap_pars$metric.function <- pars$d
      umap_pars$method <- pars$method
      umap_pars$d <- indata

      pars_2 <- pars
      pars_2$knn <- NULL
      pars_2$ndim <- NULL
      pars_2$d <- NULL
      pars_2$method <- NULL
      pars_2$mute <- NULL

      for (n in names(pars_2))
        umap_pars[[n]] <- pars_2[[n]]

      ## Do the embedding
      outdata <- do.call(umap::umap, umap_pars)

      ## Post processing
      colnames(outdata$layout) <- paste0("UMAP", 1:ncol(outdata$layout))

      return(new(
        "dimRedResult",
        data = new("dimRedData",
                   data = outdata$layout,
                   meta = meta),
        org.data = orgdata,
        has.org.data = keep.org.data,
        method = "UMAP",
        pars = pars
      ))
    }
  )
)