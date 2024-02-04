export Supplier

"""
   Supplier(name::String, cost_per_cut, kerf, available_stock::Vector{AvailablePanel})

A single supplier of sheet stock.

Some suppliers will cut shet stock down to the customer's
specifications.  `kerf` is the width of their saw custs.
`cost_per_cut` is what they charge for each cut.
"""
@Base.kwdef mutable struct Supplier
    name::String
    cost_per_cut::MoneyType
    kerf::LengthType
    available_stock::Vector{AvailablePanel}
end

export Supplier

