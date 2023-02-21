#' cdo_combine
#'
#' clip, mergetime and resample in one function
#'
#' @note
#' ```bash
#' export SKIP_SAME_TIME=1
#' ```
#' @references
#' 1. merge files with overlapping time periods, 2017,
#'  https://code.mpimet.mpg.de/boards/1/topics/1134
#'
#' @export
cdo_combine <- function(files,
                        outfile = NULL, outdir = ".",
                        # varname = NULL,
                        range = c(70, 140, 15, 55), delta = 3,
                        # cdo = "cdo",
                        ncluster = 4,
                        is_resample = FALSE,
                        f_grid = "grid_d050.txt",
                        verbose = TRUE, run = FALSE, ...) {
  if (is.null(outfile)) outfile <- guess_CMIP_outfile(files, outdir)
  # extend `range` delta deg
  box <- range + c(-1, 1, -1, 1) * delta
  # select_var = ifelse(is.null(varname), "", glue("-select,name={varname}"))
  # {select_var}
  select_box <- glue('-apply,"-sellonlatbox,{box[1]},{box[2]},{box[3]},{box[4]}"')
  resample <- ifelse(is_resample, glue("-remapbil,{f_grid}"), "")
  infile <- glue("[ {paste(files, collapse = ' ')} ]")

  nP <- ifelse(ncluster > 1, glue("-P {ncluster}"), "") # parallel
  # cmd <- glue("{cdo} {nP} -mergetime {select_box} {infile} {outfile}")
  cmd <- glue("{cdo} {nP} {resample} -mergetime {select_box} {infile} {outfile}")

  if (verbose) print(cmd)
  if (run) system(cmd)
}
# TODO: cdo -sellonlatbox 可以分开处理，这样能方便处理bug

#' @rdname cdo_combine
#' @export
cdo_combine_large <- function(files, outfile = NULL, chunk = 100, ...) {
  nchunk <- ceiling(length(files) / chunk)
  if (is.null(outfile)) outfile <- guess_CMIP_outfile(files, outdir)
  if (nchunk > 1) {
    lst <- Ipaper::split_data(files, nchunk)
    files_out <- foreach(infile = lst, i = icount()) %do% {
      f_out <- glue("{outfile}_{i}")
      cdo_combine(infile, f_out, ...)
      f_out
    }
    cdo_merge(files_out, outfile)
  }
}
