include("load_parameters.jl")

@defcomp Tolerability begin
    region = Index(region)

    y_year = Parameter(index=[time], unit="year")

    #incoming parameters from Climate
    rt_realizedtemperature = Parameter(index=[time, region], unit="degreeC")

    #component parameters
    plateau_increaseintolerableplateaufromadaptation = Parameter(index=[region], unit="degreeC")
    pstart_startdateofadaptpolicy = Parameter(index=[region], unit="year")
    pyears_yearstilfulleffect = Parameter(index=[region], unit="year")
    impred_eventualpercentreduction = Parameter(index=[region], unit= "%")
    impmax_maxtempriseforadaptpolicy = Parameter(index=[region], unit= "degreeC")
    istart_startdate = Parameter(index=[region], unit = "year")
    iyears_yearstilfulleffect = Parameter(index=[region], unit= "year")

    #component variables
    atl_adjustedtolerableleveloftemprise = Variable(index=[time,region], unit="degreeC")
    imp_actualreduction = Variable(index=[time, region], unit= "%")
    i_regionalimpact = Variable(index=[time, region], unit="degreeC")

end

@defcomp SeaLevelTolerability begin
    region = Index(region)

    y_year = Parameter(index=[time], unit="year")

    #incoming parameters from SeaLevelRise
    s_sealevel = Parameter(index=[time, region], unit="meter")

    #component parameters
    plateau_increaseintolerableplateaufromadaptation = Parameter(index=[region], unit="meter")
    pstart_startdateofadaptpolicy = Parameter(index=[region], unit="year")
    pyears_yearstilfulleffect = Parameter(index=[region], unit="year")
    impred_eventualpercentreduction = Parameter(index=[region], unit= "%")
    impmax_maxsealevelriseforadaptpolicy = Parameter(index=[region], unit= "meter")
    istart_startdate = Parameter(index=[region], unit = "year")
    iyears_yearstilfulleffect = Parameter(index=[region], unit= "year")

    #component variables
    atl_adjustedtolerablelevelofsealevelrise = Variable(index=[time,region], unit="meter")
    imp_actualreduction = Variable(index=[time, region], unit= "%")
    i_regionalimpact = Variable(index=[time, region], unit="meter")

end

function run_timestep(s::Tolerability, t::Int64)
    v = s.Variables
    p = s.Parameters
    d = s.Dimensions

    for r in d.region
        if (p.y_year[t] - p.pstart_startdateofadaptpolicy[r]) < 0
            v.atl_adjustedtolerableleveloftemprise[t,r]= 0
        elseif ((p.y_year[t]-p.pstart_startdateofadaptpolicy[r])/p.pyears_yearstilfulleffect[r])<1.
            v.atl_adjustedtolerableleveloftemprise[t,r]=
                ((p.y_year[t]-p.pstart_startdateofadaptpolicy[r])/p.pyears_yearstilfulleffect[r]) *
                p.plateau_increaseintolerableplateaufromadaptation[r]
        else
            p.plateau_increaseintolerableplateaufromadaptation[r]
        end

        if (p.y_year[t]- p.istart_startdate[r]) < 0
            v.imp_actualreduction[t,r] = 0
        elseif ((p.y_year[t]-istart_a[r])/iyears_a[r]) < 1
            v.imp_actualreduction[t,r] =
                (p.y_year[t]-p.istart_startdate[r])/p.iyears_yearstilfulleffect[r]*
                p.impred_eventualpercentreduction[r]
        else
            v.imp_actualreduction[t,r] = p.impred_eventualpercentreduction[r]
        end
        if (p.rt_realizedtemperature[t,r]-v.atl_adjustedtolerableleveloftemprise[t,r]) < 0
            v.i_regionalimpact[t,r] = 0
        else
            v.i_regionalimpact[t,r] = p.rt_realizedtemperature[t,r]-v.atl_adjustedtolerableleveloftemprise[t,r]
        end
    end


end

