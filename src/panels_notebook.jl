### A Pluto.jl notebook ###
# v0.14.4

using Markdown
using InteractiveUtils

# ╔═╡ b019d660-9f77-11eb-1527-278a3e1b087c
begin
  using Unitful
  using UnitfulUS
  using Match
  using DataStructures
  # using UnitfulCurrency   # trounble loading UnitfulCurrency
end


# ╔═╡ 60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
md"""
  # Setup

  Prefer inches.
  """

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
  return panel.length
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
struct WantedPanel <: AbstractWantedPanel
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
  struct FlippedPanel <: AbstractWantedPanel
    was::WantedPanel
  end

  function Base.getproperty(panel::FlippedPanel, prop::Symbol)
    was = getfield(panel, :was)
    if prop == :length
      return was.width
    elseif prop == :width
      return was.length
    elseif prop in propertynames(was)
      return getfield(was, prop)
    else
      return getfield(panel, prop)
    end
  end

  function Base.propertynames(panel::FlippedPanel, private::Bool=false)
    (fieldnames(typeof(panel))...,
     fieldnames(typeof(panel.was))...)
  end

  function flipped(panel::WantedPanel)  #  ::(::WantedPanel, ::FlippedPanel)
    return (panel, FlippedPanel(panel))
  end
  
  function wantsmatch(w1::WantedPanel, w2::WantedPanel)
    w1 == w2
  end
  
  function wantsmatch(f1::FlippedPanel, f2::FlippedPanel)
    f1 == f2
  end

  function wantsmatch(w::WantedPanel, f::FlippedPanel)::Bool
    f.was == w
  end

  function wantsmatch(f::FlippedPanel, w::WantedPanel)::Bool
    f.was == w
  end

  # Testing
  let
    w, f = flipped(WantedPanel(1u"inch", 2u"inch", "foo"))
    @assert w.length == f.width
    @assert w.width == f.length
    @assert w.label == f.label
    @assert setdiff(Set(propertynames(f)), Set(propertynames(w))) == Set((:was,))
    @assert wantsmatch(w, f)
    @assert wantsmatch(f, w)
  end
end

# ╔═╡ ecacafd3-5f70-41d9-b6cd-6b4893186b2a
begin
  wanda_box_panels = [
    WantedPanel(25u"inch", 30u"inch", "back")
    WantedPanel(25u"inch", 22u"inch", "right side")
    WantedPanel(25u"inch", 22u"inch", "left side")
    WantedPanel(22u"inch", 30u"inch", "top")
    WantedPanel(22u"inch", 30u"inch", "bottom")
  ]
  sort(wanda_box_panels; lt=smaller, rev=true)
end

# ╔═╡ adb89a84-5223-42db-90d5-8703b2d9a3b7
md"""
  ## AvailablePanel
  """

# ╔═╡ 5176ae29-b9ac-4c20-82c2-2e054a32eecc
"""
  A sheet of plywood we can buy frm the lumber yard.
  """
struct AvailablePanel <: AbstractPanel
  label::String
  width::LengthType
  length::LengthType
  cost
end

# ╔═╡ f6a43438-d7b0-442d-bb05-9e4488855665
md"""
  ### Supplier Data

  Taken from boulterplywood.com
  """

# ╔═╡ 65adef2d-9a53-4310-81a0-5dbb6d0918ca
begin    # Supplier Data
  KERF = (1/8)u"inch"
  
  COST_PER_CUT = 1.50   # u"USD"

  const AVAILABLE_PANELS = [
    AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", 95),
    AvailablePanel("5 x 5 x 1/2", 5u"ft", 5u"ft", 49),
    AvailablePanel("30 x 60 x 1/2", 30u"inch", 60u"inch", 30),
    AvailablePanel("30 x 30 x 1/2", 30u"inch", 30u"inch", 19)
  ]
end

# ╔═╡ 8f925530-7e76-44f7-9557-64d4629a5e39
md"""
## BoughtPanel

a BoughtPanel is created to wrap an AvailablePanel when we add it to the working set.  This ensured that when it is cut it has a distinct identity from any other BoughtPanel of the same size.
"""

