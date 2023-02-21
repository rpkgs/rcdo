#' @import zeallot
check_merged_file <- function(outfile, infiles = NULL) {
  dates = nctools::nc_date(outfile)

  # if (!is.null(infiles)) {
  #   dates_org <- nc_date_fs(fs)
  #   if (length(dates_org) < length(unique(dates))) {
  #     browser()
  #     stop()
  #   }
  # }

  status = TRUE # good file
  # 1. 文件过小删除
  if (length(dates) <= 100) status = FALSE
  
  # 2. 日期不连续删除
  info = data.table(year = year(dates))[, .N, .(year)] %>% arrange(year)
  is_year_continous = length(unique(diff(info$year))) == 1
  if (!is_year_continous) status = FALSE
  
  # 3. 和文件名日期不匹配的删除
  c(date_begin, date_end) %<-% str_extract_all(basename(outfile), "\\d{6,8}")[[1]]
  c(year_begin, year_end) %<-% str_year(c(date_begin, date_end))
  years_miss = setdiff(year_begin:year_end, info$year)
  
  if (length(years_miss) > 0) {
    message(sprintf("[w] %s: 文件日期缺失，重新处理...", outfile))
    print(years_miss)
    status <- FALSE
  }
  
  if (!status) {
    message(sprintf("[w] %s: 删除旧文件，重新处理...", basename(outfile)))
    file.remove(outfile)
  }
  status
}



nc_date_fs <- function(fs) {
  dates = foreach(f = fs, i = icount()) %do% {
    tryCatch(
      {
        nctools::nc_date(f)
      },
      error = function(e) {
        message(sprintf("[e] %s: %s", f, e$message))
      }
    )
  }
  dates %>% do.call(c, .) %>% unique()
}

check_nc_date <- function(f) {
  dates = nc_date(f)
  data.table(year = year(dates))[, .N, .(year)] %>% arrange(year) 
}
