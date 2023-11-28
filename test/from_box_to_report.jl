using PanelCutting
using PanelCutting: FinishedPanelNumbering, assign_nunbers

using Unitful
using UnitfulUS

box = Box(30u"cm", 20u"cm", 10u"cm")
do_faces(box) do face
    box.material[face] = "plywood"
end
box.open[Top()] = true
box.grain_direction[Bottom()] = GDEither()

wanted = WantedPanels(box)

supplier = Supplier(
    name="test",
    cost_per_cut=1.50,
    kerf=(1/8)u"inch",
    available_stock=[
        AvailablePanel(;
                       label = "example AvailablePanel",
                       width = 4u"ft",
                       length = 4u"ft",
                       thickness = 0.25u"inch",
                       material = "plywood",
                       cost = money(10.00))])

searcher = Searcher(supplier, wanted)
search(searcher)

numbering = FinishedPanelNumbering(searcher.cheapest)

numbering.numbers

report(searcher;
       includeCutDiagram=true,
       includeCutGraph=false,
       filename="from_box_to_report.html")

