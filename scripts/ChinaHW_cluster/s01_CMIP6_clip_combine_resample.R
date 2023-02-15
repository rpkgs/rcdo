## ----------------------------------------------------------------------------------------
library(CMIP6tools)
library(Ipaper)
library(dplyr)
library(nctools)
library(purrr)

devtools::load_all()


## ----------------------------------------------------------------------------------------
scenarios = c("hist-aer", "hist-GHG", "hist-nat", "historical", "ssp126", "ssp245", "ssp585", "piControl") %>% set_names(., .) #

indirs <- c(
  "U:/CMIP6_data/CMIP6_huss_day" %>% path.mnt(), 
  "T:/CMIP6_data/cmip6_tasmax_day" %>% path.mnt()
) %>% set_names(c("q", "tasmax"))


## ----------------------------------------------------------------------------------------
# 历史原因，之前错误的设置在了`mid=FALSE`
cdo_grid(c(70, 140, 15, 55), mid = FALSE, outfile= "data-raw/grid_d050.txt")

lst_fileInfo = foreach(indir =  indirs, i = icount(2)) %do% {
  lst = foreach(scenario = scenarios, i = icount()) %do% {
    idir = glue("{indir}/{scenario}")
    fs = dir(idir, "*.nc$", full.names = TRUE)
    CMIP5Files_info(fs)
  }
  # map(lst, merge_modelFiles)
}


## ----------------------------------------------------------------------------------------
# 重叠的部分有30个model，只处理同时含有hurs和tasmax的model
# 避免处理不需要使用的数据
varnames = names(lst_fileInfo)

BY = c("model", "ensemble")
l1 = lst_fileInfo[[1]]
l2 = lst_fileInfo[[2]]

info1 <- l1$historical %>% CMIP5Files_summary()
info2 <- l2$historical %>% CMIP5Files_summary()

# 重叠部分，有31个model
info_his = merge(info1, info2, by = BY) %>% select(model, ensemble)

## 筛选2者皆有的model
lst_fileInfo2 = foreach(d_rh = l1, d_tas = l2, icount()) %do% {
  # 二者同时都存在才行
  info_rh = CMIP5Files_summary(d_rh)
  info_tas = CMIP5Files_summary(d_tas)
  info = merge(info_rh, info_tas, by = BY) %>% select(model, ensemble)

  d_rh %<>% merge(info, by = BY)
  d_tas %<>% merge(info, by = BY)
  list(d_rh, d_tas) %>% set_names(varnames)
} %>% purrr::transpose()

# 对SSP也做同样的限制
for (i in 5:length(scenarios)) {
  for (k in 1:2) {
    lst_fileInfo2[[k]][[i]] %<>% merge(info_his, by = BY, all.x = FALSE)
  }
}
map_depth(lst_fileInfo2, 2, nrow) %>% str()


## ----------------------------------------------------------------------------------------
ok("raw:")
map_depth(lst_fileInfo, 2, nrow) %>% str()

ok("同时含有q和tasmax:")
map_depth(lst_fileInfo2, 2, nrow) %>% str()


## ----------------------------------------------------------------------------------------
lst_fileInfo2$q
lst_fileInfo2$tasmax$piControl

# InitCluster(4)
dir_root = "Z:/ChinaHW/CMIP6_mergedFiles/"
odirs = c("hurs", "tasmax") %>% paste0(dir_root, "ChinaHW_CMIP6_raw/", .)

# cdo_combine
.tmp = foreach(lst = lst_fileInfo2, outdir = odirs, icount()) %do% {
  foreach(d = lst, scenario = names(lst), icount()) %do% {
    odir = glue("{outdir}/{scenario}")
    CMIP_mergeModelFiles(d, odir, is_resample = FALSE)
  }
  # map(lst, merge_modelFiles, outdir = outdir)
}
