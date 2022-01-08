# Appearance of out panel cut graphs in dot.

using Printf

export GRAPH_ATTRIBUTES

#=
It appears that graphviz version 2.50.0 (20211204.2007)
does not respect graph attributes when generating SVG output.

For now I'm editing the SVG files by hand:

replacing: stroke="black"
with:      stroke="white"

replacing: <text
with:      <text fill="white"


=#
GRAPH_ATTRIBUTES = Dict([
    ("bgcolor", "black"),
    ("color", "white")
])

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
    "$(shorttype(panel))\n$(panel.label)"
end

function dotlabel(panel::FinishedPanel)
    join([
        "$(shorttype(panel))",
        panel.wanted.label,
        "length: $(prettydistance(panel.length))",
        "width: $(prettydistance(panel.width))",
        "x: $(prettydistance(panel.x))",
        "y: $(prettydistance(panel.y))"
    ], "\n")
end

function dotlabel(panel::Panel)
    join([
        "$(shorttype(panel))",
        "length: $(prettydistance(panel.length))",
        "width: $(prettydistance(panel.width))",
        "x: $(prettydistance(panel.x))",
        "y: $(prettydistance(panel.y))"
    ], "\n")
end

dotshape(panel::AbstractPanel) = "box"

function dotnode(io::IO, graph, panel::AbstractPanel)
    label = dotlabel(panel)
    write(io, """  "$(dotID(panel))" [label="$label"; shape=$(dotshape(panel))]\n""")
end
