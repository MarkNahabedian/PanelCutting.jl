
md"""
# Describing the Cuts using SVG

We use (locally modified, pull request pending) `NativeSVG.jl` to
generate SVG code.
"""

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
  .factory-edge {
    stroke-width: 1px;
    stroke: blue;
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

#= this macro does not play well with Pluto notebooks
# Abstract measurements in svg user space from the dimensions we use
# for measuring panels:
@Unitful.unit svgd "svgd" SVGDistance 0.01u"inch" false
Unitful.register(@thismodule)
=#

"""
Turn a Unitful length quantity to a floating point number we can use in SVG.
"""
function svgdistance(d)::Real
    ustrip(Real, u"inch", d)
end

"""
Draw an SVG `rect` representing a panel.
"""
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

export panelrect, panelrect


"""
The space between panels in an SVG drawing, and space between panels
and SVG edge.
"""
const SVG_PANEL_MARGIN = 2u"inch"

function toSVG(state::SearchState)
    buf = IOBuffer()
    toSVG(buf, state)
    return take!(buf)
end

export SVG_PANEL_MARGIN, toSVG


function toSVG(io::IO, state::SearchState)::Nothing
    rpg = makePanelGraph(state)
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

function toSVG(io::IO, panel::AbstractPanel, rpg::PanelGraph)::Nothing
    # Do nothing, We only draw certain types of panel.
end

function toSVG(io::IO, panel::BoughtPanel, rpg::PanelGraph)::Nothing
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

function toSVG(io::IO, panel::Panel, rpg::PanelGraph)::Nothing
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

function toSVG(io::IO, panel::FinishedPanel, rpg::PanelGraph)::Nothing
    g(io; class="FinishedPanel") do
	panelrect(io, panel, "finished")
    end
end

