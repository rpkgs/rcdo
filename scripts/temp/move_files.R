# mv 
scenarios = c("hist-aer", "hist-GHG", "hist-nat", "historical", "ssp126", "ssp245", "ssp585") %>% set_names(., .) #

foreach(scenario = scenarios, i = icount()) %do% {
  indir = "ChinaHW_CMIP6_raw_bilinear/tasmax"
  # indir = "ChinaHW_CMIP6_raw_bilinear/hurs"
  outdir = glue("{indir}/{scenario}")
  # mkdir(outdir)
  fs = dir(indir, glue(".*{scenario}*.*nc"), full.names = TRUE)
  mv(fs, outdir)
  # file.rename()
}

indir <- "ChinaHW_CMIP6_raw_bilinear/tasmax"
indir = "ChinaHW_CMIP6_raw_bilinear/hurs"

#! /usr/bin/env -S Rscript --no-init-file
library(purrr)

args <- commandArgs(TRUE)
fs = dir(indir, recursive = TRUE)
dirs = list.dirs(indir, full.names = TRUE)[-1] %>% set_names(., basename(.))
lst_files = map(dirs, ~dir(., "*.nc", full.names = TRUE))
map(lst_files, length) %>% str()

library(Ipaper)
# "*_gr2_*"
# "*NorESM2-LM_*"

fs = dir("ChinaHW_CMIP6_raw_bilinear", "*MPI-ESM1-2-LR_*", recursive = TRUE, full.names = TRUE)
mv(fs, "ChinaHW_CMIP6_raw_bilinear/_LR")
# "hist-aer", "hist-GHG", "hist-nat", ssp245，没有进行控制

library(nctools)
f = "ChinaHW_CMIP6_raw_bilinear/tasmax/hist-aer/tasmax_day_ACCESS-ESM1-5_hist-aer_r1i1p1f1_gn_18500101-20201231.nc"
ncread(f, "lon")
ncread(f, "lat")
