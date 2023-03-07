

let
  local nextID = 1
  global function panelUID()::Int
	i = nextID
	nextID += 1
	return i
  end
end

@doc """
    panelUID()

Generate a unique identifier for each panel when it is created.
We do this because Julia does not have a notion of equality that
distibguishes between two separately created immutable structs
with the same contents.
""" panelUID


abstract type AbstractPanel end
abstract type CuttablePanel <: AbstractPanel end
abstract type AbstractWantedPanel <: AbstractPanel end
abstract type TerminalPanel <: AbstractPanel end

LengthType = Unitful.Length


"""
    area(panel)

Return the area of the panel.
"""
function area(panel::AbstractPanel)
    panel.length * panel.width
end

function diagonal(panel::AbstractPanel)
    sqrt(panel.length * panel.length + panel.width * panel.width)
end


"""
    major(panel)

Return the greater of the Panel's two dimensions.
"""
function major(p::AbstractPanel)
    max(p.length, p.width)
end


"""
    minor(panel)

Return the lesser of the Panel's two dimensions.
"""
function minor(p::AbstractPanel)
    min(p.length, p.width)
end

function distance(panel::AbstractPanel, axis::WidthAxis)
    panel.width
end

function distance(panel::AbstractPanel, axis::LengthAxis)
    panel.length
end

	
"""
    replace0(defaultX, defaultY, newX, newY)

Return newX and newY so long as they are not 0.
If zero, use the corresponding default value.
"""
function replace0(defaultX, defaultY, newX, newY)
    ((newX == zero(newX) ? defaultX : newX),
     (newY == zero(newY) ? defaultY : newY))
end


"""
    fitsin(small::AbstractPanel, big::AbstractPanel)::Bool

See if small can be cut from big.
"""
function fitsin(small::AbstractPanel, big::AbstractPanel)::Bool
    return minor(small) <= minor(big) && major(small) <= major(big)
end


"""
    smaller(p1::AbstractPanel, p2::AbstractPanel)::Bool

An ordering function for sorting panels by size.
smaller(p1, p2) does not imply fitsin(p1, p2).
"""
function smaller(p1::AbstractPanel, p2::AbstractPanel)::Bool
    if fitsin(p1, p2)   # superfluous?
        return true
    elseif major(p1) > major(p2)
        return false
    elseif major(p1) < major(p2)
        return true 
    elseif minor(p1) > minor(p2)
        return false
    elseif minor(p1) > minor(p2)
        return true
    else
        return false
    end
end

export panelUID
export compatible
export AbstractPanel, AbstractWantedPanel, FlippedPanel, WantedPanel
export AvailablePanel, CuttablePanel, BoughtPanel, Panel,  TerminalPanel
export FinishedPanel, ScrappedPanel, Panels
export progenitor
export LengthType
export area, diagonal, major, minor, distance, replace0, fitsin, smaller
export panel_xy, panel_lw

panel_xy(p::CuttablePanel) = [p.x p.y]
panel_lw(p::CuttablePanel) = [p.length p.width]


"""
    compatible(panel, panel2):Bool

Return true if the panels have the same thickness and material.
"""
compatible(panel1, panel2) =
    panel1.thickness == panel2.thickness &&
    panel1.material == panel2.material


"""
    WantedPanel

WantedPanel describes a panel that we need to have cut from some sheet
stock.  A Set of AbstractWantedPanels establishes the goal of our
search.
"""
@Base.kwdef struct WantedPanel <: AbstractWantedPanel
    uid::Int = panelUID()
    length::LengthType
    width::LengthType
    thickness::LengthType
    material = ""
    label
end


"""
    FlippedPanel

FlippedPanel wraps a WantedPanel to indicate that its want can be
satisfied by a panel even if its length and width are swapped.

This allows the user to control whether flipping is allowed of if they
care about grain direction.

When either the original or the flipped panel is finished then its
counterpart will be removed from the unsatisfied wants as well.  The
function `wantsmatch` is used for this test.
"""
@Base.kwdef struct FlippedPanel <: AbstractWantedPanel
    uid::Int = panelUID()
    was::WantedPanel
end

function FlippedPanel(was::WantedPanel)
    FlippedPanel(; was=was)
end

function Base.getproperty(panel::FlippedPanel, prop::Symbol)
    was = getfield(panel, :was)
    @match prop begin
	:length  => was.width
	:width   => was.length
	:label   => "flipped $(was.label)"
        :thickness => was.thickness
        :material  => was.material
	_        => getfield(panel, prop)
    end
