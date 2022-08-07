#' merge_modelFiles
#' @param d obj returned by [CMIP5Files_info()]
#' 
#' @import data.table
#' @export 
merge_modelFiles <- function(d, outdir = "ChinaHW_CMIP6_raw_bilinear") {
  mkdir(outdir)
  # d = lst[[1]]
  info = CMIP5Files_summary(d)

  fs_new = foreach(MODEL = info$model, i = icount()) %dopar% {
    runningId(i)
    
    di = d[model == info$model[i] & ensemble == info$ensemble[i]]
    if (unique_length(di$ensemble) != 1) {
      stop("multiple enemble axis")
    }
    .fs <- di[, file]
    outfile = guess_outfile_CMIP(.fs, outdir)
    if (file.exists(outfile)) return()

    tryCatch({
      cdo_combine(.fs, outfile, ncluster = 4, run = TRUE, f_grid = "data-raw/grid_d050.txt")
    }, error = function(e) {
      message(sprintf('[w] %s: %s', basename(outfile), e$message))
    })
  }
}
