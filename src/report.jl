
export inPluto, report

"""
    inPluto()::Bool

Return true if the notebook is being run in Pluto, artyher than
directly in Julia (e.g. command line or REPL).
"""
function inPluto()::Bool
    isdefined(Main, :PlutoRunner)
end


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
    report(::Searcher; includeCutDiagram=true, includeCutGraph=false, filename=nothing)

Generate an HTML fragment that provides a detailed report of
our cut search and results.

If `filename` is specified (it should be an absolute path) then an
HTML file with that name is written, otherwise an HTML fragment is
returned.
"""
function report(searcher::Searcher;
                includeCutDiagram=true,
                includeCutGraph=false,
                filename=nothing)
    numbering = FinishedPanelNumbering(searcher.cheapest)
    finished = searcher.cheapest.finished
    panel_number(p::FinishedPanel) = numbering(p)
    function panel_number(wp::AbstractWantedPanel)
        fps = filter(finished) do fp
            fp.wanted == wp
        end
        if length(fps) == 1
            panel_number(fps[1])
        else
            ""
        end
    end
    sigfig(x) = @sprintf("%.3f%s", ustrip(x), unit(x))
    cell_style = :style => "padding-left: 1em; padding-right: 1em;"
    fragment =
        elt("div") do a
            a(elt("h2", "Panel Cut Report"))
            a(elt("p",
                  "Report of what stock to purchase and what",
                  " cuts to make to get panels of these sizes"))
            function th(heading)
                elt("th", cell_style, heading)
            end
            function td(things...)
                elt("td", cell_style, things...)
            end
	    # Table of wanted panels:
            a(elt("table") do a
                  a(elt("thead") do a
                        a(elt("tr") do a
                              for heading in ("#", "Label", "Length",
                                              "Width", "Ok to Flip?")
                                  a(th(heading))
                              end
                          end)
                    end)
                  a(elt("tbody") do a
                        sorted = sort(searcher.wanted; by=panel_number)
                        for panel in sorted
                            a(elt("tr") do a
                                  a(td(panel_number(panel),
                                       :align => "center"))
                                  a(td(panel.label, :align => "center"))
                                  a(td(sigfig(panel.length), :align => "right"))
                                  a(td(sigfig(panel.width), :align => "right"))
                                  a(td(:align => "center",
                                       panel isa FlippedPanel ? "yes" : "no"))
                              end)
                        end
                    end)
              end)
            if searcher.cheapest == nothing
                a(elt("p", :style => "font-weight: bold",
                      "No solution has been found!"))
                return
            else
                a(elt("p",
                      @sprintf("The best solution has a cost of %0.2f.",
                               searcher.cheapest.accumulated_cost)))
            end
            # Table of panel areas
            a(elt("div", :class => "panel-areas") do a
                  a(elt("table") do a
                        a(elt("thead") do a
                              a(elt("tr") do a
                                    a(th("Group"))
                                    a(th("Panel"))
                                    a(th("Length"))
                                    a(th("Width"))
                                    a(th("Area"))
                                    a(th("%"))
                                end)
                          end)
                        a(elt("tbody") do a
                              bought_area = sum(area.(searcher.cheapest.bought))
                              function panel_group(group, panels)
                                  for p in panels
                                      a(elt("tr", #= :style => style =#) do a
                                            if p == first(panels)
                                                a(td(group,
                                                     :align => "center",
                                                     :valign => "top",
                                                     :rowspan => length(panels)))
                                            end
                                            a(td(p.label, :align => "center"))
                                            a(td(sigfig(p.length), :align => "right"))
                                            a(td(sigfig(p.width), :align => "right"))
                                            a(td(sigfig(area(p)), :align => "right"))
                                            a(td(@sprintf("%.2f%%",
						          100 * convert(Float64, area(p)/bought_area)),
				                 :align => "right"))
                                            if p == panels[1]
				                frac = convert(Float64, sum(area.(panels)) / bought_area)
				                a(td(@sprintf("%.2f%%", 100 * frac),
				                     :rowspan => length(panels),
				                     :valign => "top",
				                     :align => "right"))
                                            end
                                        end)
                                  end
                              end
                              panel_group("bought", searcher.cheapest.bought)
                              panel_group("scrapped", searcher.cheapest.scrapped)
                              panel_group("left over", searcher.cheapest.working)
                              panel_group("finished", searcher.cheapest.finished)
                          end)
                    end)
              end)
            if includeCutDiagram
                a(elt("div",
                      :class => "best-solution",
                      toSVG(numbering)))
            end
            if includeCutGraph
                error("Panel cut graph is not currently supported.")
                a(elt("div", :class => "cut-graph") do a
                      io = IOBuffer()
		      # Run the GraphViz dot command, inlining the SVG output
		      # into the report:
                      dot, err = runCmd(`dot -Tsvg`, io)
                      dotgraph(dot, PanelCutGraph(searcher.cheapest),
                               PanelsDotStyle())
                      close(dot)
                      err = read(err)
                      if length(err) > 0
                          throw(Exception("Error running dot: $err"))
                      end
                      seek(io, 0)
                      a(XML.Document(XML.XMLTokenIterator(io)).root)
                  end)
            end
        end

    if filename isa Nothing
        return fragment
    else
        open(filename, "w") do out
            XML.write(out, report_html_wrapper(fragment))
        end
        @info "Wrote $filename"
        return filename
    end
end

function report_html_wrapper(content)
    elt("html",
        elt("head"),
        elt("body", content))
end

