
md"""
# Searching for an optimal cut sequence
"""

struct SearchState
    # panels are removed from wanten once they are finished.
    wanted::Panels{AbstractWantedPanel}
    bought::Panels{BoughtPanel}
    finished::Panels{FinishedPanel}
    scrapped::Panels{ScrappedPanel}
    working::Panels{CuttablePanel}
    accumulated_cost::MoneyType

    function SearchState(;
                         wanted=Panels{AbstractWantedPanel}([]),
                         bought=Panels{BoughtPanel}([]),
                         finished=Panels{FinishedPanel}([]),
                         scrapped=Panels{ScrappedPanel}([]),
                         working=Panels{CuttablePanel}([]),
                         accumulated_cost=money(0))
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
    SearchState(; wanted=Panels{
        AbstractWantedPanel}(sort(want; lt=smaller, rev=true)))
end

# A constructor for successor states that enforces critical invariants
function SearchState(precursor::SearchState, cost,
		     finished::Union{Nothing, FinishedPanel},
                     used::Union{Nothing, CuttablePanel},
		     offcuts::CuttablePanel...)
    ### This will not catch a newly bought panel that left no off-cut
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
            # We just cut this panel, it's gone now.
            continue
        end
        if any((w) -> fitsin(w, p), wanted)
	    push!(working, p)
        else
            # p can't fit any remaining AbstractWantedPanel, scrap it:
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

export SearchState, doneness


md"""
## Priority

For A* Search we need to assign a priority to each state in the state
space we are searching through.  A SearchState with **lower** priority
will be considered **ahead** of one with higher priority.
"""

SearchPriority = Real

function priority(state::SearchState)::SearchPriority
    # Priority should get worse as the cost increases but should get better
    # as we approach completion.
    (1 - doneness(state)) * unmoney(state.accumulated_cost)
end

export SearchPriority, priority


md"""
 ## Searching

This Searcher implements A* search using a PriorityQueue.

One could implement other searchers to implement, for example, depth or breadth first search.
"""

mutable struct Searcher
    supplier::Supplier
    wanted::Vector{<:AbstractWantedPanel}
    states::PriorityQueue{SearchState, SearchPriority}
    finished_states::Set{SearchState}
    cheapest::Union{SearchState, Nothing}
    # For debugging:
    considered_states::Vector{SearchState}
    
    function Searcher(supplier::Supplier,
                       want::Vector{<:AbstractWantedPanel})
        initial_state = SearchState(want)
        new(supplier, uniqueWantedPanels(want),
            PriorityQueue{SearchState, SearchPriority}(
                initial_state => priority(initial_state)),
            Set{SearchState}(),
	    nothing,
	    Vector{SearchState}())
    end
end

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

function search(searcher::Searcher)
    while !isempty(searcher.states)
        s = dequeue!(searcher.states)
        progress(searcher, s)
    end
end

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
    successors = 0
    # Try cutting the first wanted panel from each of the working panels
    function cutWanted(wanted)
        for working in state.working
            if !fitsin(wanted, working)
                continue
            end
            for axis_ in subtypes(Axis)
                axis = axis_()
                cuts = cut(working, axis, distance(wanted, axis);
			   kerf=searcher.supplier.kerf,
			   cost=searcher.supplier.cost_per_cut)
                if length(cuts) == 0
	            continue
                end
                @assert distance(cuts[1], axis) == distance(wanted, axis)
                if distance(cuts[1], other(axis)) == distance(wanted, other(axis))
	            enqueue(searcher, SearchState(state, searcher.supplier.cost_per_cut,
				                  FinishedPanel(cuts[1], wanted),
                                                  working,
						  cuts[2:end]...))
		    successors += 1
	            continue
                end
                cuts2 = cut(cuts[1], other(axis), distance(wanted, other(axis));
                            kerf=searcher.supplier.kerf,
			    cost=searcher.supplier.cost_per_cut)
                if length(cuts2) == 0
	            continue
                end
                @assert distance(cuts2[1], other(axis)) == distance(wanted, other(axis))
                enqueue(searcher, SearchState(state, 2 * searcher.supplier.cost_per_cut,
				              FinishedPanel(cuts2[1], wanted),
                                              working,
					      cuts[2:end]..., cuts2[2:end]...))
		successors += 1
            end
        end
        return nothing
    end
    wanted = state.wanted[1]
    cutWanted(wanted)
    # For FlippedPanel we consider both the flipped and original shapes:
    if wanted isa FlippedPanel
        cutWanted(wanted.was)
    end
    # If there are still WantedPanels remaininig but no progress was
    # made, buy more stock.
    if successors == 0 && !isempty(state.wanted)
        for p in searcher.supplier.available_stock
            if fitsin(state.wanted[1], p)
                new_state = SearchState(state, p.cost, nothing,
                                        nothing, BoughtPanel(p))
	        enqueue(searcher, new_state)
            end
        end
    end
end

function allstates(searcher::Searcher)
    union(searcher.finished_states,
	  keys(searcher.states))
end

export Searcher, enqueue, search, progress, allstates


