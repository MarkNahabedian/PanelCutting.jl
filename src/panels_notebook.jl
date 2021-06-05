### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ b019d660-9f77-11eb-1527-278a3e1b087c
begin
  using Pkg
  Pkg.activate(mktempdir())
  Pkg.add.([
	# Unitful version constrained by UnitfulCurrency
    Pkg.PackageSpec(name="Unitful", version="0.17.0"),
    Pkg.PackageSpec(name="UnitfulUS", version="0.2.0"),
	Pkg.PackageSpec(name="UnitfulCurrency"),
    Pkg.PackageSpec(name="Match", version="1.1.0"),
    Pkg.PackageSpec(name="DataStructures", version="0.18.9"),
    Pkg.PackageSpec(name="DisplayAs", version="0.1.2"),
    Pkg.PackageSpec(; name="NativeSVG",
                    path="c:/Users/Mark Nahabedian/.julia/dev/NativeSVG.jl"),
	"MacroTools",
	"Plots",
	# "BackendPackage"
	])

  using Printf
  using Unitful
  using UnitfulUS
  using Match
  using DataStructures
  using UnitfulCurrency
  using NativeSVG
  using DisplayAs
  using UUIDs
  using Plots
  import MacroTools
end

# ╔═╡ 5f5c5ef3-efed-4afd-b304-5b37a9a81bd2
LOAD_PATH

# ╔═╡ 60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
md"""
  # Setup

  Prefer inches.
  """

# ╔═╡ 1871abc7-d4cb-4ebd-862e-660a9ce5dc56
begin

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

end

# ╔═╡ 60fdb133-5d21-4445-90f9-3bbe49fb743b
begin
  Unitful.preferunits(u"inch")
end

# ╔═╡ 5be6a7bd-b97c-4b97-ab47-9d83b3a2dd77
md"""
  # Axes

  We define two singleton types LengthAxis and WidthAxis with the common supertype Axis.

  Note that the instances of these Axis types are LengthAxis() and WidthAxis().

  Measurements are made along an axis.

  Cuts are made across an axis.
  """

# ╔═╡ 6835fdd3-eead-4d2b-81ce-a05df4f57499
begin
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

end


# ╔═╡ 1292709e-63f9-4f9f-a6c0-0e9068a4c6b6
md"""
  # Panels

  We start with a goal of producing a set of WantedPanels of specified sizes.

  We then select an AvailablePanel and cut it.  Each cut potentiallyproduces two new offcut Panels.

  When one of these Panels matches a WanterPanel we associate that Panel with the WantedPanel using a FinishedPanel.

  We give Panels an X and Y 'origin' origin as well as a length (along x) and width to simplify SVG generation.(along y)
  """

# ╔═╡ 98a48a7c-51e9-46f9-bdb4-e6a6b8380061
begin
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
end

# ╔═╡ 29c94131-5b13-4588-a772-d517198d2163
md"""
  ## WantedPanel

  WantedPanel described a panel that we need to have cut from some sheet stock.  A Set of AbstractWantedPanels establishes the goal of our search.
  """

# ╔═╡ 34bab1fd-ecdc-4054-8c69-5325ae807e1f
"""
        specifies a Panel we're trying to make.
        """
@Base.kwdef struct WantedPanel <: AbstractWantedPanel
  uid::Int = panelUID()
  length::LengthType
  width::LengthType
  label
end

# ╔═╡ 7c51768d-f376-487c-a88d-f795fb01da48
md"""
  ## FlippedPanel

  FlippedPanel wraps a WantedPanel to indicate that its want can be satisfied by a panel even if its length and width are swapped.

  This allows the user to control whether flipping is allowed of if they care about grain direction.

  When either the original or the flipped panel is finished then its counterpart will be removed from the unsatisfied wants as well.  The function wantsmatch is used for this test.
  """

# ╔═╡ 594a5dc5-77cc-4610-8ae0-2ee54abb1d4b
begin

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
end

# ╔═╡ ecacafd3-5f70-41d9-b6cd-6b4893186b2a
begin
  wanda_box_panels = [
    WantedPanel(length=25u"inch", width=30u"inch", label="back")
    WantedPanel(length=25u"inch", width=22u"inch", label="right side")
    WantedPanel(length=25u"inch", width=22u"inch", label="left side")
    WantedPanel(length=22u"inch", width=30u"inch", label="top")
    WantedPanel(length=22u"inch", width=30u"inch", label="bottom")
  ]
  sort(wanda_box_panels; lt=smaller, rev=true)
end

# ╔═╡ 7e29ad94-89c1-4903-8099-52b258a7a622
begin
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
end

# ╔═╡ adb89a84-5223-42db-90d5-8703b2d9a3b7
md"""
  ## AvailablePanel
  """

# ╔═╡ 5176ae29-b9ac-4c20-82c2-2e054a32eecc
begin
	md"""
  A sheet of plywood we can buy frm the lumber yard.
  """
@Base.kwdef struct AvailablePanel <: AbstractPanel
  uid::Int = panelUID()
  label::String
  width::LengthType
  length::LengthType
  cost::Quantity{N, CURRENCY} where N
end
	
function AvailablePanel(label::String,
			width::LengthType, length::LengthType,
			cost::Quantity{N, CURRENCY} where N)
  AvailablePanel(label=label, width=width, length=length, cost=cost)
end
		
end

# ╔═╡ 4fcb103c-fca4-4bd5-8d55-018bdf73a686
begin
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
end

# ╔═╡ f6a43438-d7b0-442d-bb05-9e4488855665
md"""
  ### Supplier Data

  Taken from boulterplywood.com
  """

# ╔═╡ 65adef2d-9a53-4310-81a0-5dbb6d0918ca
begin    # Supplier Data
  KERF = (1/8)u"inch"
  
  COST_PER_CUT = 1.50u"USD"

  const AVAILABLE_PANELS = [
    AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", 95u"USD"),
    AvailablePanel("5 x 5 x 1/2", 5u"ft", 5u"ft", 49u"USD"),
    AvailablePanel("30 x 60 x 1/2", 30u"inch", 60u"inch", 30u"USD"),
    AvailablePanel("30 x 30 x 1/2", 30u"inch", 30u"inch", 19u"USD")
  ]
end

# ╔═╡ 8f925530-7e76-44f7-9557-64d4629a5e39
md"""
## BoughtPanel

a BoughtPanel is created to wrap an AvailablePanel when we add it to the working set.  This ensured that when it is cut it has a distinct identity from any other BoughtPanel of the same size.
"""

# ╔═╡ 235e25dc-7139-4a24-861b-a0e7451a45eb
begin
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

end

# ╔═╡ 61e200af-6d6a-48c0-98e5-41b98dc2de9c
md"""
  ## Panel

  Panel represents a panel that has been cut from an AvailablePanel but does not yet match an AbstractWantedPanel.
  """

# ╔═╡ 89b2a4cc-de85-41d0-b91d-44600fb39fe6
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
  cost::Quantity{N, CURRENCY} where N

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

