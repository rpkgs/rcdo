% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aria2c.R
\name{wget}
\alias{wget}
\title{wget}
\usage{
wget(url, outfile = NULL)
}
\arguments{
\item{url}{character}

\item{outfile}{character}
}
\description{
wget
}
\examples{
url = "http://esgf-data.dkrz.de/esg-search/wget/?mip_era=CMIP6&experiment_id=ssp370&frequency=day&variable=tas&realm=atmos&member_id=r1i1p1f1&limit=10000"
wget(url, "test.txt")
}
