
md"""
# Panels

We start with a goal of producing a set of WantedPanels of specified
sizes.

We then select an AvailablePanel and cut it.  Each cut
potentially produces two new offcut Panels.

When one of these Panels matches a WanterPanel we associate that Panel
with the WantedPanel using a FinishedPanel.

We give Panels an X and Y 'origin' origin as well as a length (along
x) and width to simplify SVG generation.(along y)

"""

md"""
    panelUID()
Generate a unique identifier for each panel when it is created.
We do this because Julia does not have a notion of equality that
distibguishes between two separately created immutable structs
with the same contents
"""
let
  local nextID = 1
  global function panelUID()::Int
	i = nextID
	nextID += 1
	return i
  end
end

abstract type AbstractPanel end
abstract type CuttablePanel <: AbstractPanel end
abstract type AbstractWantedPanel <: AbstractPanel end
abstract type TerminalPanel <: AbstractPanel end

LengthType = Unitful.Length

function area(panel::AbstractPanel)
    panel.length * panel.width
end

function diagonal(panel::AbstractPanel)
    sqrt(panel.length * panel.length + panel.width * panel.width)
end

"""Return the greater of the Panel's two dimensions."""
function major(p::AbstractPanel)
    max(p.length, p.width)
end

"""Return the lesser of the Panel's two dimensions."""
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
Return newX and newY so long as they are not 0.
If zero, use the corresponding default value.
"""
function replace0(defaultX, defaultY, newX, newY)
    ((newX == zero(newX) ? defaultX : newX),
     (newY == zero(newY) ? defaultY : newY))
end
	
"""
See if small can be cut from big
"""
function fitsin(small::AbstractPanel, big::AbstractPanel)::Bool
    return minor(small) <= minor(big) && major(small) <= major(big)
end

"""
an ordering function for sorting panels by size.
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
export AbstractPanel, CuttablePanel, AbstractWantedPanel, TerminalPanel
export LengthType
export area, diagonal, major, minor, distance, replace0, fitsin, smaller


md"""
## WantedPanel

WantedPanel described a panel that we need to have cut from some sheet
stock.  A Set of AbstractWantedPanels establishes the goal of our
search.
"""

"""
specifies a Panel we're trying to make.
"""
@Base.kwdef struct WantedPanel <: AbstractWantedPanel
    uid::Int = panelUID()
    length::LengthType
    width::LengthType
    label
end

export WantedPanel


md"""
## FlippedPanel

FlippedPanel wraps a WantedPanel to indicate that its want can be
satisfied by a panel even if its length and width are swapped.

This allows the user to control whether flipping is allowed of if they
care about grain direction.

When either the original or the flipped panel is finished then its
counterpart will be removed from the unsatisfied wants as well.  The
function wantsmatch is used for this test.
"""

"""
Specifies that a Panel will satisfy the want of our was panel
even if its length and width are swapped.
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
	_        => getfield(panel, prop)
    end
end
    
function Base.propertynames(panel::FlippedPanel, private::Bool=false)
    (:length, :width, :label, fieldnames(typeof(panel))...)
end

function flipped(panel::WantedPanel)
    if panel.length == panel.width
	return panel
    end
    return FlippedPanel(panel)
end

wantsmatch(p1::WantedPanel, p2::WantedPanel) = p1 == p2
wantsmatch(p1::FlippedPanel, p2::FlippedPanel) = p1 == p2
wantsmatch(p1::WantedPanel, p2::FlippedPanel) = p1 == p2.was
wantsmatch(p1::FlippedPanel, p2::WantedPanel) = p1.was == p2

export FlippedPanel, flipped, wantsmatch

# Testing
let
    w = WantedPanel(width=1u"inch", length=2u"inch", label="foo")
    f = flipped(w)
    @assert w.length == f.width
    @assert w.width == f.length
    @assert setdiff(Set(propertynames(f)), Set(propertynames(w))) == Set((:was,))
    @assert wantsmatch(w, w)
    @assert wantsmatch(f, f)
    @assert wantsmatch(w, f)
    @assert wantsmatch(f, w)
    @assert flipped(WantedPanel(width=10u"inch",
				length=10u"inch",
				label="square")) isa WantedPanel
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


md"""
## AvailablePanel
"""

md"""
A sheet of plywood we can buy frm the lumber yard.
"""
@Base.kwdef struct AvailablePanel <: AbstractPanel
    uid::Int = panelUID()
    label::String
    width::LengthType
    length::LengthType
    cost::MoneyType
end

function AvailablePanel(label::String,
			width::LengthType, length::LengthType,
			cost::MoneyType)
    AvailablePanel(label=label, width=width, length=length, cost=cost)
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

export AvailablePanel


md"""
## BoughtPanel

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
	_        => getfield(panel, prop)	
    end
end

function Base.propertynames(panel::BoughtPanel, private::Bool=false)
    (:x, :y, :length, :width, :label, :cost, fieldnames(typeof(panel))...)
end

# Though two BoughtPanels might be derived from the same
# AvailablePanel, we need to be able to distinguish between them
# because making a cut in one of them does not alter tje other.
let
    ap = AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", money(95.00))
    @assert BoughtPanel(ap) != BoughtPanel(ap)
