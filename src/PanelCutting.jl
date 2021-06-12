module PanelCutting

using Revise
using Printf
using Markdown
using Unitful
using UnitfulUS
using UnitfulCurrency
using Match
using DataStructures
using InteractiveUtils
using NativeSVG
using DisplayAs
using UUIDs
using Plots

include("AllOf.jl")
include("axes.jl")
include("panels.jl")
include("cutting.jl")
include("supplier.jl")
include("search.jl")
include("graph.jl")
include("generic_dot.jl")

function dotID(panel::AbstractPanel)
    t = split(string(typeof(panel)), ".")[end]
    "$(t)_$(string(panel.uid))"
end

include("svg.jl")

#  include("./panels_notebook.jl")

end
