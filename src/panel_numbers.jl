# Assiciate a number with each FinishedPanel.  These can be used as
# lebels in the SVG cut diagram since it's too hard to include long
# text there.

mutable struct FinishedPanelNumbering
    search_state::SearchState
    next
    numbers
    panel_graph::PanelGraph

    FinishedPanelNumbering(search_state::SearchState) =
        assign_nunbers(new(search_state, 1, Dict(),
                           PanelGraph(search_state)))
end

function (numbering::FinishedPanelNumbering)(panel::FinishedPanel)
    id = panel.uid
    if haskey(numbering.numbers, id)
        return numbering.numbers[id]
    end
    error("No assigned number for $id, $panel")
end

function assign_nunbers(n::FinishedPanelNumbering)
    for p in n.search_state.bought
        assign_nunbers(n, p)
    end
    n
end

function assign_nunbers(n::FinishedPanelNumbering, panel::ScrappedPanel)
    # ScrappedPanels don't deserve a number
end

function assign_nunbers(n::FinishedPanelNumbering, panel::FinishedPanel)
    if haskey(n.numbers, panel.uid)
        error("$panel already has a number")
    end
    n.numbers[panel.uid] = n.next
    n.next += 1
end

function assign_nunbers(n::FinishedPanelNumbering, panel::CuttablePanel)
    start = n.next
    for (from, to) in query(n.panel_graph, panel, AbstractPanel)
        @assert from == panel
        assign_nunbers(n, to)
    end
    n.numbers[panel.uid] = collect(start : (n.next - 1))
end



