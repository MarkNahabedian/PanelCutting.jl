
# Testing if panels overlap:

export PanelOverlapError, Span, XSpan, YSpan, within, overlap, errIfOverlap


"""
    PanelOverlapError

An error that is thrown when panels that shouldn'y overlap do.
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