end
    
function Base.propertynames(panel::FlippedPanel, private::Bool=false)
    (:length, :width, :label, :thickness, :material, fieldnames(typeof(panel))...)
end

function flipped(panel::WantedPanel)
    if panel.length == panel.width
	return panel
    end
    return FlippedPanel(panel)
end


"""
    orFlipped(::WantedPanel)

Return a `Vector` of `AbstractWantedPanel` consisting of the
`WantedPanel` and possibly its corresponding `FlippedPanel`.
"""
function orFlipped(p::WantedPanel)::Vector{AbstractWantedPanel}
    result = Vector{AbstractWantedPanel}([p])
    if p.length != p.width
        push!(result, FlippedPanel(p))
    end
    return result
end

wantsmatch(p1::WantedPanel, p2::WantedPanel) = p1 == p2
wantsmatch(p1::FlippedPanel, p2::FlippedPanel) = p1 == p2
wantsmatch(p1::WantedPanel, p2::FlippedPanel) = p1 == p2.was
wantsmatch(p1::FlippedPanel, p2::WantedPanel) = p1.was == p2

export FlippedPanel, flipped, orFlipped, wantsmatch

function Base.:*(how_many::Integer, p::WantedPanel)::Vector{WantedPanel}
    map(1:how_many) do index
        WantedPanel(label = "$(p.label) $index",
                    length = p.length,
                    width = p.width,
                    thickness = p.thickness,
                    material = p.material)
    end
end

function uniqueWantedPanels(panels)::Vector{AbstractWantedPanel}
    result = Vector{AbstractWantedPanel}()
    have = []
    # Consider just FlippedPanels first:
    for flipped in filter(p -> p isa FlippedPanel, panels)
	push!(result, flipped)
	push!(have, flipped)
	push!(have, flipped.was)
    end
    # Now include any WantedPanels that are not also flipped:
    for wanted in filter(p -> p isa WantedPanel, panels)
	if wanted in have
	    continue
	end
	push!(result, wanted)
	push!(have, wanted)
    end
    return result
end

export uniqueWantedPanels


"""
    AvailablePanel

A sheet of plywood we can buy from the lumber yard.
"""
@Base.kwdef struct AvailablePanel <: AbstractPanel
    uid::Int = panelUID()
    label::String
    width::LengthType
    length::LengthType
    thickness::LengthType
    material = ""
    cost::MoneyType
end

function AvailablePanel(label::String,
			width::LengthType, length::LengthType,
                        thickness::LengthType,
			cost::MoneyType)
    AvailablePanel(label=label, width=width, length=length,
                   thickness=thickness, cost=cost)
end
		
function Base.getproperty(panel::AvailablePanel, prop::Symbol)
    @match prop begin
	:x  => 0u"inch"
	:y  => 0u"inch"
	_   => getfield(panel, prop)
    end
end
	
function Base.propertynames(panel::AbstractPanel, private::Bool=false)
    (:x, :y, fieldnames(typeof(panel))...)
end


"""
    BoughtPanel

a BoughtPanel is created to wrap an AvailablePanel when we add it to the working set.  This ensured that when it is cut it has a distinct identity from any other BoughtPanel of the same size.
"""
@Base.kwdef struct BoughtPanel <: CuttablePanel
    uid::Int = panelUID()
    was::AvailablePanel
end
	
function BoughtPanel(was::AvailablePanel)
    BoughtPanel(; was=was)
end

function Base.getproperty(panel::BoughtPanel, prop::Symbol)
    was = getfield(panel, :was)
    @match prop begin
	:x       => was.x
	:y       => was.y
	:length  => was.length
	:width   => was.width
	:label   => was.label
	:cost    => was.cost
        :thickness => was.thickness
        :material  => was.material
	_        => getfield(panel, prop)	
    end
end

function Base.propertynames(panel::BoughtPanel, private::Bool=false)
    (:x, :y, :length, :width, :label, :cost, :thickness, :material,
     fieldnames(typeof(panel))...)
end


