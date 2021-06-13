"""
    Allof(iterables...)
combine the iterables into a single iterable.
"""
struct AllOf
    length::Int
    lengths
    iterables
    
    function AllOf(iterables...)
        lengths = length.(iterables)
        new(sum(lengths), lengths, iterables)
    end
end

function Base.length(x::AllOf)::Int
    x.length
end

Base.firstindex(x::AllOf) = 1

Base.lastindex(x::AllOf) = x.length

function Base.getindex(x::AllOf, index::Int)
    if index < 1
	throw(BoundsError(x, index))
    end
    idx = index
    for i in 1:length(x.lengths)
        if idx <= x.lengths[i]
            return x.iterables[i][idx]
        end
        idx -= x.lengths[i]
    end
    throw(BoundsError(x, index))
end

Base.iterate(iter::AllOf) = iterate(iter, firstindex(iter))

function Base.iterate(iter::AllOf, state::Int)
    if state > lastindex(iter)
        return
    end
    return iter[state], state + 1
end

export AllOf