# ╔═╡ 235e25dc-7139-4a24-861b-a0e7451a45eb
begin
  struct BoughtPanel <: CuttablePanel
	was::AvailablePanel
  end

  function Base.getproperty(panel::BoughtPanel, prop::Symbol)
    was = getfield(panel, :was)
	@match prop begin
		:was          =>  was
		:x            =>  0u"inch"
		:y            =>  0u"inch"
		:length       =>  was.length
		:width        =>  was.width
	    _             =>  getfield(was, prop)
    end
  end

  function Base.propertynames(panel::BoughtPanel, private::Bool=false)
    (fieldnames(typeof(panel))...,
     fieldnames(typeof(panel.was))...)
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
  length::LengthType
  width::LengthType
  cut_from::CuttablePanel
  cut_at::LengthType
  cut_axis::Axis
  x::LengthType
  y::LengthType
  cost
end

# ╔═╡ 41a5afbb-146a-407e-836e-299d80d7c55d
md"""
  ## ScrappedPanel

  ScrappedPanel wraps a Panel that is not big enough to cut any remaining AbstractWantedPanel from.
  """

# ╔═╡ 702afb66-eb60-4d13-84ff-d8eccd9e173c
struct ScrappedPanel <: AbstractPanel
  was::Panel    # We should never be scrapping an AvailablePanel.
end

# ╔═╡ fbc6012e-8893-4634-b632-1609c5a1d23a
# delegations from ScrappedPanel to the Panel we're tagging as too small
begin
  function Base.getproperty(panel::ScrappedPanel, property::Symbol)
    if property === :was
      return getfield(panel, :was)
    end
    getfield(getfield(panel, :was), property)
  end

  function Base.propertynames(panel::ScrappedPanel; private=false)
    fieldnames(Panel)
  end
end

# ╔═╡ 63b95b10-769f-4e8c-ad7f-6f6471155c5c
md"""
  ## FinishedPanel

  FinishedPanel wraps a Panel that matches an AbstractWantedPanel and associates that AbstractWantedPanel with the cut Panel.
  """

# ╔═╡ b264c74c-1470-4a0b-a693-922dd40a1216
"""
  matches an AbstractedWantedPanel that we've successfully made.
  """
struct FinishedPanel <: AbstractPanel
  wanted::AbstractWantedPanel
  was::CuttablePanel
  
  function FinishedPanel(candidate::Panel, wanted::AbstractWantedPanel)
    @assert candidate.length == wanted.length
    @assert candidate.width == wanted.width
    new(wanted, candidate)
  end
end

# ╔═╡ c012d7a5-6b89-455c-a4ca-7f50b507d670
# Delegation from FinishedPanel to Panel
begin
  function Base.getproperty(panel::FinishedPanel, property::Symbol)
    @match property begin
      :was        => getfield(panel, :was)
      :wanted     => getfield(panel, :wanted)
      _           => Base.getproperty(Core.getfield(panel, :was), property)
    end
  end

  function Base.propertynames(panel::FinishedPanel; private=false)
    (:was, :wanted, Base.fieldnames(Panel)...)
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
  Panels{T} = Tuple{Vararg{T}}
end

# ╔═╡ b03675d3-327d-4915-9a04-c9c6bbe04924
md"""
  # Cutting
  """

# ╔═╡ ce55a015-792b-41e1-9426-e5a349cf5ec1
begin
  function cut(panel::CuttablePanel,
               axis::LengthAxis,
               at::LengthType)::Union{Nothing,
                                      Tuple{Panel, Panel}}
    if panel.length < at
      return nothing
    end
    remnant = panel.length - at - KERF
    cost = (panel.cost + COST_PER_CUT) / 2
    (Panel(at, panel.width, panel, at, axis,
           panel.x, panel.y,
	   cost),
     Panel(remnant, panel.width, panel, at, axis,
           panel.x + at + KERF,
           panel.y,
	   cost))
  end

  function cut(panel::CuttablePanel,
               axis::WidthAxis,
               at::LengthType)::Union{Nothing,
                                      Tuple{Panel, Panel}}
    if panel.width < at
      return nothing
    end
    remnant = panel.width - at - KERF
    cost = (panel.cost + COST_PER_CUT) / 2
    (Panel(panel.length, at, panel, at, axis,
           panel.x, panel.y,
	   cost),
     Panel(panel.length, remnant, panel, at, axis,
           panel.x,
           panel.y + at + KERF,
	   cost))
  end
end

