module PanelCutting

using Revise
using Printf
using Markdown
using Unitful
using UnitfulUS
# using UnitfulCurrency     #Problems
using Match
using DataStructures
using InteractiveUtils
using NativeSVG
using DisplayAs
using UUIDs
using Plots
using Logging
using NahaGraphs


# Work around issues with UnitfulCurrency
function money(amount)
    try
        amount * uparse("USD")
    catch e
        amount
    end
end

MoneyType = try
    Quantity{N, CURRENCY} where N
catch e
    Real
end

if MoneyType == Real
    unmoney(amount::Real) = amount
else
    eval(:(unmoney(amount::Quantity) = ustrip(Real, u"USD", amount)))
end

export money, MoneyType, unmoney


include("AllOf.jl")
include("axes.jl")
include("panels.jl")
include("cutting.jl")
include("supplier.jl")
include("search.jl")
include("report.jl")
include("graph.jl")
include("generic_dot.jl")
include("dot_styles.jl")

include("svg.jl")

#  include("./panels_notebook.jl")

end
