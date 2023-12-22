# Appearance of out panel cut graphs in dot.

using Printf

export PanelsDotStyle

struct PanelsDotStyle <: AbstractDotStyleWhiteOnBlack
end


function prettydistance(x)
    s = @sprintf("%.3f", svgdistance(x))
    # trim trailing decimal zeros:
    if '.' in s
        s = rstrip(s, '0')
    end
    return "$(s)inch"
end

function dotID(panel::AbstractPanel)
    t = split(string(typeof(panel)), ".")[end]
    "$(t)_$(string(panel.uid))"
end

function shorttype(panel)
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

function node_attributes(::PanelsDotStyle, node)
    Dict([
        (:label, dotlabel(node)),
        (:shape, dotshape(node))
    ])
end

