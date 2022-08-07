#! /bin/bash
# module load mpi/impi/2020.1
mpiexec -n 10 julia --sysimage /opt/julia/libnctools.so --project scripts/s02_cal_HI.jl
