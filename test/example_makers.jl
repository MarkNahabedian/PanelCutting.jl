
example_makers = Dict{Type, Function}()

"""
Make a new example of the specified type.
"""
function example(t::Type{<:AbstractPanel})
    example_makers[t]()
end

example_makers[WantedPanel] =
    () -> WantedPanel(;
                      label = "example WantedPanel",
                      width = 6u"inch",
                      length = 10u"inch")
example_makers[FlippedPanel] =
    () -> FlippedPanel(example(WantedPanel))
example_makers[AvailablePanel] =
    () -> AvailablePanel(;
                         length = 4u"ft",
                         width = 2u"ft",
                         label = "example AvailablePanel",
                         cost = money(10.00))
example_makers[BoughtPanel] =
    () -> BoughtPanel(example(AvailablePanel))
example_makers[Panel] =
    () -> let
        from = example(BoughtPanel)
        axis = LengthAxis()
        at = distance(from, axis) / 3
        Panel(;
              length = at,
              width = distance(from, other(axis)),
              cut_from = from,
              cut_at = at,
              cut_axis = axis,
              x = from.x,
              y = from.y,
              cost = from.cost)
    end
example_makers[ScrappedPanel] =
    () -> ScrappedPanel(; was=example(Panel))
example_makers[FinishedPanel] =
    () -> let
        have = example(Panel)
        FinishedPanel(have, WantedPanel(label = "want",
                                        width = have.width,
                                        length = have.length))
    end
