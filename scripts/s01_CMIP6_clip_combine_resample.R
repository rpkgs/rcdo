library(CMIP6tools)
library(Ipaper)
library(dplyr)
library(nctools)
library(purrr)

devtools::load_all()

# , "piControl"
scenarios = c("hist-aer", "hist-GHG", "hist-nat", "historical", "ssp126", "ssp245", "ssp585") %>% set_names(., .) #
indirs <- c(
  "/share/Data/CMIP6/cmip6_hurs_day", 
  "/share/Data/CMIP6/cmip6_tasmax_day"
) %>% set_names(c("rh", "tas"))

# 历史原因，之前错误的设置在了`mid=FALSE`
cdo_grid(c(70, 140, 15, 55), mid = FALSE, outfile= "data-raw/grid_d050.txt")

lst_fileInfo = foreach(indir =  indirs, i = icount(2)) %do% {
  lst = foreach(scenario = scenarios, i = icount()) %do% {
    idir = glue("{indir}/{scenario}")
    fs = dir(idir, "*.nc", full.names = TRUE)
    CMIP5Files_info(fs)
  }
  # map(lst, merge_modelFiles)
}

# 重叠的部分有30个model，只处理同时含有hurs和tasmax的model
# 避免处理不需要使用的数据
{
  BY = c("model", "ensemble")
  info1 <- lst_fileInfo[[1]]$historical %>% CMIP5Files_summary()
  info2 <- lst_fileInfo[[2]]$historical %>% CMIP5Files_summary()
  info_his = merge(info1, info2, by = BY) %>% select(model, ensemble)

  ## 筛选2者皆有的model
  lst_fileInfo2 = foreach(d_rh = lst_fileInfo[[1]], d_tas = lst_fileInfo[[2]], icount()) %do% {
    # 二者同时都存在才行
    info_rh = CMIP5Files_summary(d_rh)
    info_tas = CMIP5Files_summary(d_tas)
    info = merge(info_rh, info_tas, by = BY) %>% select(model, ensemble)

    d_rh %<>% merge(info, by = BY)
    d_tas %<>% merge(info, by = BY)
    list(rh = d_rh, tas = d_tas)
    # foreach(d_rh = l_rh, d_tas = l_tas, icount()) %do% {
  } %>% purrr::transpose()
  ok("raw:")
  map_depth(lst_fileInfo, 2, nrow) %>% str()

  ok("同时含有rh和tas:")
  map_depth(lst_fileInfo2, 2, nrow) %>% str()
  
  for (i in 5:length(scenarios)) {
    for (k in 1:2) {
      lst_fileInfo2[[k]][[i]] %<>% merge(info_his, by = BY, all.x = FALSE)
    }
  }
  map_depth(lst_fileInfo2, 2, nrow) %>% str()
}

lst_fileInfo2$rh
lst_fileInfo2$tas$piControl

InitCluster(4)

outdirs = c("hurs", "tasmax") %>% paste0("INPUT/ChinaHW_CMIP6_raw_bilinear/", .)

.tmp = foreach(lst = lst_fileInfo2, outdir = outdirs, icount()) %do% {
  foreach(d = lst, scenario = names(lst), icount()) %do% {
    odir = glue("{outdir}/{scenario}")
    merge_modelFiles(d, odir)
  }
  # map(lst, merge_modelFiles, outdir = outdir)
}
d = lst_fileInfo2$tas$`hist-GHG`


fs = d[model == "ACCESS-ESM1-5", file]
# nc_date(fs[4])
outfile = "tasmax_day_ACCESS-ESM1-5_hist-GHG_r1i1p1f1_gn_18500101-20201231.nc"
cdo_combine(fs, outfile, ncluster = 8, run = TRUE, f_grid = "data-raw/grid_d050.txt")
# map(, nrow)
# lst[[5]]

# 从9:48开始, 13:41结束，处理了约四个小时

# map(lst, CMIP5Files_summary)
# 大概半小时可以搞定

# library(nctools)

# file.remove(.fs[2:5])

# # 2-5文件下载不全
# .tmp = foreach(f = .fs, i = icount()) %do% {
#   runningId(i)
#   nc_date(f)
# }
# # NAE
# # _GFDL-CM4_hist-nat_r1i1p1f1
# library(data.table)
# d = fread("/share/Data/CMIP6/cmip6_hurs_day-url/hurs_hist-nat.txt", header = F)[[1]]

# CMIP5Files_info(d) %>% CMIP5Files_summary()

# map(lst[3], merge_modelFiles)

# system("which cdo")

# # fs_new
# # unlist(fs_new)
# # export SKIP_SAME_TIME=1
