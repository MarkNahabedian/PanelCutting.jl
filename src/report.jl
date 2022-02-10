
export report

"""
    runCmd(cmd::Cmd, cmdOutput::IO)::IO
Run the external command `cmd`, which will write output to `cmdOutput`.
The stream that's returnd can be written to to provide inoput to the
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

"""
    report(::Searcher)
Generate an HTML fragment that provides a detailed report of
our cut search and results.
"""
function report(searcher::Searcher;
                includeCutDiagram=true,
                includeCutGraph=false)
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
                " cuts to make to get panels of these sizes")
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
        if searcher.cheapest == nothing
            elt(io, :p; style="font-weight: bold") do
                write(io, "No solution has been found!")
            end
            return
        else
            elt(io, :p) do
                write(io, "The best solution has a cost of " *
                    "$(searcher.cheapest.accumulated_cost).")
            end
        end
        # Table of panel areas
        elt(io, :div) do
            elt(io, :table) do
                elt(io, :thread) do
                    elt(io, :tr) do
                        th(io, "Group")
                        th(io, "Panel")
                        th(io, "Length")
                        th(io, "Width")
                        th(io, "Area")
                        th(io, "%")
                    end
                end
                elt(io, :tbody) do
                    bought_area = sum(area.(searcher.cheapest.bought))
                    function panel_group(group, panels)
                        for p in panels
                            elt(io, :tr; style=style) do
                                if p == first(panels)
                                    td(io, group;
                                       align="center",
                                       valign="top",
                                       rowspan=length(panels))
                                end
                                td(io, p.label; align="center")
                                td(io, p.length; align="right")
                                td(io, p.width; align="right")
                                td(io, area(p); align="right")
                                td(io, @sprintf("%.2f%%",
						100 * convert(Float64, area(p)/bought_area));
				   align="right")
                                if p == panels[1]
				    frac = convert(Float64, sum(area.(panels)) / bought_area)
				    td(io, @sprintf("%.2f%%", 100 * frac);
				       rowspan=length(panels),
				       valign="top",
				       align="right")
                                end
                            end
                        end
                    end
                    panel_group("bought", searcher.cheapest.bought)
                    panel_group("scrapped", searcher.cheapest.scrapped)
                    panel_group("left over", searcher.cheapest.working)
                    panel_group("finished", searcher.cheapest.finished)
                end
            end
        end
        if includeCutDiagram
            elt(io, :div) do
                toSVG(io, searcher.cheapest)
            end
        end
        if includeCutGraph
            elt(io, :div) do
		# Run the GraphViz dot command, inlining the SVG output
		# into the report:
                dot, err = runCmd(`dot -Tsvg`, io)
                dotgraph(dot, PanelCutGraph(searcher.cheapest), PanelsDotStyle())
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

