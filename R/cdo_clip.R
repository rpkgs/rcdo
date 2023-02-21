# TODO: cdo -sellonlatbox 可以分开处理，这样能方便处理bug

cdo_clip <- function(
    fs, outdir = "cdo_temp",
    range = c(70, 140, 15, 55), delta = 3, ncluster = 4, 
    verbose = TRUE, run = FALSE) {
  
  box <- range + c(-1, 1, -1, 1) * delta
  select_box <- glue('-sellonlatbox,{box[1]},{box[2]},{box[3]},{box[4]}"')
  nP <- ifelse(ncluster > 1, glue("-P {ncluster}"), "") # parallel
  
  outfiles <- foreach(infile = fs, i = icount()) %do% {
    outfile <- sprintf("%s/%s", outdir, basename(f))
    cmd <- glue("{cdo} {nP} {resample} -mergetime {select_box} {infile} {outfile}")

    if (!file.exists(file)) {
      if (verbose) print(cmd)

      tryCatch(
        {
          if (run) system(cmd)
        },
        error = function(e) {
          message(sprintf("[e] %s: %s", infile, e$message))
        }
      )
    }
    outfile
  }
  outfiles
}

cdo_combine2 <- function(
    files, outfile = NULL, outdir = ".",
    range = c(70, 140, 15, 55), delta = 3,
    ncluster = 4,
    is_resample = FALSE, f_grid = "grid_d050.txt",
    verbose = TRUE, run = FALSE, ...) {
      
  fs <- cdo_clip(files, range = range, delta = delta, ncluster = ncluster, verbose = verbose, run = run)
  cdo_merge(fs, outfile)
}
