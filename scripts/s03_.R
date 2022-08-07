library(Ipaper)
library(CMIP6tools)

# "IITM-ESM": 新增一个印度模型

fs = dir("INPUT/TRS", full.names = TRUE)
models1 = get_model(fs, "_movTRS_", "\\.")

fs = dir("INPUT/ChinaHW_CMIP6_raw_bilinear/HItasmax/historical", full.names = TRUE)
models2 = get_model(fs, "day_", "_hist|_ssp")

info = match2(models1, models2)
models2[-info$I_y]
