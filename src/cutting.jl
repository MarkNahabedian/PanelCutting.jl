
md"""
# Cutting
"""

"""
    cut(panel, axis, at; kerf, cost)::(panel1, panel2)

Cut panel at the specified distance along axis.
The first returned panel is the piece cut to that distance.
The second is what remains (accounting for kerf).

An empty Tuple is returned if the cut can't be made.
"""  
function cut(panel::CuttablePanel,
             axis::Axis,
             at::LengthType;
             kerf = (1/8)u"inch",
             cost = money(0.0))
    if distance(panel, axis) < at
        return (())
    end
    # We might short circuit the test of the function if
    #   distance(panel, axis) == at
    # but then we might return a BoughtPanel rather than a Panel.
    # It does affect the cost though:
    cost = panel.cost + (distance(panel, axis) > at ? cost : 0)
    mult(v1, v2) = map(*, v1, v2)
    at_vector = at * unit_vector(axis)
    kerf_vector = kerf * unit_vector(axis)
    cross_vector = mult(panel_lw(panel), unit_vector(other(axis)))
    lw1 = at_vector + cross_vector
    prev = at_vector + kerf_vector
    xy2 = panel_xy(panel) + prev
    lw2 = panel_lw(panel) - prev
    if lw2[1] < 0u"inch" || lw2[2]< 0u"inch"
        lw2 = zerovector
    end
    area1 = area(lw1)
    area2 = area(lw2)
    total_area = area1 + area2
    panel1 = Panel(; length=lw1[1], width=lw1[2],
                   cut_from=panel, cut_at=at, cut_axis=axis,
                   x=panel.x, y=panel.y,
	           cost=cost * area1 / total_area)
    # There might be no off-cut if panel was bigger than at by kerf,
    # for example:
    if area2 > zeroarea
        # Maybe cost should be apportioned by area rather than by
        # count?  That would slightly favor shorter cuts.
        (panel1,
         Panel(; length=lw2[1], width=lw2[2],
               cut_from=panel, cut_at=at, cut_axis=axis,
               x=xy2[1], y=xy2[2],
	       cost=cost * area2 / total_area))
    else
        (panel1,)
    end
end

export cut

let
    KERF = (1/8)u"inch"
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", money(20.00)))

    # Cut panel1 at 25" down LengthAxis:
    panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch"; kerf=KERF)
    @assert panel2.length == 25u"inch"  """got $(panel2.length), expected $(25u"inch")"""
    @assert panel2.width == 30u"inch"
    @assert panel3.length == panel1.length - panel2.length - KERF
    @assert panel3.width == 30u"inch"   """got $(panel3.width), expected $(30u"inch")"""
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
    panel1 = BoughtPanel(AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", money(95.00)))
    at = 22u"inch"
    cut1, cut2 = cut(panel1, LengthAxis(), at, kerf=KERF)
    @assert cut1.length == at  "got $(cut1.length), expected $(at)"
    @assert cut1.width == panel1.width  "got $(cut1.width), expected $(panel1.width)"
    @assert cut2.width == panel1.width  "got $(cut2.width), expected $(panel1.width)"
    @assert cut2.length ≈ panel1.length - at - KERF (
        "got $(cut2.length), expected $(panel1.length - at - KERF)")
end
