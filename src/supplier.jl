
@Base.kwdef mutable struct Supplier
    name::String
    cost_per_cut::MoneyType
    kerf::LengthType
    available_stock::Vector{AvailablePanel}
end

export Supplier

