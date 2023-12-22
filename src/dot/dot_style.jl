# Allow styling of GraphViz Dot diagrams independent of graph type.

using Markdown

md"""
A *graph style* is a type that supportes these methods:

  - graph_attributes(::GraphStyle)
  - node_attributes(::GraphStyle)
  - node_attributes(::GraphStyle, node)
  - edge_attributes(::GraphStyle)
  - edge_attributes(::GraphStyle, from, to)

These all should return a `Dict{Symbol, AbstractString}`.

Default methods are provided that give default Dot behavior.

You can define your own *graph style* to control how your graph is
styled by `dot`.
"""

export graph_attributes, node_attributes, edge_attributes
export AbstractDotStyleWhiteOnBlack, DotStyleWhiteOnBlack

"""
    graph_attributes(dotstyle)
Return a Dict of graph level attributes (for the Dot `graph` statement).
"""
graph_attributes(dotstyle) = Dict{Symbol, AbstractString}()


"""
    node_attributes(dotstyle)
Return a Dict of the default node attributes that should apply to all nodes of `graph`.
"""
node_attributes(dotstyle) = Dict{Symbol, AbstractString}()


"""
    node_attributes(dotstyle, node)
Return a Dict of the Dot attributes to be used when rendering `node`.
"""
node_attributes(dotstyle, node) = Dict{Symbol, AbstractString}()


"""
    edge_attributes(dotstyle)
Return a Dict of the default attributes that should apply to all edges of `graph`.
"""
edge_attributes(dotstyle) = Dict{Symbol, AbstractString}()


"""
    edge_attributes(dotstyle, from, to)
Return a Dict of the Dot attributes to be used when rendering the edge
running from `from` to `to`, which are both nodes.
"""
edge_attributes(dotstyle, from, to) = Dict{Symbol, AbstractString}()



md"""
A style for formatting graphs as white against a black background.
"""
abstract type AbstractDotStyleWhiteOnBlack end

graph_attributes(style::AbstractDotStyleWhiteOnBlack) = Dict{Symbol, AbstractString}([
    (:bgcolor, "black"),
    (:color, "white")
])

node_attributes(style::AbstractDotStyleWhiteOnBlack) = Dict{Symbol, AbstractString}([
    (:color, "white"),
    (:fontcolor, "white")
])

edge_attributes(style::AbstractDotStyleWhiteOnBlack) = Dict{Symbol, AbstractString}([
    (:color, "white")
])

struct DotStyleWhiteOnBlack <: AbstractDotStyleWhiteOnBlack end

