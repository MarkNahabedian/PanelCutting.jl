
# Describing the Cuts using SVG

export STYLESHEET, svgdistance, elt, panelrect


"""
The CSS stylesheet we use for SVG rendering in reports.
"""
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
  .BoughtPanel-edge rect {
    stroke-width: 1px;
    stroke: blue;
    fill: none;
  }
  .FinishedPanel rect {
    stroke: none;
    fill: rgb(0%, 50%, 0%);
  }
  .ScrappedPanel rect {
    stroke: none;
    fill: rgb(50%, 0%, 0%);
  }
  .FinishedPanel text {
    stroke: white;
    fill: white;
    text-anchor: middle;
    font-family: sans-serif;
    font-size: 2px;
    font-weight: bold;
    vector-effect: non-scaling-stroke;
  }
"""

#= this macro does not play well with Pluto notebooks
# Abstract measurements in svg user space from the dimensions we use
# for measuring panels:
@Unitful.unit svgd "svgd" SVGDistance 0.01u"inch" false
Unitful.register(@thismodule)
=#


"""
    svgdistance(d)

Turn a Unitful length quantity to a floating point number we can use in SVG.
"""
function svgdistance(d)::Real
    ustrip(Real, u"inch", d)
end


function xmlComment(text::AbstractString)
    XML.Comment(text)
end


"""
    elt(f, tagname::AbstractString, things...)
    elt(tagname::AbstractString, things...)

Return an XML element.  `f` is called with a single argument: either
an XML.AbstractXMLNode or a Pair describing an XML attribute to be added to the
resulting element.
"""
function elt(f::Function, tagname::AbstractString, things...)
    attributes = OrderedDict()
    children = Vector{Union{CData, Comment, Element, String}}()
    function add_thing(s)
        if s isa Pair
            attributes[Symbol(s.first)] = string(s.second)
        elseif s isa AbstractString
            push!(children, s)
        elseif s isa Number
            push!(children, string(s))
        elseif s isa XML.AbstractXMLNode
            push!(children, s)
        elseif s isa Nothing
            # Ignore
        else
            error("unsupported XML content: $s")
        end
    end
    for thing in things
        add_thing(thing)
    end
    f(add_thing)
    XML.Element(tagname, attributes, children)
end

elt(tagname::AbstractString, things...) = elt(identity, tagname, things...)


"""
    panelrect(panel::AbstractPanel)

Return an SVG element that will draw the representation of the panel.
"""
function panelrect(panel::AbstractPanel)
    # It's confusing that panel.width corresponds to SVG length
    # and panel.length corresponds to SVG width.  Sorry.
    # This is a consequence of the x and y coordinates of a panel
    # corresponding with the panel's length and width respectively.
    elt("g", :class => string(typeof(panel))) do a
        a(xmlComment(string("<!-- $(panel.label): ",
			    "$(panel.width) by $(panel.length), ",
			    "at $(panel.x), $(panel.y) -->\n")))
        a(elt("rect",
	      :x => svgdistance(panel.x),
	      :y => svgdistance(panel.y),
	      :width => svgdistance(panel.length),
	      :height => svgdistance(panel.width),
              panel_title_elt(panel)))
        a(panel_text_elt(panel))
    end
end


"""
The space between panels in an SVG drawing, and space between panels
and SVG edge.
"""
const SVG_PANEL_MARGIN = 2u"inch"

export SVG_PANEL_MARGIN, toSVG


function toSVG(state::SearchState)::XML.Element
    rpg = PanelGraph(state)
    #=
    write(io, """<?xml version="1.0" encoding="UTF-8"?>\n""")
    write(io, """<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"\n""")
    write(io, """          "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n""")
    =#
    # Outermost SVG:
    vpwidth = svgdistance(maximum(major.(keys(rpg))) + 2 * SVG_PANEL_MARGIN)
    vpheight = svgdistance(sum(minor.(filter(p -> p isa BoughtPanel, keys(rpg)))) + 
	2 * SVG_PANEL_MARGIN)
    elt("svg",
        :xmlns => "http://www.w3.org/2000/svg",
	:width =>"90%",
	:viewBox => "0 0 $(vpwidth) $(vpheight)",
        :style => "background-color: pink",
        elt("style", :type => "text/css", STYLESHEET),
        elt("g", :class => "everything") do a
	    y = SVG_PANEL_MARGIN
	    for stock in filter((p) -> p isa BoughtPanel, keys(rpg))
		# We want to have the longer dimension of panel run
		# horizontally.  If so, we can apply a 90 degree rotation.
		# Here we just translate successive stock panels (BoughtPanel)
		# by its minor dimension and margins to space them out.
		# The toSVG method of BoughtPanel will deal with rotation.
		tx = svgdistance(SVG_PANEL_MARGIN)
		ty = svgdistance(y)
                a(elt("g",
                      :transform => "translate($(tx), $(ty))",
                      toSVG(stock, rpg)))
                y += minor(stock) + SVG_PANEL_MARGIN
	    end
        end)
end

        
function toSVG(panel::AbstractPanel, rpg::PanelGraph)
    # Do nothing, We only draw certain types of panel.
end

function toSVG(panel::BoughtPanel, rpg::PanelGraph)
    # We want to have the longer dimension of panel run horizontally.
    # This is already anticipated above wnere we calculate the SVG viewBox.
    transform = ""
    if panel.length != major(panel)
	tx = svgdistance(0u"inch")
	ty = svgdistance(panel.width)
	transform = "rotate(90) translate($tx $ty)"
    end
    elt("g",
        :transform =>transform) do a
            a(panelrect(panel))
	    for p in rpg[panel]
	        a(toSVG(p, rpg))
	    end
        end
end

function toSVG(panel::Panel, rpg::PanelGraph)
    elt("g", :class => "Panel") do a
	for p in rpg[panel]
	    a(toSVG(p, rpg))
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
        a(elt("path", :d => d))
    end
end

function toSVG(panel::FinishedPanel, rpg::PanelGraph)
    panelrect(panel)
end

function toSVG(panel::ScrappedPanel, rpg::PanelGraph)
    panelrect(panel)
end

panel_text_elt(::AbstractPanel) = nothing

panel_title_elt(panel::BoughtPanel) = nothing

function panel_title_elt(panel::FinishedPanel)
    elt("title",
        "$(panel.length) × $(panel.width)")
end

function panel_title_elt(panel::ScrappedPanel)
    elt("title",
        "SCRAP\n$(panel.length) × $(panel.width)")
end

function panel_text_elt(panel::FinishedPanel)
    elt("text",
	:x => svgdistance(panel.x + panel.length / 2),
	:y => svgdistance(panel.y + panel.width / 2),
        :textLength => svgdistance(panel.length),
        :lengthAdjust => "spacingAndGlyphs",
        "$(panel.length) × $(panel.width)")
end