function run_timestep(s::SeaLevelTolerability, t::Int64)
    v = s.Variables
    p = s.Parameters
    d = s.Dimensions

    for r in d.region
        if (Y[t] - p.pstart_startdateofadaptpolicy[r]) < 0
            v.atl_adjustedtolerablelevelofsealevelrise[t,r]= 0
        elseif ((Y[t]-p.pstart_startdateofadaptpolicy[r])/p.pyears_yearstilfulleffect[r])<1.
            v.atl_adjustedtolerablelevelofsealevelrise[t,r]=
                ((Y[t]-p.pstart_startdateofadaptpolicy[r])/p.pyears_yearstilfulleffect[r]) * p.plateau_increaseintolerableplateaufromadaptation[r]
        else
            p.plateau_increaseintolerableplateaufromadaptation[r]
        end

        if (Y[t]- p.istart_startdate[r]) < 0
            v.imp_actualreduction[t,r] = 0
        elseif ((Y[t]-istart_a[r])/iyears_a[r]) < 1
            v.imp_actualreduction[t,r] =
                (Y[t]-p.istart_startdate[r])/p.iyears_yearstilfulleffect[r]*p.impred_eventualpercentreduction[r]
        else
            v.imp_actualreduction[t,r] = p.impred_eventualpercentreduction[r]
        end

        if (p.s_sealevel[t,r]-v.atl_adjustedtolerablelevelofsealevelrise[t,r]) < 0
            v.i_regionalimpact[t,r] = 0
        else
            v.i_regionalimpact[t,r] = p.s_sealevel[t,r]-v.atl_adjustedtolerablelevelofsealevelrise[t,r]
        end
    end

end

function addtolerabilitymarket(model::Model)
    tolerabilitymarketcomp = addcomponent(model, Tolerability, :MarketTolerability)

    tolerabilitymarketcomp[:plateau_increaseintolerableplateaufromadaptation] = readpagedata(model, "../data/market_plateau.csv")
    tolerabilitymarketcomp[:pstart_startdateofadaptpolicy] = readpagedata(model, "../data/marketadaptstart.csv")
    tolerabilitymarketcomp[:pyears_yearstilfulleffect] = readpagedata(model, "../data/marketadapttimetoeffect.csv")
    tolerabilitymarketcomp[:impred_eventualpercentreduction] = readpagedata(model, "../data/marketimpactreduction.csv")
    tolerabilitymarketcomp[:impmax_maxtempriseforadaptpolicy] = readpagedata(model, "../data/marketmaxtemprise.csv")
    tolerabilitymarketcomp[:istart_startdate] = readpagedata(model, "../data/marketadaptstart.csv")
    tolerabilitymarketcomp[:iyears_yearstilfulleffect] = readpagedata(model, "../data/marketimpactyearstoeffect.csv")

    return tolerabilitymarketcomp
end

function addtolerabilitynonmarket(model::Model)
    tolerabilitynonmarketcomp = addcomponent(model, Tolerability, :NonMarketTolerability)

    tolerabilitynonmarketcomp[:plateau_increaseintolerableplateaufromadaptation] = readpagedata(model, "../data/nonmarket_plateau.csv")
    tolerabilitynonmarketcomp[:pstart_startdateofadaptpolicy] = readpagedata(model, "../data/nonmarketadaptstart.csv")
    tolerabilitynonmarketcomp[:pyears_yearstilfulleffect] = readpagedata(model, "../data/nonmarkettimetoadapt.csv")
    tolerabilitynonmarketcomp[:impred_eventualpercentreduction] = readpagedata(model, "../data/nonmarketimpactreduction.csv")
    tolerabilitynonmarketcomp[:impmax_maxtempriseforadaptpolicy] = readpagedata(model, "../data/nonmarketmaxtemprise.csv")
    tolerabilitynonmarketcomp[:istart_startdate] = readpagedata(model, "../data/nonmarketadaptstart.csv")
    tolerabilitynonmarketcomp[:iyears_yearstilfulleffect] = readpagedata(model, "../data/nonmarketimpactyearstoeffect.csv")

    return tolerabilitynonmarketcomp
end

function addtolerabilitysealevel(model::Model)
    tolerabilitysealevelcomp = addcomponent(model, SeaLevelTolerability, :SeaLevelTolerability)

    tolerabilitysealevelcomp[:plateau_increaseintolerableplateaufromadaptation] = readpagedata(model, "../data/sealevel_plateau.csv")
    tolerabilitysealevelcomp[:pstart_startdateofadaptpolicy] = readpagedata(model, "../data/sealeveladaptstart.csv")
    tolerabilitysealevelcomp[:pyears_yearstilfulleffect] = readpagedata(model, "../data/sealeveladapttimetoeffect.csv")
    tolerabilitysealevelcomp[:impred_eventualpercentreduction] = readpagedata(model, "../data/sealevelimpactreduction.csv")
    tolerabilitysealevelcomp[:impmax_maxsealevelriseforadaptpolicy] = readpagedata(model, "../data/sealevelmaxrise.csv")
    tolerabilitysealevelcomp[:istart_startdate] = readpagedata(model, "../data/sealeveladaptstart.csv")
    tolerabilitysealevelcomp[:iyears_yearstilfulleffect] = readpagedata(model, "../data/sealevelimpactyearstoeffect.csv")

    return tolerabilitysealevelcomp
end