"""
    Panel

Panel represents a panel that has been cut from an AvailablePanel but
does not yet match an AbstractWantedPanel.
"""
struct Panel <: CuttablePanel
    uid::Int
    length::LengthType
    width::LengthType
    cut_from::CuttablePanel
    cut_at::LengthType
    cut_axis::Axis  #the axis along which cut_at is measured
    # x and y are relative to the progenitor BoughtPanel:
    x::LengthType   # x is along LengthAxis()
    y::LengthType   # y is along WidthAxis()
    cost::MoneyType
    
    function Panel(; length::LengthType, width::LengthType,
		   cut_from::CuttablePanel, cut_at::LengthType, cut_axis::Axis,
		   x::LengthType, y::LengthType, cost)
	@assert length > 0u"inch"  "length $length > 0"
	@assert width > 0u"inch"   "width $width > 0"
	@assert x >= 0u"inch"      "x $x >= 0"
	@assert y >= 0u"inch"      "y $y >= 0"
	new(panelUID(), length, width,
	    cut_from, cut_at, cut_axis,
	    x, y, cost)
    end
end

function Base.getproperty(panel::Panel, prop::Symbol)
    cut_from = getfield(panel, :cut_from)
    @match prop begin
        :thickness => cut_from.thickness
        :material  => cut_from.material
	_          => getfield(panel, prop)
    end
end

function Base.propertynames(panel::Panel, private::Bool=false)
    (:thickness, :material, fieldnames(typeof(panel))...)
end


"""
    ScrappedPanel

ScrappedPanel wraps a Panel that is not big enough to cut any
remaining AbstractWantedPanel from.
"""
@Base.kwdef struct ScrappedPanel <: TerminalPanel
    uid::Int = panelUID()
    was::Panel    # We should never be scrapping an AvailablePanel.
end


# delegations from ScrappedPanel to the Panel we're tagging as too small
function Base.getproperty(panel::ScrappedPanel, prop::Symbol)
    was = getfield(panel, :was)
    @match prop begin
	:x       => was.x
	:y       => was.y
	:length  => was.length
	:width   => was.width
	:label   => "scrapped $(panel.uid)"
	:cost    => was.cost
        :thickness => was.thickness
        :material  => was.material
	_        => getfield(panel, prop)
    end
end

function Base.propertynames(panel::ScrappedPanel; private=false)
    (:x, :y, :length, :width, :label, :cost, :thickness, :material,
     fieldnames(typeof(panel))...)
end


"""
    FinishedPanel

FinishedPanel wraps a Panel that matches an AbstractWantedPanel and
associates that AbstractWantedPanel with the cut Panel.
"""
struct FinishedPanel <: TerminalPanel
    uid::Int
    wanted::AbstractWantedPanel
    was::CuttablePanel
    
    function FinishedPanel(candidate::Panel, wanted::AbstractWantedPanel)
        @assert candidate.length == wanted.length
        @assert candidate.width == wanted.width
	new(panelUID(), wanted, candidate)
    end
end
    
function Base.getproperty(panel::FinishedPanel, prop::Symbol)
    was = getfield(panel, :was)
    @match prop begin
	:x         => was.x
	:y         => was.y
	:length    => was.length
	:width     => was.width
	:label     => getfield(panel, :wanted).label
	:cost      => was.cost
        :thickness => was.thickness
        :material  => was.material
	_          => getfield(panel, prop)
    end
end

function Base.propertynames(panel::FinishedPanel, private::Bool=false)
    (:x, :y, :length, :width, :label, :cost, :thickness, :material,
     fieldnames(typeof(panel))...)
end


"""
    Panels

An immutable collections of Panels

Our `SearchState` objects contain several collections of panels.  We'd
like these collections to be immutable, like the SearchStates
themselves.

When transitioning from one SearchState to its possible successor
states, these collections could change in the following ways:

  * a WantedPanel and possibly its flipped counterpart, might be removed and a FinishedPanel added
  * one or two CuttablePanels added to stock panels
  * CuttablePanels moved from stock to waste if they are too small for any remaining wanted panels
"""
Panels{T} = Tuple{Vararg{T}} where T <: AbstractPanel


"""
    progenitor(panel)

Return the BoughtPanel that this panel was cut from.

An AbstractPanel is its own progenitor.

A WantedPanel is its own progenitor.

A FlippedPanel is its own progenitor.
	    
progenitor is used in the overlap test: panels
can not overlap if they have different progenitors.
"""
function progenitor end

progenitor(panel::AbstractPanel) = panel

function progenitor(panel::FinishedPanel)::BoughtPanel
    progenitor(panel.was)
end

function progenitor(panel::Panel)::BoughtPanel
    progenitor(panel.cut_from)
end