# ╔═╡ 41a5afbb-146a-407e-836e-299d80d7c55d
md"""
  ## ScrappedPanel

  ScrappedPanel wraps a Panel that is not big enough to cut any remaining AbstractWantedPanel from.
  """

# ╔═╡ 702afb66-eb60-4d13-84ff-d8eccd9e173c
@Base.kwdef struct ScrappedPanel <: TerminalPanel
  uid::Int = panelUID()
  was::Panel    # We should never be scrapping an AvailablePanel.
end

# ╔═╡ fbc6012e-8893-4634-b632-1609c5a1d23a
# delegations from ScrappedPanel to the Panel we're tagging as too small
begin
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
end

# ╔═╡ 63b95b10-769f-4e8c-ad7f-6f6471155c5c
md"""
  ## FinishedPanel

  FinishedPanel wraps a Panel that matches an AbstractWantedPanel and associates that AbstractWantedPanel with the cut Panel.
  """

# ╔═╡ b264c74c-1470-4a0b-a693-922dd40a1216
begin
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

end

# ╔═╡ 2fd93f59-4101-489f-b540-41d3ca48febf
md"""
  ## Collections of Panels

  Our SearchState objects contain several collections of panels.  We'd like these collections to be immutable, like the SearchStates themselves.

  When transitioning from one SearchState to its possible successor states, these collections could change in the following ways:

  * a WantedPanel and possibly its flipped counterpart, might be removed and a FinishedPanel added
  * one or two CuttablePanels added to stock panels
  * CuttablePanels moved from stock to waste if they are too small for any remaining wanted panels

  Here we implement an immutable collection type Panels based on Tuple to support these operations.
  """

# ╔═╡ 65f4609e-5d6f-4ba6-a941-45c42ac396b4
begin
  Panels{T} = Tuple{Vararg{T}} where T <: AbstractPanel
end

# ╔═╡ a10f122d-fe66-4523-8322-6907481a096f
md"""
## Progenitor
"""

# ╔═╡ 5f83ca7d-aa0d-490c-9b03-122dff375c12
begin
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
	
end

# ╔═╡ a7403050-4bbd-4f0b-9dd7-3dcfa06e43db
# Why we need to add unique ids to all panels:
@assert BoughtPanel(AVAILABLE_PANELS[1]) != BoughtPanel(AVAILABLE_PANELS[1])

# ╔═╡ c63390d5-1e04-44c0-8842-df2b07d8767b
md"""
  ## Testing if Panels Overlap
  """

# ╔═╡ 977fe6fe-a8a0-4498-bf0d-4a6df65a1c85
begin
  struct PanelOverlapError <: Exception
	panel1::AbstractPanel
	panel2::AbstractPanel
	state
	why
  end

  function Base.showerror(io::IO, e::PanelOverlapError)
	print(io, "PanelOverlapError: \n  ", e.panel1, "\n  ", e.panel2)
  end
end

# ╔═╡ e0247c8e-c10f-44f8-af9b-3fd3a0b921ed
# Spans
begin

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
end

# ╔═╡ 9537ad91-fec8-4159-9ed1-3f57174ce7f3
let
	xs1 = XSpan(0, 25)
	xs2 = XSpan(25.125, 30)
	@assert !overlap(xs1, xs2)
end

# ╔═╡ 19b79a97-fc75-480b-bdc6-829ec285d3fe
  let
	s = XSpan(0, 10)
	@assert within(0, s)
	@assert within(10, s)
	@assert within(5, s)
	@assert !within(12, s)
  end

# ╔═╡ 9a3ab7c1-c2c1-4744-8aec-b3e06fcd172c
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

# ╔═╡ b03675d3-327d-4915-9a04-c9c6bbe04924
md"""
  # Cutting
  """

# ╔═╡ ce55a015-792b-41e1-9426-e5a349cf5ec1
"""
    cut(panel, axis, at)::(panel1, panel2)

Cut panel at the specified distance along axis.
The first returned panel is the piece cut to that distance.
The second is what remains (accounting for kerf).

An empty Tuple is returned if the cut can't be made.

# Examples
```jldoctest
julia> panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20u"USD"))
...
julia> panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch")
...
julia> panel2.length == 25u"inch"
true
julia> panel2.width == 30u"inch"
true
julia> panel3.length == panel1.length - panel2.length - KERF
true
julia> panel3.width == 30u"inch"
true
julia panel2.x == panel1.x
true
julia> panel2.y == panel1.y
true
julia> panel3.x == panel1.x + panel2.length + KERF
true
julia> panel3.y == panel1.y
true
``````
"""  
function cut(panel::CuttablePanel,
             axis::Axis,
             at::LengthType)
  if distance(panel, axis) < at
    return (())
  end
  cost = (panel.cost + COST_PER_CUT) / 2
  p2xy = moveby(panel.x, panel.y, axis, at + KERF)
  panel1 = let
    (l, w) = replace0(panel.length, panel.width,
		      moveby(zerozero..., axis, at)...)
    Panel(; length=l, width=w,
          cut_from=panel, cut_at=at, cut_axis=axis,
          x=panel.x, y=panel.y,
	  cost=cost)
  end
  panel2l = panel.length - p2xy[1]
  panel2w = panel.width - p2xy[2]
  if panel2l > 0u"inch" && panel2w > 0u"inch"
    (panel1,
     Panel(length=panel2l, width=panel2w,
           cut_from=panel, cut_at=at, cut_axis=axis,
           x=p2xy[1], y=p2xy[2],
	   cost=cost))
  else
    (panel1,)
  end
end

# ╔═╡ 952a3952-7632-4355-beea-ab064d4b374d
begin
  panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20u"USD"))

  let
	result = cut(panel1, LengthAxis(), 61u"inch")
	@assert result == (())  "$(result) == (())"
  end
  let
	result = length(cut(panel1, LengthAxis(), 29.8u"inch"))
	@assert length(result) == 1  "length($(result)) == 1"
  end
  # Cut panel1 at 25" down LengthAxis:
  panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch")
  @assert panel2.length == 25u"inch"  """got $(panel2.length), expected $(25u"inch")"""
  @assert panel2.width == 30u"inch"
  @assert panel3.length == panel1.length - panel2.length - KERF
  @assert panel3.width == 30u"inch"
  @assert panel2.x == panel1.x   "panel2.x: got $(panel2.x), expected $(panel1.x)"
  @assert panel2.y == panel1.y
  @assert panel3.x == panel1.x + panel2.length + KERF
  @assert panel3.y == panel1.y
	
  # Cut panel2 at 10" down WidthAxis:
  panel4, panel5 = cut(panel2, WidthAxis(), 10u"inch")
  @assert panel4.width == 10u"inch"
  @assert panel4.length == panel2.length
  @assert panel4.x == panel2.x
  @assert panel4.y == panel2.y
  @assert panel5.x == panel2.x
  @assert panel5.y == panel4.y + panel4.width + KERF
  @assert panel5.length == panel2.length
  @assert panel5.width == panel2.width - panel4.width - KERF
