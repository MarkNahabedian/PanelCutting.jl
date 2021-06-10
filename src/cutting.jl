
md"""
# Cutting
"""

"""
    cut(panel, axis, at, cost)::(panel1, panel2)

Cut panel at the specified distance along axis.
The first returned panel is the piece cut to that distance.
The second is what remains (accounting for kerf).

An empty Tuple is returned if the cut can't be made.

# Examples
```jldoctest
julia> panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20u"USD"))
...
julia> panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch", 0)
...
julia> panel2.length == 25u"inch"
true
julia> panel2.width == 30u"inch"
true
julia> panel3.length == panel1.length - panel2.length - KERF
true
julia> panel3.width == 30u"inch"
true
julia panel2.x == panel1.x
true
julia> panel2.y == panel1.y
true
julia> panel3.x == panel1.x + panel2.length + KERF
true
julia> panel3.y == panel1.y
true
``````
"""  
function cut(panel::CuttablePanel,
             axis::Axis,
             at::LengthType;
             kerf = (1/8)u"inch",
             cost = 0u"USD")
    if distance(panel, axis) < at
        return (())
    end
    cost = (panel.cost + cost) / 2
    p2xy = moveby(panel.x, panel.y, axis, at + kerf)
    panel1 = let
        (l, w) = replace0(panel.length, panel.width,
		          moveby(zerozero..., axis, at)...)
        Panel(; length=l, width=w,
              cut_from=panel, cut_at=at, cut_axis=axis,
              x=panel.x, y=panel.y,
	      cost=cost)
    end
    panel2l = panel.length - p2xy[1]
    panel2w = panel.width - p2xy[2]
    if panel2l > 0u"inch" && panel2w > 0u"inch"
        (panel1,
         Panel(length=panel2l, width=panel2w,
               cut_from=panel, cut_at=at, cut_axis=axis,
               x=p2xy[1], y=p2xy[2],
	       cost=cost))
    else
        (panel1,)
    end
end

export cut

let
    KERF = (1/8)u"inch"
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20u"USD"))

    let
	result = cut(panel1, LengthAxis(), 61u"inch"; kerf=KERF)
	@assert result == (())  "$(result) == (())"
    end
    let
	result = length(cut(panel1, LengthAxis(), 29.8u"inch", kerf=KERF))
	@assert length(result) == 1  "length($(result)) == 1"
    end
    # Cut panel1 at 25" down LengthAxis:
    panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch"; kerf=KERF)
    @assert panel2.length == 25u"inch"  """got $(panel2.length), expected $(25u"inch")"""
    @assert panel2.width == 30u"inch"
    @assert panel3.length == panel1.length - panel2.length - KERF
    @assert panel3.width == 30u"inch"
    @assert panel2.x == panel1.x   "panel2.x: got $(panel2.x), expected $(panel1.x)"
    @assert panel2.y == panel1.y
    @assert panel3.x == panel1.x + panel2.length + KERF
    @assert panel3.y == panel1.y
    
    # Cut panel2 at 10" down WidthAxis:
    panel4, panel5 = cut(panel2, WidthAxis(), 10u"inch", kerf=KERF)
    @assert panel4.width == 10u"inch"
    @assert panel4.length == panel2.length
    @assert panel4.x == panel2.x
    @assert panel4.y == panel2.y
    @assert panel5.x == panel2.x
    @assert panel5.y == panel4.y + panel4.width + KERF
    @assert panel5.length == panel2.length
    @assert panel5.width == panel2.width - panel4.width - KERF
end

let
    KERF = (1/8)u"inch"
    panel1 = BoughtPanel(AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", 95u"USD"))
    at = 22u"inch"
    cut1, cut2 = cut(panel1, LengthAxis(), at, kerf=KERF)
    @assert cut1.length == at  "got $(cut1.length), expected $(at)"
    @assert cut1.width == panel1.width  "got $(cut1.width), expected $(panel1.width)"
    @assert cut2.width == panel1.width  "got $(cut2.width), expected $(panel1.width)"
    @assert cut2.length ≈ panel1.length - at - KERF (
        "got $(cut2.length), expected $(panel1.length - at - KERF)")
end
