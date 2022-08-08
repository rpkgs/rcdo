library(rcdo)
library(CMIP6tools)
library(dplyr)

get_scenario <- function(file) {
  basename(file) %>% str_extract("[a-z,A-Z,0-9,-]*(?=_r\\d)")
}

indir = "/share/home/kong/github/rpkgs/rcdo/INPUT/ChinaHW_CMIP6_raw_bilinear/_LR/temp"
fs = dir(indir, "*.nc", full.names = TRUE)

info = CMIP5Files_info(fs) %>% 
  mutate(
    scenario = get_scenario(fs), 
    var = get_varname(fs)
  ) %>% select(Id, model, var, scenario, file) %>% 
  mutate(
    file_new = glue("INPUT/ChinaHW_CMIP6_raw_bilinear/{var}/{scenario}/{basename(file)}")
  )

file.rename(info$file, info$file_new)