end

# ╔═╡ 966f82be-7fdf-44d2-9c9f-3e27c19aef89
begin
  local panel1 = BoughtPanel(AVAILABLE_PANELS[1])
  local at = 22u"inch"
  cut1, cut2 = cut(panel1, LengthAxis(), at)
  @assert cut1.length == at  "got $(cut1.length), expected $(at)"
  @assert cut1.width == panel1.width  "got $(cut1.width), expected $(panel1.width)"
  @assert cut2.width == panel1.width  "got $(cut2.width), expected $(panel1.width)"
  @assert cut2.length == panel1.length - at - KERF "got $(cut2.length), expected $(panel1.length - at - KERF)"
end

# ╔═╡ 1fec8fd3-fc4a-4efc-9d03-16b050c22926
md"""
  # Searching for an optimal cut sequence
  """

# ╔═╡ ed05bfa9-995a-422b-9ccb-215b5535723e
begin
  struct SearchState
    # panels are removed from wanten once they are finished.
    wanted::Panels{AbstractWantedPanel}
    bought::Panels{BoughtPanel}
    finished::Panels{FinishedPanel}
    scrapped::Panels{ScrappedPanel}
    working::Panels{CuttablePanel}
    accumulated_cost::Quantity{N, CURRENCY} where N

    function SearchState(;
                         wanted=Panels{AbstractWantedPanel}([]),
                         bought=Panels{BoughtPanel}([]),
                         finished=Panels{FinishedPanel}([]),
                         scrapped=Panels{ScrappedPanel}([]),
                         working=Panels{CuttablePanel}([]),
                         accumulated_cost=0u"USD")
	  newstate = new(wanted, bought, finished, scrapped, working, accumulated_cost)
	  panels = AllOf(finished, scrapped, working)
	  for i in 1:length(panels)
		for j in i+1:length(panels)
		  errIfOverlap(panels[i], panels[j], newstate)
		end
	  end
      return newstate
    end
  end
  
  # Constructor for the initial search state:
  function SearchState(want::Vector{<:AbstractWantedPanel})
    SearchState(; wanted=Panels{AbstractWantedPanel}(sort(want;
					                  lt=smaller, rev=true)))
  end
  
  # A constructor for successor states that enforces critical invariants
  function SearchState(precursor::SearchState, cost,
		       finished::Union{Nothing, FinishedPanel},
                       used::Union{Nothing, CuttablePanel},
		       offcuts::CuttablePanel...)
	newly_bought = filter(x -> x isa BoughtPanel, offcuts)
	bought = if length(newly_bought) == 0
		precursor.bought
	else
		Panels{BoughtPanel}([precursor.bought..., newly_bought...])
	end
    wanted = if finished == nothing
      precursor.wanted
    else
      filter(precursor.wanted) do w
		!wantsmatch(w, finished.wanted)
      end
    end
    newlyscrapped=[]
    working=[]
    for p in [offcuts...,
              precursor.working...]
      if p == used
        continue
      end
      if any((w) -> fitsin(w, p), wanted)
	push!(working, p)
      else
	push!(newlyscrapped, ScrappedPanel(was=p))
      end
    end
    state = SearchState(;
		        wanted=wanted,
		        bought=bought,
		        finished=if finished == nothing
                          precursor.finished
                        else
                          Panels{FinishedPanel}(
			    union((finished,),
				  precursor.finished))
                        end,
		        scrapped=Panels{ScrappedPanel}(
			  union(newlyscrapped, precursor.scrapped)),
		        working=Panels{CuttablePanel}(working),
		        accumulated_cost=precursor.accumulated_cost + cost)
    # println("precursor: ", precursor, "\n      new: ", state)
    return state
  end
  
  function doneness(state::SearchState)::Real
    a = (x) -> reduce(+, area.(x); init=0u"inch^2")
    finished = a(state.finished)
    return finished / (finished + a(state.wanted))
  end
end

# ╔═╡ 042388f8-d557-4e9c-b9a8-71865563ffac


# ╔═╡ fc065401-50dc-4a21-98ad-b2ecd003d397
SearchState(; wanted=Panels{AbstractWantedPanel}(sort(wanda_box_panels; by=major)))

# ╔═╡ c72bb206-c7c6-4be6-8b92-446540edbea2
md"""
  ## Priority

  For A* Search we need to assign a priority to each state in the state space we are searching through.  A SearchState with **lower** priority will be considered **ahead** of one with hjigher priority.
  """

# ╔═╡ 77b32e0e-fb41-4a2a-8b1d-a272e4a1dd60
SearchPriority = Real

# ╔═╡ 81ffb853-ba0a-4513-b4e1-21f5c2327dc9
function priority(state::SearchState)::SearchPriority
  # Priority should get worse as the cost increases but should get better
  # as we approach completion.
  (1 - doneness(state)) * ustrip(Real, u"USD", state.accumulated_cost)
end

# ╔═╡ d90e2c72-9fdb-4f9e-94c8-7b211d2b16e3
md"""
  ## Searching

  This Searcher implements A* search using a PriorityQueue.

  One could implement other searchers to implement, for example, depth or breadth first search.
  """

# ╔═╡ 7b64474a-bbb1-4bc2-8f87-a35e4b168545
mutable struct Searcher
  available_stock::Vector{AvailablePanel}
  wanted::Vector{<:AbstractWantedPanel}
  states::PriorityQueue{SearchState, SearchPriority}
  finished_states::Set{SearchState}
  cheapest::Union{SearchState, Nothing}
  # For debugging:
  considered_states::Vector{SearchState}
  
  function Searcher(want::Vector{<:AbstractWantedPanel};
                    available=AVAILABLE_PANELS)
    initial_state = SearchState(want)
    new(available, uniqueWantedPanels(want),
        PriorityQueue{SearchState, SearchPriority}(
          initial_state => priority(initial_state)),
        Set{SearchState}(),
	nothing,
	Vector{SearchState}())
  end
end

# ╔═╡ 137932b7-b914-47f0-b355-2406c7dfe4a4
function enqueue(searcher::Searcher, state::Union{SearchState, Nothing})::Nothing
  if state == Nothing
    return nothing
  end
  if isempty(state.wanted)
    push!(searcher.finished_states, state)
    if searcher.cheapest == nothing
      searcher.cheapest = state
    elseif state.accumulated_cost < searcher.cheapest.accumulated_cost
      searcher.cheapest = state
    end
  else
    enqueue!(searcher.states, state => priority(state))
  end
  nothing
end

