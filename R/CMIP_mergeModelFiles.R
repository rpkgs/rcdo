#' merge_modelFiles
#' 
#' @param d obj returned by [CMIP5Files_info]
#' @param ... other parameters to [cdo_combine]
#' 
#' @import data.table
#' @export 
CMIP_mergeModelFiles <- function(d, outdir = "ChinaHW_CMIP6_raw_bilinear", ...) {
  mkdir(outdir)
  info = CMIP5Files_summary(d)

  # models_bad = c("MPI-ESM1-2-LR", "NorESM2-LM")
  fs_new = foreach(MODEL = info$model, i = icount()) %dopar% {
    # runningId(i)
    di = d[model == info$model[i] & ensemble == info$ensemble[i]]
    if (unique_length(di$ensemble) != 1) {
      stop("multiple enemble axis")
    }
    fs <- di[, file]
    outfile = guess_outfile_CMIP(fs, outdir)
    
    if (file.exists(outfile)) {
      is_good_file <- check_merged_file(outfile, fs)
      if (is_good_file) return()
    }

    ind_valid = file.exists(fs)
    
    if (!all(ind_valid)) {
      message(sprintf("[missing] %s:", basename(outfile)))
      print(fs[!ind_valid])
      return()
    }
    
    # TODO: 增加功能，如果文件不全，要报错
    tryCatch({
      fprintf("[%02d] running: %s\n", i, basename(outfile))
      cdo_combine(fs, outfile, ncluster = 8, run = TRUE, 
        ..., f_grid = "data-raw/grid_d050.txt")
    }, error = function(e) {
      message(sprintf('[w] %s: %s', basename(outfile), e$message))
    })
  }
}

merge_modelFiles <- CMIP_mergeModelFiles
