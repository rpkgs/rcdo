include("main_pkgs.jl")

fs = dir("./INPUT/TRS")

function jld_info(f)
  fid = jldopen(f)
  println(fid)
  # jldclose(fid)
end

f = ("./INPUT/TRS/HItasmax_movTRS_ACCESS-CM2.jld2")
# 5个阈值
TRS = load(f, "TRS_mov")