# ╔═╡ 4e51fc12-7f05-49e2-b55a-7d91c47dd185
function progress(searcher::Searcher, state::SearchState)::Nothing
    if searcher.cheapest != nothing &&
        searcher.cheapest.accumulated_cost <= state.accumulated_cost
        # No improvement possible.  Prune this search branch:
        return nothing
    end
    push!(searcher.considered_states, state)
    if isempty(state.wanted)
        return nothing
    end
    if isempty(state.working)
        for p in searcher.available_stock
            if any((w) -> fitsin(w, p), state.wanted)
	        enqueue(searcher,
		        SearchState(state, p.cost, nothing, nothing, BoughtPanel(p)))
            end
        end
        return nothing
    end
    # Try cutting the first wanted panel from each of the working panels
    function cutWanted(wanted)
        for working in state.working
            if !fitsin(wanted, working)
                continue
            end
            for axis_ in subtypes(Axis)
                axis = axis_()
                cuts = cut(working, axis, distance(wanted, axis))
                if length(cuts) == 0
	            continue
                end
                @assert distance(cuts[1], axis) == distance(wanted, axis)
                if distance(cuts[1], other(axis)) == distance(wanted, other(axis))
	            enqueue(searcher, SearchState(state, COST_PER_CUT,
				                  FinishedPanel(cuts[1], wanted),
                                                  working,
						  cuts[2:end]...))
	            continue
                end
                cuts2 = cut(cuts[1], other(axis), distance(wanted, other(axis)))
                if length(cuts2) == 0
	            continue
                end
                @assert distance(cuts2[1], other(axis)) == distance(wanted, other(axis))
                enqueue(searcher, SearchState(state, 2 * COST_PER_CUT,
				              FinishedPanel(cuts2[1], wanted),
                                              working,
					      cuts[2:end]..., cuts2[2:end]...))
            end
        end
        return nothing
    end
    wanted = state.wanted[1]
    # For FlippedPanel we consider both the flipped and original shapes:
    if wanted isa FlippedPanel
        cutWanted(wanted.was)
    end
    cutWanted(wanted)
end

# ╔═╡ 5aac7456-b32f-40e8-a015-fcbea6f638ff
function run(searcher::Searcher)
  while !isempty(searcher.states)
    s = dequeue!(searcher.states)
    progress(searcher, s)
  end
end

# ╔═╡ 673904ce-42d2-44d8-93c4-cdc59d1e9392
function allstates(searcher::Searcher)
	union(searcher.finished_states,
	      keys(searcher.states))
end

# ╔═╡ df84b1ad-cbd5-4f7b-a37e-30534b17adcf
md"""
# Reverse Graph

AbstractPanels are related to one another through a directed graph
based on various relations.  Here we construct the inverse directed graph,
which could be one-to-many, as a Dict.
"""

# ╔═╡ 148e3f7f-4ac6-4e57-be5d-fb4082bf1154
begin
	struct ReversePanelGraph
		arcs::Set{Pair}
	
		ReversePanelGraph() = new(Set{Pair{AbstractPanel, AbstractPanel}}())
	end
	
	function Base.haskey(rpg::ReversePanelGraph, key)::Bool
		for p in rpg.arcs
			if p.first == key
				return true
			end
		end
		return false
	end

	Base.keys(rpg::ReversePanelGraph) =
		Set([p.first for p in rpg.arcs])

	Base.values(rpg::ReversePanelGraph) =
		Set([p.second for p in rpg.arcs])
	
	nodes(rpg::ReversePanelGraph) = union(keys(rpg), values(rpg))
	
	arcs(rpg::ReversePanelGraph) = rpg.arcs

	Base.getindex(rpg::ReversePanelGraph, key) =
		(p -> p.second).(filter(p -> p.first == key, rpg.arcs))

	havingKey(rpg::ReversePanelGraph, key) =
		filter(p -> p.first == key, rpg.arcs)
	
	havingValue(rpg::ReversePanelGraph, value) =
		filter(p -> p.second == value, rpg.arcs)

	function injest(rpg::ReversePanelGraph, panel::AbstractPanel)
	end

	function injest(rpg::ReversePanelGraph, panel::BoughtPanel)
	  push!(rpg.arcs, (panel.was) => panel)
	  injest(rpg, panel.was)
	end

	function injest(rpg::ReversePanelGraph, panel::TerminalPanel)
		push!(rpg.arcs, (panel.was) => panel)
		injest(rpg, panel.was)
	end

	function injest(rpg::ReversePanelGraph, panel::Panel)
		push!(rpg.arcs, (panel.cut_from) => panel)
		injest(rpg, panel.cut_from)
	end

	function makeReversePanelGraph(state::SearchState)::ReversePanelGraph
		rpg = ReversePanelGraph()
		for f in state.finished
			injest(rpg, f)
		end
		for s in state.scrapped
			injest(rpg, s)
		end
		return rpg
	end

	function transform!(rpg::ReversePanelGraph, addarcs, removearcs)
		setdiff!(rpg.arcs, removearcs)
		union!(rpg.arcs, addarcs)
		return nothing
	end

	function applyRule!(rpg::ReversePanelGraph, rule)
	  nodes(rpg) .|>
		(node -> rule(rpg, node)) .|>
		(ar -> transform!(rpg, ar...))
	end
end

# ╔═╡ 85f95152-93a2-42cd-80f3-c3d7d931dbfe
md"""
# Describing the Cuts using SVG
"""

# ╔═╡ 2e1e9fc8-6209-4968-bf7e-fa97b72ebef3
const STYLESHEET = """
  g.everything {
  }
  g.everything * { 
    vector-effect: non-scaling-stroke;
  }
  .cut {
    stroke-width: 1px;
    stroke: rgb(0%,50%, 50%);
    stroke-dasharray: 4 4;
  }
  .factory-edge {
    stroke-width: 1px; stroke: blue;
    fill: none;
  }
  .finished {
    stroke: none;
    fill: rgba(0%, 50%, 0%, 50%);
  }
  text.finished {
	color: white;
    text-anchor: middle;
	font-family: sans-serif;
    font-size: 2px;
	vector-effect: non-scaling-stroke;
  }
"""

# ╔═╡ 134ac318-adb5-4939-96f7-3b70b12ffe43
#=
macro thismodule()
	:($__module__)
end
=#

# ╔═╡ d5b1c891-9529-4876-839f-cddd94d3d800
#= this macro does not play well with Pluto notebooks

begin
	# Abstract measurements in svg user space from the dimensions we use
	# for measuring panels:
	@Unitful.unit svgd "svgd" SVGDistance 0.01u"inch" false
	Unitful.register(@thismodule)
end
=#

# ╔═╡ 9d0fb461-46e4-4436-a367-5cdf3406474f
"""
turn a Unitful length quantity to a floating point number we can use in SVG.
"""
function svgdistance(d)::Real
	ustrip(Real, u"inch", d)
end

