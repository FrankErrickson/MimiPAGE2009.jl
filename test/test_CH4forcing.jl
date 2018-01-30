using Mimi
using Base.Test

include("../src/CH4forcing.jl")
include("../src/load_parameters.jl")


m = Model()
setindex(m, :time, [2009.,2010.,2020.,2030.,2040., 2050., 2075., 2100., 2150., 2200.])
setindex(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])

addCH4forcing(m)

setparameter(m, :ch4forcing, :c_N2Oconcentration, readpagedata(m,"test/validationdata/c_n2oconcentration.csv"))
setparameter(m, :ch4forcing, :c_CH4concentration, readpagedata(m,"test/validationdata/c_ch4concentration.csv"))

##running Model
run(m)

@test !isnan(m[:ch4forcing, :f_CH4forcing][10])

forcing=m[:ch4forcing,:f_CH4forcing]
forcing_compare=readpagedata(m,"test/validationdata/f_ch4forcing.csv")

@test forcing ≈ forcing_compare atol=1e-3
