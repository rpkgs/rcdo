library(Ipaper)
library(lubridate)
library(stringr)
Ipaper::prepend_path("PATH", "/opt/miniconda3/bin") # add the path of cdo
# system("cdo")

idir <- "Z:/DATA/Global/GLDASV2.1" %>% path_mnt()
odir <- "Z:/DATA/Global/GLDASV2.1_daily" %>% path_mnt()
mkdir(odir)


files = dir(idir, "*.nc", full.names = TRUE)
years = str_extract(basename(files), "\\d{8}") %>% as_date() %>% year()

# 不考虑2022年
lst_files = split(files, years)[-23]

InitCluster(6)
tmp = foreach(fs = lst_files, year = 2000:2021, i = icount()) %dopar% {
  runningId(i)
  fout = glue("{odir}/GLDASV21_3hourly_{year}_Evap_tavg.nc")
  if (file.exists(fout)) return()
  
  cmd = glue("cdo -f nc4 -z zip_3 cat {idir}/*A{year}* {fout}")
  print(cmd)
  system(cmd)
  # cdo_merge(fs, fout, run = TRUE)
}


## then aggregate into daily
files = dir("/mnt/z/DATA/Global/GLDASV2.1_3hourly", "*.nc", full.names = TRUE)

tmp = foreach(fin = files, year = 2000:2021, i = icount()) %dopar% {
  runningId(i)
  fout = gsub("3hourly", "daily", fin)
  if (file.exists(fout)) return()
  
  cmd = glue("cdo -f nc4 -z zip_1 daymean {fin} {fout}")
  print(cmd)
  system(cmd)
  # cdo_merge(fs, fout, run = TRUE)
}


# setdiff(strsplit(basename(files[1]), "")[[1]], strsplit(basename(files[2]), "")[[1]])
# stringi::stri_compare(files[1], files[2])
# str_diff(files[1], files[2])

# a = files[1]
# b = files[2]
# s.a <- strsplit(a, "")[[1]]
# s.b <- strsplit(b, "")[[1]]
# paste(s.a[s.a != s.b], collapse = "")

