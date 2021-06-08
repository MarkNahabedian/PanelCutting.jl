md"""
# Axes

We define two singleton types LengthAxis and WidthAxis with the common supertype Axis.

Note that the instances of these Axis types are LengthAxis() and WidthAxis().

Measurements are made along an axis.

Cuts are made across an axis.
"""

abstract type Axis end

struct LengthAxis <: Axis end
struct WidthAxis <: Axis end

"""
    other(axis)
returns the axis that is perpendicular to the specified axis.
"""
function other end
	
function other(axis::LengthAxis)::Axis
    WidthAxis()
end

function other(axis::WidthAxis)::Axis
    LengthAxis()
end

"""
    moveby(x, y, axis, distance)
return new `x`, `y` values that have been moved from the given ones
by the specified `distance` along the specified `axis`.
"""
function moveby end

function moveby(x, y, axis::LengthAxis, distance)
    (x + distance, y)
end

function moveby(x, y, axis::WidthAxis, distance)
    (x, y + distance)
end

const zerozero = (0u"inch", 0u"inch")

@assert LengthAxis() isa Axis
@assert WidthAxis() isa Axis
@assert other(WidthAxis()) == LengthAxis()
@assert other(LengthAxis()) == WidthAxis()

@assert moveby(zerozero..., LengthAxis(), 10u"inch") == (10u"inch", 0u"inch")
@assert moveby(zerozero..., WidthAxis(), 10u"inch") == (0u"inch", 10u"inch")

export Axis, LengthAxis, WidthAxis
export other, moveby, zerozero