end

export BoughtPanel


md"""
## Panel

Panel represents a panel that has been cut from an AvailablePanel but
does not yet match an AbstractWantedPanel.
"""

"""
a panel that is in progress.
"""
struct Panel <: CuttablePanel
    uid::Int
    length::LengthType
    width::LengthType
    cut_from::CuttablePanel
    cut_at::LengthType
    cut_axis::Axis
    x::LengthType
    y::LengthType
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

export Panel


md"""
## ScrappedPanel

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
	_        => getfield(panel, prop)
    end
end

function Base.propertynames(panel::ScrappedPanel; private=false)
    (:x, :y, :length, :width, :label, :cost, fieldnames(typeof(panel))...)
end

export ScrappedPanel


md"""
## FinishedPanel

FinishedPanel wraps a Panel that matches an AbstractWantedPanel and
associates that AbstractWantedPanel with the cut Panel.
"""

"""
matches an AbstractedWantedPanel that we've successfully made.
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
	_          => getfield(panel, prop)
    end
end

function Base.propertynames(panel::FinishedPanel, private::Bool=false)
    (:x, :y, :length, :width, :label, :cost, fieldnames(typeof(panel))...)
end

export FinishedPanel


md"""
## Collections of Panels

Our SearchState objects contain several collections of panels.  We'd
like these collections to be immutable, like the SearchStates
themselves.

When transitioning from one SearchState to its possible successor
states, these collections could change in the following ways:

  * a WantedPanel and possibly its flipped counterpart, might be removed and a FinishedPanel added
  * one or two CuttablePanels added to stock panels
  * CuttablePanels moved from stock to waste if they are too small for any remaining wanted panels

Here we implement an immutable collection type Panels based on Tuple to support these operations.
"""

Panels{T} = Tuple{Vararg{T}} where T <: AbstractPanel

export Panels

md"""
## Progenitor
"""

md"""
Return the BoughtPanel that this panel was cut from.

An AbstractPanel is its own progenitor.

A WantedPanel is its own progenitor.

A FlippedPanel is its own progenitor.
	    
progenitor is used in the overlap test: panels
can not overlap if they have different progeniyors.
"""
function Progenitor end

progenitor(panel::AbstractPanel) = panel

function progenitor(panel::FinishedPanel)::BoughtPanel
    progenitor(panel.was)
end

function progenitor(panel::Panel)::BoughtPanel
    progenitor(panel.cut_from)
end

export progenitor


md"""
## Testing if Panels Overlap
"""

struct PanelOverlapError <: Exception
    panel1::AbstractPanel
    panel2::AbstractPanel
    state
    why
end

function Base.showerror(io::IO, e::PanelOverlapError)
    print(io, "PanelOverlapError: \n  ", e.panel1, "\n  ", e.panel2)
end

# Spans

abstract type Span end

struct XSpan <: Span
    c1
    c2

    XSpan(c1, c2) = new(c1, c2)

    function XSpan(panel::AbstractPanel)
        new(panel.x, panel.x + panel.length)
    end
end

struct YSpan <: Span
    c1
    c2

    YSpan(c1, c2) = new(c1, c2)

    function YSpan(panel::AbstractPanel)
        new(panel.y, panel.y + panel.width)
    end
end

function within(c, s::Span)::Bool
    c >= s.c1 && c <= s.c2
end

function overlap(s1::T, s2::T)::Bool where T <: Span
    within(s1.c1, s2) ||
        within(s1.c2, s2) ||
        within(s2.c1, s1) ||
        within(s2.c2, s1)
end

function errIfOverlap(panel1::AbstractPanel, panel2::AbstractPanel, state)::Nothing
    distinct_panels = (panel1.uid !== panel2.uid)
    same_progenitor = (progenitor(panel1).uid == progenitor(panel2).uid)
    x_overlap = (overlap(XSpan(panel1), XSpan(panel2)))
    y_overlap = (overlap(YSpan(panel1), YSpan(panel2)))
    if distinct_panels && same_progenitor && x_overlap && y_overlap
	throw(PanelOverlapError(panel1, panel2, state,
				(distinct_panels=distinct_panels,
			 	 same_progenitor=same_progenitor,
				 x_overlap=x_overlap,
				 y_overlap=y_overlap)))
    end
end

export PanelOverlapError, Span, XSpan, YSpan, within, overlap, errIfOverlap

let
    xs1 = XSpan(0, 25)
    xs2 = XSpan(25.125, 30)
    @assert !overlap(xs1, xs2)
end

let
    s = XSpan(0, 10)
    @assert within(0, s)
    @assert within(10, s)
    @assert within(5, s)
    @assert !within(12, s)
end

let
    s1 = XSpan(0, 10)
    s2 = XSpan(3, 7)
    s3 = XSpan(5, 15)
    s4 = XSpan(12, 20)
    @assert overlap(s1, s2)
    @assert overlap(s2, s1)
    @assert overlap(s1, s3)
    @assert overlap(s3, s1)
    @assert !overlap(s1, s4)
    @assert !overlap(s4, s1)
end

