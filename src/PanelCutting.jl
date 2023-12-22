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
using XML
using DisplayAs
using UUIDs
using Plots
using Logging
using Graphviz_jll

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


include("dot/generic_dot.jl")
include("dot/dot_style.jl")

include("AllOf.jl")
include("axes.jl")
include("panels.jl")
include("overlap.jl")
include("cutting.jl")
include("supplier.jl")
include("search.jl")
include("report.jl")
include("metagraphsnext_interface.jl")
include("panel_numbers.jl")
include("dot_styles.jl")
include("PanelCutGraph.jl")
include("svg.jl")
include("box.jl")

#  include("./panels_notebook.jl")

end
