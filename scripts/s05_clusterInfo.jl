# julia --sysimage /share/opt/julia/libIpaper.so --project scripts/s05_clusterInfo.jl

## 计算统计指标 -----------------------------------------------------------------
include("main_pkgs.jl")
using DataFrames:DataFrame
using Revise
using Pkg
Pkg.activate("~/github/jl-spatial/SpatioTemporalCluster.jl")

f_grid = "/share/home/kong/github/jl-spatial/SpatioTemporalCluster.jl/data/China_GCM_050deg_FractionArea_V1.csv"
@time d_coord = fread(f_grid) |> tidy_coord

f_id = "/share/home/kong/github/rpkgs/rcdo/INPUT/clusterId/hist-GHG/clusterId_HItasmax_day_FGOALS-g3_hist-GHG_r1i1p1f1_gn_18500101-20201231.nc"

isfile(f_id)
cal_clusterInfo(f_id; d_coord=d_coord)

methods(cal_clusterInfo)
