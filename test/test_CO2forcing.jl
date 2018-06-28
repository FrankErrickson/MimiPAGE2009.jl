using Mimi
using Base.Test

include("../src/components/CO2forcing.jl")

m = Model()
set_dimension!(m, :time, [2009.,2010.,2020.,2030.,2040., 2050., 2075., 2100., 2150., 2200.])
set_dimension!(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])

addcomponent(m, co2forcing)

set_parameter!(m, :co2forcing, :c_CO2concentration, readpagedata(m,"test/validationdata/c_co2concentration.csv"))

##running Model
run(m)

forcing=m[:co2forcing,:f_CO2forcing]
forcing_compare=readpagedata(m,"test/validationdata/f_co2forcing.csv")

@test forcing ≈ forcing_compare rtol=1e-3
