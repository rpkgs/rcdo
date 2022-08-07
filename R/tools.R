mv <- function(files, outdir) {
  mkdir(outdir)
  fs2 <- paste0(outdir, "/", basename(files))
  file.rename(files, fs2)
}
