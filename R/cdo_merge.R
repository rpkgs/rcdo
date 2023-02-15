# library(Ipaper)
# library(stringr)

Sys.setenv(SKIP_SAME_TIME=1)
# Sys.getenv("SKIP_SAME_TIME")

# # https://stackoverflow.com/questions/25731393/is-there-a-way-to-crop-a-netcdf-file
# Ipaper::prepend_path("PATH", "/opt/miniconda3/bin") # add the path of cdo
cdo = "/opt/miniconda3/bin/cdo -f nc4 -z zip_1"

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

#' get regular cdo grid
#' 
#' @param range `[lon_min, lon_max, lat_min, lat_max]`
#' @param cellsize double
#' @param outfile character, path of output file
#' @param mid If `TRUE`, the first coordinate is on the middle; otherwise, 
#' on the edge. 
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
