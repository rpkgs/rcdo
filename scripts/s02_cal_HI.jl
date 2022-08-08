# module load mpi/impi/2020.1
# mpiexec -n 10 julia --sysimage /share/opt/julia/libIpaper.so --project scripts/s02_cal_HI.jl

@time using nctools
using nctools.CMIP
using Ipaper

chunk = 1
mpi_id = 1


using MPI
MPI.Init()
comm = MPI.COMM_WORLD
mpi_id = MPI.Comm_rank(comm) + 1
chunk = MPI.Comm_size(comm)
# println("Hello world, I am $(mpi_id) of $(chunk)")


function CMIP6_cal_HI(info::DataFrame; parallel = true) 
  # @par parallel 
  for j = 1:nrow(info)
    if chunk > 1 && mod(j, chunk) != mpi_id; continue; end
    
    f_rh = info[j, :file]
    f_tas = info[j, :file_1]

    outfile = @pipe f_rh |> str_replace(_, "hurs", "HItasmax")
    mkpath(dirname(outfile))

    println("[j = $j]: outfile = $(basename(outfile))")
    # @show basename(outfile)
    # @show basename(f_tas)
    # @show basename(f_rh)
    try
      heat_index(f_tas, f_rh, outfile)  
    catch
      printstyled("[e] outfile = $(basename(outfile))\n", color=:red, underline=true, bold=true)
    end
  end
end

scenarios = ["hist-aer", "hist-GHG", "hist-nat", "historical", "ssp126", "ssp245", "ssp585"]#[1:1]
# scenario = scenarios[1]

for i = 1:length(scenarios)
  scenario = scenarios[i]
  indir_rh = "INPUT/ChinaHW_CMIP6_raw_bilinear/hurs/$scenario"
  indir_tas = "INPUT/ChinaHW_CMIP6_raw_bilinear/tasmax/$scenario"
  fs_rh = dir(indir_rh, "nc\$")
  fs_tas = dir(indir_tas, "nc\$")
  
  d_rh = CMIPFiles_info(fs_rh)
  d_tas = CMIPFiles_info(fs_tas)

  d_rh  = @pipe d_rh |> _[_.nmiss .== 0, :]
  d_tas = @pipe d_tas |> _[_.nmiss .== 0, :]

  vars = [:model, :ensemble, :file]
  info = dt_merge(d_rh[:, vars], d_tas[:, vars], by = ["model", "ensemble"])
  # @show scenario
  CMIP6_cal_HI(info)
end

# $(basename(outfile))

# CMIPFiles_info 函数运行较慢，检查原因
MPI.Barrier(comm)
# Threads.nthreads()
# julia --threads 5 --sysimage /opt/julia/libnctools.so ChinaHW_CMIP6_raw_bilinear/cal_HI.jl

## 查看日期类型为julia的model是哪个
## 用于debug
debug = false
if debug
  using JLD2
  @time d_rh = CMIPFiles_info(fs_rh)
  jldsave("debug.jld2"; fs_rh, d_rh)

  files = fs_rh

  @time begin
    date_begin, date_end = get_date(files)
    calender = nc_calendar.(files)
    cell_x, cell_y, regular = nc_cellsize(files)

    model = get_model.(files)
    ensemble = get_ensemble.(files)
    scenario = get_scenario.(files)  
    @time nmiss = get_date_nmiss.(files)
    # DataFrame(
    #       model = get_model.(files),
    #       ensemble = get_ensemble.(files),
    #       scenario = get_scenario.(files),
    #       date_begin = date_begin, date_end = date_end,
    #       calender = calender,
    #       nmiss = get_date_nmiss.(files), # v0.1.2
    #       cell_x = cell_x, cell_y = cell_y, grid_regular = regular, file = files)
  end
end