# ╔═╡ 966f82be-7fdf-44d2-9c9f-3e27c19aef89
begin
  local panel1 = AVAILABLE_PANELS[1]
  local at = 22u"inch"
  cut1, cut2 = cut(panel1, LengthAxis(), at)
  @assert cut1.length == at
  @assert cut1.width == panel1.width
  @assert cut2.width == panel1.width
  @assert cut2.length == panel1.length - at - KERF
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
    finished::Panels{FinishedPanel}
    scrapped::Panels{ScrappedPanel}
    working::Panels{CuttablePanel}
    accumulated_cost

    function SearchState(;
                         wanted=Panels{AbstractWantedPanel}([]),
                         finished=Panels{FinishedPanel}([]),
                         scrapped=Panels{ScrappedPanel}([]),
                         working=Panels{CuttablePanel}([]),
                         accumulated_cost=0)
      new(wanted, finished, scrapped, working, accumulated_cost)
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
	push!(newlyscrapped, ScrappedPanel(p))
      end
    end
    state = SearchState(;
		        wanted=wanted,
		        finished=if finished == nothing
                          precursor.finished
                        else
                          Panels{FinishedPanel}(union((finished,), precursor.finished))
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
  uconvert(Unitful.NoUnits,
           (1 - doneness(state)) * state.accumulated_cost)
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
  states::PriorityQueue{SearchState, SearchPriority}
  finished_states::Set{SearchState}
  cheapest::Union{SearchState, Nothing}
  # For debugging:
  considered_states::Vector{SearchState}
  
  function Searcher(want::Vector{<:AbstractWantedPanel};
                    available=AVAILABLE_PANELS)
    initial_state = SearchState(want)
    new(available,
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
  wanted = state.wanted[1]
  for working in state.working
    if !fitsin(wanted, working)
      continue
    end
    for axis_ in subtypes(Axis)
      axis = axis_()
      cuts = cut(working, axis, distance(wanted, axis))
      if cuts == nothing
	continue
      end
      @assert distance(cuts[1], axis) == distance(wanted, axis)
      if distance(cuts[1], other(axis)) == distance(wanted, other(axis))
	enqueue(searcher, SearchState(state, COST_PER_CUT,
				      FinishedPanel(cuts[1], wanted),
                                      working,
				      cuts[2]))
	continue
      end
      cuts2 = cut(cuts[1], other(axis), distance(wanted, other(axis)))
      if cuts2 == nothing
	continue
      end
      @assert distance(cuts2[1], other(axis)) == distance(wanted, other(axis))
      enqueue(searcher, SearchState(state, 2 * COST_PER_CUT,
				    FinishedPanel(cuts2[1], wanted),
                                    working,
				    cuts[2], cuts2[2]))
    end
  end
  return nothing
end


# ╔═╡ 5aac7456-b32f-40e8-a015-fcbea6f638ff
function run(searcher::Searcher)
  while !isempty(searcher.states)
    s = dequeue!(searcher.states)
    progress(searcher, s)
  end
end

# ╔═╡ 3b082138-5062-433b-b224-24b287851a1d
subtypes(Axis)

# ╔═╡ 4a9ebc9b-b91c-4ff6-ba55-2c32093044be
begin
  searcher = Searcher(wanda_box_panels[1:2])
  run(searcher)
  println(searcher.finished_states)
  searcher
end

# ╔═╡ c79562cb-0d5d-4ffe-877c-2404b817e9c1
length(wanda_box_panels)

# ╔═╡ f1a3bb57-8ef4-446b-82e2-9df8f79e57c8
length(AVAILABLE_PANELS)

# ╔═╡ 70685b9d-b660-4443-ae7f-a0659456dc4f
md"""
  # Experiments
  """

# ╔═╡ 1d0d28b0-30fd-4acb-bb20-18e9659f8549
begin
  x = (3, 5)
  a, b = x
  "$a  $b"
end

# ╔═╡ bb38f4c1-4443-4b33-a526-b5cc653f437b
+(area.(Set(wanda_box_panels))...)

# ╔═╡ b5c18d07-f61f-4167-86cd-2ccb9e283425
subtypes(Axis)

# ╔═╡ 74502de0-5b60-44e3-8bcf-3ad5d6fbcba2
LengthAxis()

# ╔═╡ f9519d09-57a3-41db-bf43-55d45e5e2584
Set(Iterators.flatten((1, (2, 3, 4), 5, (6, (7, 8)))))

# ╔═╡ 1ee711b3-c80b-434d-bccc-ec9768f3af5b
WantedPanel <: AbstractWantedPanel

# ╔═╡ 3f14900a-09f5-4a35-888a-af3491347033
Vector{WantedPanel} <: Vector{AbstractWantedPanel}

# ╔═╡ b127a88a-00ed-44e6-b829-4858e8bc35da
Vector{AbstractWantedPanel} <: Vector{WantedPanel}

# ╔═╡ 0b876d62-97a4-4952-adbc-6147ebd8dbb8
cat([1, 2, 3], [4, 5, 6]; dims=[1])

# ╔═╡ 0174ad76-753f-4367-879b-d3fb6f563184
collect(Iterators.flatten(((1,2,3), (4,5,6))))

# ╔═╡ Cell order:
# ╠═b019d660-9f77-11eb-1527-278a3e1b087c
# ╟─60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
# ╠═60fdb133-5d21-4445-90f9-3bbe49fb743b
# ╠═5be6a7bd-b97c-4b97-ab47-9d83b3a2dd77
# ╠═6835fdd3-eead-4d2b-81ce-a05df4f57499
# ╟─1292709e-63f9-4f9f-a6c0-0e9068a4c6b6
# ╠═98a48a7c-51e9-46f9-bdb4-e6a6b8380061
# ╟─29c94131-5b13-4588-a772-d517198d2163
# ╠═34bab1fd-ecdc-4054-8c69-5325ae807e1f
# ╟─7c51768d-f376-487c-a88d-f795fb01da48
# ╠═594a5dc5-77cc-4610-8ae0-2ee54abb1d4b
# ╠═ecacafd3-5f70-41d9-b6cd-6b4893186b2a
# ╟─adb89a84-5223-42db-90d5-8703b2d9a3b7
# ╠═5176ae29-b9ac-4c20-82c2-2e054a32eecc
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
# ╠═c012d7a5-6b89-455c-a4ca-7f50b507d670
# ╟─2fd93f59-4101-489f-b540-41d3ca48febf
# ╠═65f4609e-5d6f-4ba6-a941-45c42ac396b4
# ╟─b03675d3-327d-4915-9a04-c9c6bbe04924
# ╠═ce55a015-792b-41e1-9426-e5a349cf5ec1
# ╠═966f82be-7fdf-44d2-9c9f-3e27c19aef89
# ╟─1fec8fd3-fc4a-4efc-9d03-16b050c22926
# ╠═ed05bfa9-995a-422b-9ccb-215b5535723e
# ╠═fc065401-50dc-4a21-98ad-b2ecd003d397
# ╟─c72bb206-c7c6-4be6-8b92-446540edbea2
# ╠═77b32e0e-fb41-4a2a-8b1d-a272e4a1dd60
# ╠═81ffb853-ba0a-4513-b4e1-21f5c2327dc9
# ╟─d90e2c72-9fdb-4f9e-94c8-7b211d2b16e3
# ╠═7b64474a-bbb1-4bc2-8f87-a35e4b168545
# ╠═137932b7-b914-47f0-b355-2406c7dfe4a4
# ╠═5aac7456-b32f-40e8-a015-fcbea6f638ff
# ╠═4e51fc12-7f05-49e2-b55a-7d91c47dd185
# ╠═3b082138-5062-433b-b224-24b287851a1d
# ╠═4a9ebc9b-b91c-4ff6-ba55-2c32093044be
# ╠═c79562cb-0d5d-4ffe-877c-2404b817e9c1
# ╠═f1a3bb57-8ef4-446b-82e2-9df8f79e57c8
# ╟─70685b9d-b660-4443-ae7f-a0659456dc4f
# ╠═1d0d28b0-30fd-4acb-bb20-18e9659f8549
# ╠═bb38f4c1-4443-4b33-a526-b5cc653f437b
# ╠═b5c18d07-f61f-4167-86cd-2ccb9e283425
# ╠═74502de0-5b60-44e3-8bcf-3ad5d6fbcba2
# ╠═f9519d09-57a3-41db-bf43-55d45e5e2584
# ╠═1ee711b3-c80b-434d-bccc-ec9768f3af5b
# ╠═3f14900a-09f5-4a35-888a-af3491347033
# ╠═b127a88a-00ed-44e6-b829-4858e8bc35da
# ╠═0b876d62-97a4-4952-adbc-6147ebd8dbb8
# ╠═0174ad76-753f-4367-879b-d3fb6f563184
