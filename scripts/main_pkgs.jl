@time using nctools
using nctools.CMIP
using Ipaper
using JLD2
using Plots
using SpatioTemporalCluster

chunk = 1
mpi_id = 1

function par_init()
end

# using MPI
# MPI.Init()
# comm = MPI.COMM_WORLD
# mpi_id = MPI.Comm_rank(comm) + 1
# chunk = MPI.Comm_size(comm)


function ncread(f)
  band = nc_bands(f)[1]
  nc_open(f) do nc
    x = nc[band].var[:, :, 1]
    x
  end
end

function glance_nc(f, outfile = "a.jpg")
  x = ncread(f)
  heatmap(x')
  write_fig(outfile; show=false)
end

function nc_info2(f)
  band = nc_bands(f)[1]
  nc_open(f) do nc
    var = nc[band]
    print(var)
  end
end


function getFileInfo(fs)  
  model = get_model.(fs, "day_|TRS_", "_hist|_ssp|_piControl|.jld2")
  ensemble = @pipe basename.(fs) |> get_ensemble.(_)
  scenario = get_scenario.(fs, "[a-z,A-Z,0-9,-]*(?=_r\\d)")

  dates = CMIP.get_date.(fs)
  # period = map(x -> "$(x[1])-$(x[2])", dates)
  DataFrame(; model, scenario, ensemble, period=dates, name = basename.(fs), file = fs)
end
