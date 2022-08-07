@time using nctools
using nctools.CMIP
using Ipaper
using JLD2

chunk = 1
mpi_id = 1

function par_init()
end

# using MPI
# MPI.Init()
# comm = MPI.COMM_WORLD
# mpi_id = MPI.Comm_rank(comm) + 1
# chunk = MPI.Comm_size(comm)
