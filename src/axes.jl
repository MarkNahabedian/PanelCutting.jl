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

@assert LengthAxis() isa Axis
@assert WidthAxis() isa Axis
@assert other(WidthAxis()) == LengthAxis()
@assert other(LengthAxis()) == WidthAxis()

unit_vector(::LengthAxis) = [1 0]
unit_vector(::WidthAxis) = [0 1]

const zerovector = [0u"inch" 0u"inch"]

area(v::Array{<:Number, 2}) = v[1] * v[2]

@assert area([2 3]) == 6

const zeroarea = area(zerovector)

export Axis, LengthAxis, WidthAxis, other
export unit_vector, zerovector, zeroarea

