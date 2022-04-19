# library(Ipaper)
# library(stringr)

# # https://stackoverflow.com/questions/25731393/is-there-a-way-to-crop-a-netcdf-file
# Ipaper::prepend_path("PATH", "/opt/miniconda3/bin") # add the path of cdo
cdo = "cdo -f nc4 -z zip_1"

#' @export
guess_outfile_CMIP <- function(files, outdir = ".") {
  date_begin <- basename(files) %>% str_extract("\\d{6,8}(?=\\-)") %>% min()
  date_end <- basename(files) %>% str_extract("(?<=\\-)\\d{6,8}") %>% max()
  prefix <- basename(files[1]) %>% str_extract(".*(?=_\\d{6,8})")
  outfile <- glue("{outdir}/{prefix}_{date_begin}-{date_end}.nc")
  outfile
}

#' @export
cdo_merge <- function(files, outfile = NULL, outdir = ".", overwrite = FALSE) {
  if (is.null(outfile)) outfile <- guess_outfile_CMIP(files, outdir)
  if (!file.exists(outfile) || overwrite) {
    files %<>% paste(collapse = " ")
    cmd <- glue::glue("{cdo} cat {files} {outfile}")
    print(cmd)
    system(cmd)
  }
}

#' cdo_combine
#' 
#' @export
cdo_combine <- function(files,
                        outfile = NULL, outdir = ".",
                        # varname = NULL,
                        range = c(70, 140, 15, 55), delta = 3,
                        cdo = "cdo", ncluster = 4,
                        verbose = TRUE, run = FALSE, ...) {
  if (is.null(outfile)) outfile <- guess_CMIP_outfile(files, outdir)
  # extend `range` delta deg
  box <- range + c(-1, 1, -1, 1) * delta
  # select_var = ifelse(is.null(varname), "", glue("-select,name={varname}"))
  # {select_var}
  select_box <- glue('-apply,"-sellonlatbox,{box[1]},{box[2]},{box[3]},{box[4]}"')
  infile <- glue("[ {paste(files, collapse = ' ')} ]")

  nP <- ifelse(ncluster > 1, glue("-P {ncluster}"), "") # parallel
  cmd <- glue("{cdo} {nP} -cat {select_box} {infile} {outfile}")

  if (verbose) print(cmd)
  if (run) system(cmd)
}

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

#' get regular cdo grid
#' 
#' @param range `[lon_min, lon_max, lat_min, lat_max]`
#' @param cellsize double
#' @param outfile character, path of output file
#' @param mid If `TRUE`, the first coordinate is on the middle; otherwise, on the 
#' edge. 
#' 
#' @export 
cdo_grid <- function(range = c(70, 140, 15, 55), cellsize = 0.5, mid = FALSE, 
  outfile = NULL) 
{
  if (is.null(outfile)) outfile = sprintf("grid_d%03d.txt", cellsize*100)
  nlon = diff(range[1:2])/cellsize
  nlat = diff(range[3:4])/cellsize

  hcell = cellsize/2 * mid
  grid = glue("
    gridtype = lonlat
    xsize = {nlon}
    ysize = {nlat}
    xfirst = {range[1] + hcell}
    xinc = {cellsize}
    yfirst = {range[3] + hcell}
    yinc = {cellsize}
    ")
  writeLines(grid, outfile)
}