# ╔═╡ c2a34850-17eb-43ca-b6c1-262dc67d6006
function panelrect(io::IO, panel::AbstractPanel, cssclass::String)
	# It's confusing that panel.width corresponds to SVG length
	# and panel.length corresponds to SVG width.  Sorry.
	# This is a consequence of the x and y coordinaces of a panel
	# corresponding with the panel's length and width respectively.
	g(io) do
		write(io, string("<!-- $(panel.label): ",
				 "$(panel.width) by $(panel.length), ",
				 "at $(panel.x), $(panel.y) -->\n"))
		rect(io; class=cssclass,
			 x=svgdistance(panel.x),
			 y=svgdistance(panel.y),
			 width=svgdistance(panel.length),
			 height=svgdistance(panel.width)) do
		  if panel isa FinishedPanel
		    title(io) do
			  print(io, "$(panel.length) × $(panel.width)")
		    end
		  end
		end
		if panel isa FinishedPanel
		  NativeSVG.text(io;
				class = cssclass,
				x = svgdistance(panel.x + panel.length / 2),
				y = svgdistance(panel.y + panel.width / 2)) do
			write(io, "$(panel.length) × $(panel.width)")
		  end
		end

	end
end

# ╔═╡ 099be731-dd16-4f56-af53-269e38ada04b
# Space between panels in an SVG drawing, and space between panels and SVG edge.
const SVG_PANEL_MARGIN = 2u"inch"

# ╔═╡ 495229d3-c8f8-4410-be90-3737655207ce
function toSVG(state::SearchState)
  buf = IOBuffer()
  toSVG(buf, state)
  return take!(buf)
end

# ╔═╡ bcbcf050-ee5f-4531-b432-7e2006fccc1e
function toSVG(io::IO, state::SearchState)::Nothing
	rpg = makeReversePanelGraph(state)
	write(io, """<?xml version="1.0" encoding="UTF-8"?>\n""")
	write(io, """<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"\n""")
	write(io, """          "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n""")
	# Outermost SVG:
	vpwidth = svgdistance(maximum(major.(keys(rpg))) + 2 * SVG_PANEL_MARGIN)
	vpheight = svgdistance(sum(minor.(filter(p -> p isa BoughtPanel, keys(rpg)))) + 
		2 * SVG_PANEL_MARGIN)
	svg(io; xmlns="http://www.w3.org/2000/svg",
		width="90%",
		viewBox="0 0 $(vpwidth) $(vpheight)",
		style="background-color: pink") do
		style(io; type="text/css") do
		  write(io, STYLESHEET)
		end
		g(io; class="everything") do
			y = SVG_PANEL_MARGIN
			for stock in filter((p) -> p isa BoughtPanel, keys(rpg))
				# We want to have the longer dimension of panel run
				# horizontally.  If so, we can apply a 90 degree rotation.
				# Here we just translate successive stock panels (BoughtPanel)
				# by its minor dimension and margins to space them out.
				# The toSVG method of BoughtPanel will deal with rotation.
				tx = svgdistance(SVG_PANEL_MARGIN)
				ty = svgdistance(y)
				g(io; transform="translate($(tx), $(ty))") do
					toSVG(io, stock, rpg)
					y += minor(stock) + SVG_PANEL_MARGIN
				end
			end
		end
	end
end

# ╔═╡ ffe9f05a-4348-4967-ba9d-5b0cc57dd70b
function toSVG(io::IO, panel::AbstractPanel, rpg::ReversePanelGraph)::Nothing
end

# ╔═╡ 738201a6-b769-4586-81cd-c8e73c9a6ad9
function toSVG(io::IO, panel::BoughtPanel, rpg::ReversePanelGraph)::Nothing
	# We want to have the longer dimension of panel run horizontally.
	# This is already anticipated above wnere we calculate the SVG viewBox.
	transform = ""
	if panel.length != major(panel)
		tx = svgdistance(0u"inch")
		ty = svgdistance(panel.width)
		transform = "rotate(90) translate($tx $ty)"
	end
	g(io; class="BoughtPanel",
		  transform=transform) do
		panelrect(io, panel, "factory-edge")
		for p in rpg[panel]
			toSVG(io, p, rpg)
		end
	end
end

# ╔═╡ deb5d973-3fb6-48c9-87da-ed50eb4cd33d
function toSVG(io::IO, panel::Panel, rpg::ReversePanelGraph)::Nothing
	g(io; class="Panel") do
		for p in rpg[panel]
			toSVG(io, p, rpg)
		end
		endX = panel.x + panel.length
		endY = panel.y + panel.width
		if panel.cut_axis isa LengthAxis
			startX = endX
			startY = panel.y
		else
			startX = panel.x
			startY = endY
		end
		startX, startY, endX, endY = svgdistance.((startX, startY, endX, endY))
		d = "M $startX $startY L $endX $endY"
		NativeSVG.path(io; class="cut", d=d)
	end
end

# ╔═╡ c90350c2-9c91-43df-b7ed-2ed77f960e6d
function toSVG(io::IO, panel::FinishedPanel, rpg::ReversePanelGraph)::Nothing
	g(io; class="FinishedPanel") do
		panelrect(io, panel, "finished")
	end
end

# ╔═╡ 4cd74059-f59b-46e4-be23-bfbd95e4d96d
md"""
# Generic Dot Code
"""

# ╔═╡ dcbc9193-fa7a-435b-8f68-05b77e1d9b36
md"""
# Panel Progression Graph

A GraphViz graph that describes what panels are cut from what other panels.
"""

# ╔═╡ bd178f5d-7701-4a09-ba6d-0b80712bc3e2
begin
	# This graph just shows panels by their types and uids and
	# the relationships between them,
	function dotgraph(io::IO, state::SearchState)::Nothing
		rpg = makeReversePanelGraph(state)
		dotgraph(io, rpg)
		return
	end

end

# ╔═╡ 6bafdc76-dd65-47a6-9c34-90353408c488
md"""
# Panel Cut Graph

The Panel Cut Graph is limited to describing starting and ending panels and the cuts that are made.  Irrelevant panels are elided.
"""

# ╔═╡ b879cd1d-938a-4839-9c00-20d989ff5d45
begin

  struct NonlocalTransfer <: Exception
    uid

    function NonlocalTransfer()
      new(UUIDs.uuid1())
    end
  end

  function Base.showerror(io::IO, e::NonlocalTransfer)
    print(io, "NonlocalTransfer not caught!")
  end

  function transformingGraph(f)
	addset = Set()
	removeset = Set()
	exittag = NonlocalTransfer()
	add(arc) = push!(addset, arc)
	remove(arc) = push!(removeset, arc)
	function check(condition)
	  if !condition
		throw(exittag)
	  end
	end
	try
	  f(check, add, remove)
	catch e
	  if e != exittag
		rethrow(e)
	  end
	end
	return addset, removeset
  end

end

