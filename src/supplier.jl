
@Base.kwdef mutable struct Supplier
    name::String
    cost_per_cut::Quantity{N, CURRENCY} where N
    kerf::LengthType
    available_stock::Vector{AvailablePanel}
end

export Supplier

