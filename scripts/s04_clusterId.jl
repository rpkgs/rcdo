# module load mpi/impi/2020.1
# mpiexec -n 6 julia --sysimage /share/opt/julia/libIpaper.so --project scripts/s04_clusterId.jl
include("main_pkgs.jl")
using DataFrames:DataFrame

f_grid = "/share/home/kong/github/jl-spatial/SpatioTemporalCluster.jl/data/China_GCM_050deg_FractionArea_V1.csv"
@time d_coord = fread(f_grid) |> tidy_coord

## begin of parallel setting ---------------------------------------------------
chunk = 1
mpi_id = 1

using MPI
MPI.Init()
comm = MPI.COMM_WORLD
mpi_id = MPI.Comm_rank(comm)#+ 1
chunk = MPI.Comm_size(comm)
# println("Hello world, I am $(mpi_id) of $(chunk)")
## end of parallel setting -----------------------------------------------------


function MultiModel_clusterId(info)
  for i = 1:nrow(info)
    if chunk > 1 && mod(i, chunk) != mpi_id; continue; end
    
    f_trs = info[i, :file_1] |> jldFile
    f_hi = info[i, :file]
    scenario = info[i, :scenario]
    outdir = "INPUT/clusterId/$scenario"
    
    subfix = str_replace(basename(f_hi), ".nc", "")
    f_id = "$outdir/clusterId_$subfix.nc"
    
    @show basename(f_hi)
    try
      @time res = cal_clusterId(f_hi, f_trs; ncell_connect=4, d_coord=d_coord, outdir=outdir);  
    catch e
      println(e)
      printstyled("[e] outfile = $(basename(f_hi))\n", color=:red, underline=true, bold=true)
      # rm(f_id)
    end
  end
end

## 匹配阈值, model + ensemble
info_trs = dir("INPUT/TRS/", ".jld2") |> getFileInfo
scenarios = ["hist-aer", "hist-GHG", "hist-nat", "ssp245", "historical", "ssp126", "ssp585"]#[1:1]

for i = 5:7 #length(scenarios)
  scenario = scenarios[i]
  indir = "INPUT/ChinaHW_CMIP6_raw_bilinear/HItasmax/$scenario"
  fs = dir(indir, ".nc")
  # 如此就没有重复的model了
  info_hi = @pipe getFileInfo(fs) |> _[_.ensemble .!= "r1i1p1f1_gr2", :]

  grp = table(info_hi.model)
  models_bad = filter(x -> x[2] == 2, grp) |> keys |> collect

  if length(models_bad) > 0
    ind_bad = info_hi.model .∈ (models_bad,)
    println(info_hi[ind_bad, 1:4])
    error("[e] i = $i\n")
  end

  vars = [:model, :file]
  info = dt_merge(info_hi[:, [:model, :scenario, :file]], info_trs[:, vars], by = "model")
  
  # println(info)
  MultiModel_clusterId(info)
end

MPI.Barrier(comm)

## 检查中途中断的model
function MultiModel_unfinished(info; del=false)
  for i = 1:nrow(info)
    # if chunk > 1 && mod(i, chunk) != mpi_id; continue; end
    f_trs = info[i, :file_1] |> jldFile
    f_hi = info[i, :file]
    scenario = info[i, :scenario]
    outdir = "INPUT/clusterId/$scenario"
    
  
    subfix = str_replace(basename(f_hi), ".nc", "")
    f_id = "$outdir/clusterId_$subfix.nc"
    f_path = "$outdir/char_path_$subfix.csv"
    # @show basename(f_hi)
    if !isfile(f_path)    
      printstyled("[e] outfile = $(basename(f_hi))\n", color=:red, underline=true, bold=true)
      try
        del && rm(f_id)  
      catch e
        println(e)
      end
    end
  end
end

for i = 1:0 #length(scenarios)
  scenario = scenarios[i]
  indir = "INPUT/ChinaHW_CMIP6_raw_bilinear/HItasmax/$scenario"
  fs = dir(indir, ".nc")
  # 如此就没有重复的model了
  info_hi = @pipe getFileInfo(fs) |> _[_.ensemble .!= "r1i1p1f1_gr2", :]

  vars = [:model, :file]
  info = dt_merge(info_hi[:, [:model, :scenario, :file]], info_trs[:, vars], by = "model")
  
  # println(info)
  MultiModel_unfinished(info; del=false)
end