# ╔═╡ 7408dbb2-f396-4e8f-9686-d7ac1a522647
begin
  struct PanelCutGraph
    state::SearchState
    rpg::ReversePanelGraph

    function PanelCutGraph(state::SearchState)
      pcg = new(state, makeReversePanelGraph(state))
	  applyRule!(pcg.rpg, addCutNodes)
	  applyRule!(pcg.rpg, elideTerminalPanels)
	  applyRule!(pcg.rpg, elideBoughtPanels)
      pcg
    end
  end

  arcs(pcg::PanelCutGraph) = arcs(pcg.rpg)

  nodes(pcg::PanelCutGraph) = nodes(pcg.rpg)

  struct CutNode
    panel1::Panel
    panel2::Panel
  end

  function dotID(n::CutNode)
    return "CutNode_$(n.panel1.cut_from.uid)"
  end

  function dotnode(io::IO, pcg::PanelCutGraph, n::CutNode)
    write(io, """  "$(dotID(n))"[shape=pentagon; label="$(dotnodelabel(pcg, n))"]\n""")
    return n
  end

  function dotnodelabel(pcg::PanelCutGraph, n::CutNode)::String
    from = if n.panel1.cut_axis isa LengthAxis
      "from end"
    elseif n.panel1.cut_axis isa WidthAxis
      "from side"
    end
    return "cut $(n.panel1.cut_at) $(from)"
  end
	
  md"""
  Compute the arguments to transform! in order to insert a
  CutNode wherever a panel is cut.
  """
  function addCutNodes(rpg::ReversePanelGraph, key)
	transformingGraph() do check, add, remove
	  check(isa(key, CuttablePanel))
	  arcs = havingKey(rpg, key)
	  check(length(arcs) == 2)
	  arc1, arc2 = Tuple(arcs)
	  check(arc1.second isa Panel)
	  check(arc2.second isa Panel)
	  check(key == arc1.second.cut_from)
	  check(key == arc2.second.cut_from)
      cutnode = CutNode(arc1.second, arc2.second)
      add(key => cutnode)
      remove(arc1)
      remove(arc2)
      add(cutnode => cutnode.panel1)
      add(cutnode => cutnode.panel2)
	end
  end

  md"""
  Compute the arguments to transform! in order to elide a Panel that is
  succeeded by a TerminalPanel.
  
  """
  function elideTerminalPanels(rpg::ReversePanelGraph, terminal)
    transformingGraph() do check, add, remove
      check(terminal isa TerminalPanel)
      arcs2 = havingValue(rpg, terminal)
      check(length(arcs2) == 1)
	  arc2 = first(arcs2)
      panel = arc2.first
      check(panel isa Panel)
      arcs1 = havingValue(rpg, panel)
      check(length(arcs1) == 1)
	  arc1 = first(arcs1)
      precursor = arc1.first
      add(precursor => terminal)
      remove(arc1)
      remove(arc2)
    end
  end

  md"""
  Compute the arguments to transform! to elide BoughtPanels.
	"""
  function elideBoughtPanels(rpg::ReversePanelGraph, bought)
	transformingGraph() do check, add, remove
	  check(bought isa BoughtPanel)
	  arcs1 = havingValue(rpg, bought)
	  check(length(arcs1) == 1)
	  arc1 = first(arcs1)
	  check(arc1.first isa AvailablePanel)
	  arcs2 = havingKey(rpg, bought)
	  check(length(arcs2) == 1)
	  arc2 = first(arcs2)
	  remove(arc1)
	  remove(arc2)
	  add(arc1.first => arc2.second)
	end
  end

  function dotnodelabel(graph::PanelCutGraph, panel::BoughtPanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnodelabel(graph::PanelCutGraph, panel::AvailablePanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnodelabel(graph::PanelCutGraph, panel::FinishedPanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
					"$(panel.label)",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "x: $(panel.x)",
                    "y: $(panel.y)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnodelabel(graph::PanelCutGraph, panel::AbstractPanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "x: $(panel.x)",
                    "y: $(panel.y)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnode(io::IO, graph::PanelCutGraph, panel::AbstractPanel)
    write(io, """  "$(dotID(panel))"[shape=record; label="$(dotnodelabel(graph, panel))"]\n""")
  end

end

# ╔═╡ f89c8f2e-8bdf-4d4e-8090-3f6a56e0ce85
begin
	
  md"""
	Write a GraphViz dot file describing the panel cutting progression
	described in a SearchState.
	"""
  function dotgraph end

  function rundot(path)
	Base.run(`dot -Tsvg -O $path`)
  end

  function dotgraph(path::String, graph)
    open(path, "w") do io
      dotgraph(io, graph)
    end
    return path
  end
  
  function dotgraph(io::IO, graph)
    write(io, "digraph panels {\n")
    for node in nodes(graph)
      dotnode(io, graph, node)
    end
    for arc in arcs(graph)
      diarc(io, graph, arc.first, arc.second)
    end
	write(io, "}\n")
  end

  function dotnode(io::IO, graph, node)
	write(io, """  "$(dotID(node))"\n""")
  end

  function diarc(io::IO, graph, arc::Pair)
    diarc(io, graph, arc.from, arc.to)
  end

  function diarc(io::IO, graph, from, to)
    write(io, """  "$(dotID(from))" -> "$(dotID(to))"\n""")
  end
	
  function dotID(panel::AbstractPanel)
	t = split(string(typeof(panel)), ".")[end]
 	"$(t)_$(string(panel.uid))"
  end

end

# ╔═╡ 75012d46-535c-4d51-9948-f3c611c7a72c
md"""
# Plots
"""

# ╔═╡ 9b16e856-dd32-400c-833a-cc2a3db5bf92
function plot_doneness_to_cost(searcher::Searcher)
  as = allstates(searcher)
  costs = (s -> s.accumulated_cost).(as)
  costs = (c -> ustrip(Real, u"USD", c)).(costs)
  done = doneness.(as)
  scatter(costs, done)
end

# ╔═╡ 1ea2113a-27f1-427a-a78e-23ef4bf52b33
md"""
# Report

Generate an HTML fragment that provides a detailed report of our cut search and results.
"""

# ╔═╡ 0d804f8e-838a-49a0-983e-d517d7588f56
cat = `"c:/Program Files/Git/usr/bin/cat.exe"`

# ╔═╡ 2883b685-b394-408f-b1ec-eb4804ead5f8
"""
    runCmd(cmd::Cmd, cmdOutput::IO)::IO
Run the external command `cmd`, which will write output to `cmdOutput`.
The stream that's returns can be written to to provide inoput to the
command.  The second return value is the stderr stream.
"""
function runCmd(cmd::Cmd, cmdOutput::IO)
	cmdInput = Pipe()
	err = Pipe()
	proc = Base.run(pipeline(cmd,
			stdin=cmdInput,
			stdout=cmdOutput,
			stderr=err),
		wait=false)
	process_running(proc) || throw(Exception("Problem starting $cmd"))
	close(cmdInput.out)
	close(err.in)
	return cmdInput, err
end

# ╔═╡ f8b1780e-9614-4414-93e1-205233d3fb16
function report(searcher::Searcher;
                includeCutDiagram=true,
                includeCutGraph=true)
    io = IOBuffer()
    function elt(f, io, tagname; attrs...)
        NativeSVG.element(f, tagname, io; attrs...)
    end
    elt(io, :div) do
        elt(io, :h2) do
            write(io, "Panel Cut Report")
        end
        elt(io, :p) do
            write(io, "Report of what stock to purchase and what" *
                " cuts to make to get panels of these aizes")
        end
        function th(io, heading)
            elt(io, :th) do
                write(io, heading)
            end
        end
        function td(io, val; attrs...)
            elt(io, :td; attrs...) do
		if val isa String
		    write(io, val)
		else
                    show(io, val)
		end
            end
        end
	# Table of wanted panels:
        elt(io, :table) do
            elt(io, :thread) do
                elt(io, :tr) do
                    for heading in ("Label", "Length", "Width", "Ok to Flip?")
                        th(io, heading)
                    end
                end
            end
            elt(io, :tbody) do
                for panel in searcher.wanted
                    elt(io, :tr) do
                        td(io, panel.label; align="center")
                        td(io, panel.length; align="right")
                        td(io, panel.width; align="right")
                        td(io, if panel isa FlippedPanel
                               "yes"
                           else
                               "no"
			   end;
			   align="center")
                    end
                end
            end
        end
        elt(io, :p) do
            write(io, "The best solution has a cost of " *
                "$(searcher.cheapest.accumulated_cost).")
        end
        # Table of panel areas
        elt(io, :div) do
            elt(io, :table) do
                elt(io, :thread) do
                    elt(io, :tr) do
                        th(io, "Panel")
                        th(io, "Area")
                        th(io, "%")
                    end
                end
                elt(io, :tbody) do
                    bought_area = sum(area.(searcher.cheapest.bought))
                    function panel_group(panels)
                        for p in panels
                            elt(io, :tr; style=style) do
                                td(io, p.label; align="center")
                                td(io, area(p); align="right")
                                td(io, @sprintf("%.2f%%",
						100 * area(p)/bought_area);
				   align="right")
                                if p == panels[1]
				    frac = sum(area.(panels)) / bought_area
				    td(io, @sprintf("%.2f%%", 100 * frac);
				       rowspan=length(panels),
				       valign="top",
				       align="right")
                                end
                            end
                        end
                    end
                    panel_group(searcher.cheapest.bought)
                    panel_group(searcher.cheapest.scrapped)
                    panel_group(searcher.cheapest.finished)
                end
            end
        end
        if includeCutDiagram
            toSVG(io, searcher.cheapest)
        end
        if includeCutGraph
            elt(io, :div) do
                dot, err = runCmd(`dot -Tsvg`, io)
                dotgraph(dot, PanelCutGraph(searcher.cheapest))
                close(dot)
                err = read(err)
                if length(err) > 0
                    throw(Exception("Error running dot: $err"))
                end
            end
        end
    end
    return HTML(String(take!(io)))
end

# ╔═╡ 58cd80ab-5a98-4b34-9bc2-a414d766a486
md"""
# Examples / Testing
"""

# ╔═╡ e3f1b65c-1bb2-44ee-bbec-8bda4e1ae6c3
let
	p1, p2 = cut(BoughtPanel(AVAILABLE_PANELS[1]), LengthAxis(), 10u"inch")
	fp = FinishedPanel(p1, WantedPanel(length=10u"inch", width=p1.width, label="foo"))
	sp = ScrappedPanel(was=p2)
	rpg = ReversePanelGraph()
	injest(rpg, fp)
	injest(rpg, sp)
	nodes(rpg) .|> (key -> (elideTerminalPanels(rpg, key)))
end

# ╔═╡ c5f24393-4c92-4dcf-8a14-8f81c03cc2f0
md"""
## Two Panels From One Sheet of Stock
"""

# ╔═╡ 4a9ebc9b-b91c-4ff6-ba55-2c32093044be
let
  searcher = Searcher(wanda_box_panels[1:2])
  run(searcher)
  report(searcher)
end

# ╔═╡ 40eda0d7-3871-48d6-9976-e9dd7829265d
md"""
## Panels for a Complete Five Sided Box
"""

# ╔═╡ aeaa6940-4f97-4286-97d4-7ad6dc6013b1
let
	searcher = Searcher(wanda_box_panels)
	run(searcher)
	@assert length(searcher.cheapest.finished) == length(wanda_box_panels)
	report(searcher)
end

# ╔═╡ a968cf5a-bed4-4939-980f-86e90903b756
md"""
## A Complete Box Allowing Flipping
"""

# ╔═╡ 81b8240b-e3c0-427d-b57a-b07e52963f15
let
	searcher = Searcher(flipped.(wanda_box_panels))
	run(searcher)
	report(searcher)
end

# ╔═╡ 2d6b3e56-0858-4b7a-9bd7-5d5fa2b835c9
md"""
# allsubtypes
"""

# ╔═╡ 97d24eee-024e-4079-948a-49245fd3c734
function allsubtypes(t, result=Set())
	push!(result, t)
	for t1 in subtypes(t)
		allsubtypes(t1, result)
	end
	return result
end

# ╔═╡ 52956b53-22a2-47c2-bb8d-d70ea63dcff6
allsubtypes(AbstractPanel)

# ╔═╡ 70685b9d-b660-4443-ae7f-a0659456dc4f
md"""
  # Experiments
  """

# ╔═╡ bb38f4c1-4443-4b33-a526-b5cc653f437b
+(area.(Set(wanda_box_panels))...)

# ╔═╡ 2b814578-5137-4805-bedf-2c7759d87048
typeof(20u"USD")

# ╔═╡ 7e368048-6a64-4439-8114-493f7f45ddfd
20u"USD" isa Quantity{N, CURRENCY} where N

# ╔═╡ 4049d967-f932-4eec-b6fc-711a5df79531
zero(Quantity{Real, CURRENCY})

# ╔═╡ Cell order:
# ╠═b019d660-9f77-11eb-1527-278a3e1b087c
# ╠═5f5c5ef3-efed-4afd-b304-5b37a9a81bd2
# ╟─60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
# ╠═1871abc7-d4cb-4ebd-862e-660a9ce5dc56
# ╠═60fdb133-5d21-4445-90f9-3bbe49fb743b
# ╟─5be6a7bd-b97c-4b97-ab47-9d83b3a2dd77
# ╟─6835fdd3-eead-4d2b-81ce-a05df4f57499
# ╟─1292709e-63f9-4f9f-a6c0-0e9068a4c6b6
# ╠═98a48a7c-51e9-46f9-bdb4-e6a6b8380061
# ╟─29c94131-5b13-4588-a772-d517198d2163
# ╠═34bab1fd-ecdc-4054-8c69-5325ae807e1f
# ╟─7c51768d-f376-487c-a88d-f795fb01da48
# ╠═594a5dc5-77cc-4610-8ae0-2ee54abb1d4b
# ╠═ecacafd3-5f70-41d9-b6cd-6b4893186b2a
# ╠═7e29ad94-89c1-4903-8099-52b258a7a622
# ╟─adb89a84-5223-42db-90d5-8703b2d9a3b7
# ╠═5176ae29-b9ac-4c20-82c2-2e054a32eecc
# ╠═4fcb103c-fca4-4bd5-8d55-018bdf73a686
# ╟─f6a43438-d7b0-442d-bb05-9e4488855665
# ╠═65adef2d-9a53-4310-81a0-5dbb6d0918ca
# ╟─8f925530-7e76-44f7-9557-64d4629a5e39
# ╠═235e25dc-7139-4a24-861b-a0e7451a45eb
# ╟─61e200af-6d6a-48c0-98e5-41b98dc2de9c
# ╠═89b2a4cc-de85-41d0-b91d-44600fb39fe6
# ╟─41a5afbb-146a-407e-836e-299d80d7c55d
# ╠═702afb66-eb60-4d13-84ff-d8eccd9e173c
# ╠═fbc6012e-8893-4634-b632-1609c5a1d23a
# ╟─63b95b10-769f-4e8c-ad7f-6f6471155c5c
# ╠═b264c74c-1470-4a0b-a693-922dd40a1216
# ╟─2fd93f59-4101-489f-b540-41d3ca48febf
# ╠═65f4609e-5d6f-4ba6-a941-45c42ac396b4
# ╟─a10f122d-fe66-4523-8322-6907481a096f
# ╠═5f83ca7d-aa0d-490c-9b03-122dff375c12
# ╠═a7403050-4bbd-4f0b-9dd7-3dcfa06e43db
# ╟─c63390d5-1e04-44c0-8842-df2b07d8767b
# ╠═977fe6fe-a8a0-4498-bf0d-4a6df65a1c85
# ╠═e0247c8e-c10f-44f8-af9b-3fd3a0b921ed
# ╠═9537ad91-fec8-4159-9ed1-3f57174ce7f3
# ╠═19b79a97-fc75-480b-bdc6-829ec285d3fe
# ╠═9a3ab7c1-c2c1-4744-8aec-b3e06fcd172c
# ╟─b03675d3-327d-4915-9a04-c9c6bbe04924
# ╠═ce55a015-792b-41e1-9426-e5a349cf5ec1
# ╠═952a3952-7632-4355-beea-ab064d4b374d
# ╟─966f82be-7fdf-44d2-9c9f-3e27c19aef89
# ╟─1fec8fd3-fc4a-4efc-9d03-16b050c22926
# ╠═ed05bfa9-995a-422b-9ccb-215b5535723e
# ╠═042388f8-d557-4e9c-b9a8-71865563ffac
# ╠═fc065401-50dc-4a21-98ad-b2ecd003d397
# ╟─c72bb206-c7c6-4be6-8b92-446540edbea2
# ╟─77b32e0e-fb41-4a2a-8b1d-a272e4a1dd60
# ╠═81ffb853-ba0a-4513-b4e1-21f5c2327dc9
# ╟─d90e2c72-9fdb-4f9e-94c8-7b211d2b16e3
# ╠═7b64474a-bbb1-4bc2-8f87-a35e4b168545
# ╠═137932b7-b914-47f0-b355-2406c7dfe4a4
# ╠═5aac7456-b32f-40e8-a015-fcbea6f638ff
# ╠═4e51fc12-7f05-49e2-b55a-7d91c47dd185
# ╠═673904ce-42d2-44d8-93c4-cdc59d1e9392
# ╟─df84b1ad-cbd5-4f7b-a37e-30534b17adcf
# ╠═148e3f7f-4ac6-4e57-be5d-fb4082bf1154
# ╟─85f95152-93a2-42cd-80f3-c3d7d931dbfe
# ╠═2e1e9fc8-6209-4968-bf7e-fa97b72ebef3
# ╟─134ac318-adb5-4939-96f7-3b70b12ffe43
# ╠═d5b1c891-9529-4876-839f-cddd94d3d800
# ╠═9d0fb461-46e4-4436-a367-5cdf3406474f
# ╠═c2a34850-17eb-43ca-b6c1-262dc67d6006
# ╠═099be731-dd16-4f56-af53-269e38ada04b
# ╠═495229d3-c8f8-4410-be90-3737655207ce
# ╠═bcbcf050-ee5f-4531-b432-7e2006fccc1e
# ╠═ffe9f05a-4348-4967-ba9d-5b0cc57dd70b
# ╠═738201a6-b769-4586-81cd-c8e73c9a6ad9
# ╠═deb5d973-3fb6-48c9-87da-ed50eb4cd33d
# ╠═c90350c2-9c91-43df-b7ed-2ed77f960e6d
# ╟─4cd74059-f59b-46e4-be23-bfbd95e4d96d
# ╠═f89c8f2e-8bdf-4d4e-8090-3f6a56e0ce85
# ╟─dcbc9193-fa7a-435b-8f68-05b77e1d9b36
# ╠═bd178f5d-7701-4a09-ba6d-0b80712bc3e2
# ╟─6bafdc76-dd65-47a6-9c34-90353408c488
# ╠═b879cd1d-938a-4839-9c00-20d989ff5d45
# ╠═7408dbb2-f396-4e8f-9686-d7ac1a522647
# ╟─75012d46-535c-4d51-9948-f3c611c7a72c
# ╠═9b16e856-dd32-400c-833a-cc2a3db5bf92
# ╟─1ea2113a-27f1-427a-a78e-23ef4bf52b33
# ╠═f8b1780e-9614-4414-93e1-205233d3fb16
# ╠═0d804f8e-838a-49a0-983e-d517d7588f56
# ╠═2883b685-b394-408f-b1ec-eb4804ead5f8
# ╟─58cd80ab-5a98-4b34-9bc2-a414d766a486
# ╠═e3f1b65c-1bb2-44ee-bbec-8bda4e1ae6c3
# ╟─c5f24393-4c92-4dcf-8a14-8f81c03cc2f0
# ╠═4a9ebc9b-b91c-4ff6-ba55-2c32093044be
# ╟─40eda0d7-3871-48d6-9976-e9dd7829265d
# ╠═aeaa6940-4f97-4286-97d4-7ad6dc6013b1
# ╟─a968cf5a-bed4-4939-980f-86e90903b756
# ╠═81b8240b-e3c0-427d-b57a-b07e52963f15
# ╟─2d6b3e56-0858-4b7a-9bd7-5d5fa2b835c9
# ╠═97d24eee-024e-4079-948a-49245fd3c734
# ╠═52956b53-22a2-47c2-bb8d-d70ea63dcff6
# ╟─70685b9d-b660-4443-ae7f-a0659456dc4f
# ╠═bb38f4c1-4443-4b33-a526-b5cc653f437b
# ╠═2b814578-5137-4805-bedf-2c7759d87048
# ╠═7e368048-6a64-4439-8114-493f7f45ddfd
# ╠═4049d967-f932-4eec-b6fc-711a5df79531
