
md"""
# Cutting
"""


"""
    CostDistribution

CostDistribution is the abstract supertype for the various choices we
implement for sharing the cost of a precursor panel and its cut with
its descendent panels.
"""
abstract type CostDistribution end



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
    # the cut is made in the direction of cross_vector, at_vector away
    # from the edge of the panel.  The cut is kerf_vector wide.
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

