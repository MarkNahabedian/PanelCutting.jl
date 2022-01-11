# Appearance of out panel cut graphs in dot.

using Printf

export GRAPH_ATTRIBUTES


function graph_attributes(::PanelGraph)
    Dict([
        (:bgcolor, "black"),
        (:color, "white")
    ])
end

function node_attributes(::PanelGraph)
    Dict([
        (:color, "white"),
        (:fontcolor, "white")
    ])
end

function edge_attributes(::PanelGraph)
    Dict([
        (:color, "white"),
    ])
end


function prettydistance(x)
    s = @sprintf("%.3f", svgdistance(x))
    # trim trailing decimal zeros:
    if '.' in s
        s = rstrip(s, '0')
    end
    return s
end

function dotID(panel::AbstractPanel)
    t = split(string(typeof(panel)), ".")[end]
    "$(t)_$(string(panel.uid))"
end

function shorttype(panel::AbstractPanel)
    split(string(typeof(panel)), ".")[end]
end

function dotlabel(panel::AbstractPanel)
    "$(shorttype(panel))\n$(panel.uid)"
end

function dotlabel(panel::AvailablePanel)
    join([
        "$(shorttype(panel))",
        panel.label,
        "length: $(prettydistance(panel.length))",
        "width: $(prettydistance(panel.width))",
        @sprintf("cost: %.2f", panel.cost)
    ], "\n")
end

function dotlabel(panel::FinishedPanel)
    join([
        "$(shorttype(panel))",
        panel.wanted.label,
        "length: $(prettydistance(panel.length))",
        "width: $(prettydistance(panel.width))",
        "x: $(prettydistance(panel.x))",
        "y: $(prettydistance(panel.y))",
        @sprintf("cost: %.2f", panel.cost)
    ], "\n")
end

function dotlabel(panel::Panel)
    join([
        "$(shorttype(panel))",
        "length: $(prettydistance(panel.length))",
        "width: $(prettydistance(panel.width))",
        "at: $(prettydistance(panel.cut_at))",
        pretty(panel.cut_axis),
        "x: $(prettydistance(panel.x))",
        "y: $(prettydistance(panel.y))",
        @sprintf("cost: %.2f", panel.cost)
    ], "\n")
end

dotshape(panel::AbstractPanel) = "box"

function dotnode(io::IO, graph::PanelGraph, panel::AbstractPanel)
    attrs = dot_attributes_string(
        ;
        label=dotlabel(panel),
        shape=dotshape(panel))
    write(io, """  "$(dotID(panel))" [$attrs]\n""")
end

function dotedge(io::IO, graph::PanelGraph, from, to)
    diarc(io, from, to)
end
