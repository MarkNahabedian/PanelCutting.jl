var documenterSearchIndex = {"docs":
[{"location":"example_1/#An-Example","page":"Example 1","title":"An Example","text":"","category":"section"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"Suppose we want to make an open-topped box whose outside dimensions are 12 inches long, 6 inches wide and 4 inches deep out of 1/4 inch plywood.","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"using PanelCutting\nusing Unitful\nusing UnitfulUS\n\nbox_length = 12u\"inch\"\nbox_width = 6u\"inch\"\nbox_depth = 4u\"inch\"\nstock_thickness = (1/4)u\"inch\"","category":"page"},{"location":"example_1/#What-Do-We-Want?","page":"Example 1","title":"What Do We Want?","text":"","category":"section"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"To use PanelCutting we must first describe the target dimensions of sheet stock after it is cut.  For each panel we must make a WantedPanel.","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"Note that these dimensions don't account for any joinery.  For this simple example all panels are butt jointed, with the sides and ends sitting on top of the bottom and the ends inset between the sides.","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"Also note that we do not yet include the thickness of stock when selecting material to cut.  so far my projects have been simple enough that I've only needed one thickness of stock.  In the furure we should also model stock thickness and material type.","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"WANTED = [\n    WantedPanel(\n        label = \"bottom\",\n        # the bottom will occupy the full footprint of the box with\n        # the sides and ends sitting on top of it\n        length = box_length,\n        width = box_width,\n        material = \"Baltic Birch\",\n        thickness = (1/4)u\"inch\"),\n    # Sometimes we need several instances of the same shaped panel.\n    # WantedPanel can take a pre-multiplier:\n    (2 * WantedPanel(\n        label = \"side\",\n        length = box_length - 2 * stock_thickness,\n        width = box_depth - stock_thickness,\n        material = \"Baltic Birch\",\n        thickness = (1/4)u\"inch\")\n     )...,  # Pre-multiplying gives a Vector, which we must spread.\n    (2 * WantedPanel(\n        label = \"end\",\n        length = box_width - 2 * stock_thickness,\n        width = box_depth - stock_thickness,\n        material = \"Baltic Birch\",\n        thickness = (1/4)u\"inch\")\n     )...\n         ]","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"If you don't care about grain direction you can include a flipped version of a WantedPanel:","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"orFlipped(WantedPanel(\n    label = \"bottom\",\n    length = box_length,\n    width = box_width,\n    material = \"Baltic Birch\",\n    thickness = (1/4)u\"inch\",))","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"but we will not include these in our example.","category":"page"},{"location":"example_1/#What-Are-We-Starting-With?","page":"Example 1","title":"What Are We Starting With?","text":"","category":"section"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"We must describe what sheet stock is available to cut from.  We do this with AvailablePanel.  Each size of AvailablePanel only needs to be instantiated once.  It is assumed that the supply of AvailablePanels is unlimited for our purposes.  These sizes and prices are taken from my local plywood supplier.  My supplier will accurately cut down stock to specified dimensions at a reasonable price, so we also note the cost per cut and the kerf width:","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"BOULTER_PLYWOOD = Supplier(\n    name = \"Boulter Plywood\",\n    kerf = (1/8)u\"inch\",\n    cost_per_cut = money(1.50),\n    available_stock = [\n        AvailablePanel(;\n            label = \"1/4 5 × 5 Baltic Birch\",\n            material = \"Baltic Birch\",\n            thickness = (1/4)u\"inch\",\n            length = 5u\"ft\",\n            width = 5u\"ft\",\n            cost = 84.00   # I've not been able to get UnitfulCurrency to work\n        ),\n        AvailablePanel(;\n            label = \"1/4 30 × 60 Baltic Birch\",\n            material = \"Baltic Birch\",\n            thickness = (1/4)u\"inch\",\n            length = 60u\"inch\",\n            width = 30u\"inch\",\n            cost = 51.00\n        ),\n        AvailablePanel(;\n            label = \"1/4 30 × 30 Baltic Birch\",\n            material = \"Baltic Birch\",\n            thickness = (1/4)u\"inch\",\n            length = 30u\"inch\",\n            width = 30u\"inch\",\n            cost = 36.00)\n      ])","category":"page"},{"location":"example_1/#What-To-Buy-And-Where-To-Cut?","page":"Example 1","title":"What To Buy And Where To Cut?","text":"","category":"section"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"Now that we have described what we want and what we're starting with, we can search for an optimal cut pattern.","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"# The cut optimization is performed by a Searcher:\nsearcher = Searcher(BOULTER_PLYWOOD, WANTED)\nsearch(searcher)","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"The most efficient cut pattern (least expensive in terms of stock used and number of cuts) is in searcher.cheapest. The resulting panels there are represented by FinishedPanels which have tracked how they were cut:","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"searcher.cheapest.finished","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"We can generate a more readable report for our box:","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"report(searcher;\n       includeCutDiagram=true,\n       includeCutGraph=false,\n       filename=\"example_panel_cut_report.html\")","category":"page"},{"location":"example_1/","page":"Example 1","title":"Example 1","text":"You can see the report here.","category":"page"},{"location":"box_example/#Using-the-Box-type-to-define-your-panels","page":"Boxes","title":"Using the Box type to define your panels","text":"","category":"section"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Sheet stock is typically used for making boxes, cabinets and drawers, all of which have a rectangular crosssection on each axis.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"A Box is first specified by its outside dimensions.  The Unitful package (and optionally UnitfulUS) are used so we can specify units for the box dimensions.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"using PanelCutting, Unitful, UnitfulUS\n\nmy_box = Box(0.3u\"m\", 0.2u\"m\", 0.1u\"m\")","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"The Box has six faces which are identified by singleton types.  The faces come in three opposite pairs: Top and Bottom, Left and Right, and Front and Back.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Once a box is defined, one can specify whether each face is open, or the thickness of the panel for that face.  One can also specify what material should be used.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"my_box.open[Top()] = true\n\ndo_faces(my_box) do face\n    # All faces are 5mm baltic birch:\n    my_box.thickness[face] = (1/4)u\"inch\"\n    my_box.material[face] = \"Baltic Birch\"\nend","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"For each face of a box, one can also specify the grain direction (also represented by singleton types), one of GDLong(the default), GDShort or GDEither.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"my_box.grain_direction[Bottom()] = GDEither()","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"A Box also has edges.  An edge is identified by a pair of faces. Edge(Front(), Bottom()) specifies the edge where the bottom and front panels of the box meet.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"One can specify the joint type to be used for each edge.  The joint type affects this sizes of the panels which meet at that edge.  For a butt joint, one face is shortened by the thickness of the other.  For a finger joint, both panels would be at full length.  For a dado/tongue and grrove joint, one panel is shortened by the thickness of the other but lengthened by the tongue length.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"let\n    # Use finger joints between each pair of sides:\n    sides = [Left(), Back(), Right(), Front()]\n    for i in 0:(length(sides) - 1)\n        e = Edge(sides[i + 1],\n                 sides[1 + (i + 1) % length(sides)])\n        my_box.joint_types[e] = FingerJoint()\n    end\n    # Use a dado joint for each edge of the bottom:\n    for n in neighbors(Bottom())\n        edge = Edge(Bottom(), n)\n        my_box.joint_types[edge] = DadoJoint(Bottom(), 2u\"mm\")\n    end\nend","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Once the box is fully specified, we can ask about the panels it requires, its WantedPanels:","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"WantedPanels(my_box)","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"To make our box, we first need sheet stock, which comes from a Supplier.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"BOULTER_PLYWOOD = Supplier(\n    name = \"Boulter Plywood\",\n    kerf = (1/8)u\"inch\",\n    cost_per_cut = money(1.50),\n    available_stock = [\n        AvailablePanel(;\n            label = \"1/4 5 × 5 Baltic Birch\",\n            material = \"Baltic Birch\",\n            thickness = (1/4)u\"inch\",\n            length = 5u\"ft\",\n            width = 5u\"ft\",\n            cost = 84.00   # I've not been able to get UnitfulCurrency to work\n        ),\n        AvailablePanel(;\n            label = \"1/4 30 × 60 Baltic Birch\",\n            material = \"Baltic Birch\",\n            thickness = (1/4)u\"inch\",\n            length = 60u\"inch\",\n            width = 30u\"inch\",\n            cost = 51.00\n        ),\n        AvailablePanel(;\n            label = \"1/4 30 × 30 Baltic Birch\",\n            material = \"Baltic Birch\",\n            thickness = (1/4)u\"inch\",\n            length = 30u\"inch\",\n            width = 30u\"inch\",\n            cost = 36.00)\n      ])","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Now we can figure out where to make the cuts.  We can multiply our list of WantedPanels by an integer if we want to make several boxes.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"searcher = Searcher(BOULTER_PLYWOOD, 2 * WantedPanels(my_box))\nsearch(searcher)\nsearcher.cheapest.finished","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"We would like a clearer description though:","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"report(searcher;\n       includeCutDiagram=true,\n       includeCutGraph=false,\n       filename=\"box_example_panel_cut_report.html\")","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"View the result.","category":"page"},{"location":"box_example/#Box-Faces","page":"Boxes","title":"Box Faces","text":"","category":"section"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Modules = [ PanelCutting ]\nOrder = [ :type ]\nFilter = t -> t <: PanelCutting.Face","category":"page"},{"location":"box_example/#PanelCutting.Back","page":"Boxes","title":"PanelCutting.Back","text":"The back face of a Box.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.Bottom","page":"Boxes","title":"PanelCutting.Bottom","text":"The bottom face of a Box.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.Face","page":"Boxes","title":"PanelCutting.Face","text":"Face\n\nFace is the abstract supertype for the tokens that identify each face of a Box.\n\nSubtypes are Top, Bottom, Left, Right, Front and Back, which are all singleton types.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.Front","page":"Boxes","title":"PanelCutting.Front","text":"The front face of a Box.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.Left","page":"Boxes","title":"PanelCutting.Left","text":"The left face of a Box.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.Right","page":"Boxes","title":"PanelCutting.Right","text":"The right face of a Box.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.Top","page":"Boxes","title":"PanelCutting.Top","text":"The top face of a Box.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#Edges","page":"Boxes","title":"Edges","text":"","category":"section"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Between each pair of adjacent faces is an Edge.  For each edge, the type of joinery to be used at that edge can be specified.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Edge","category":"page"},{"location":"box_example/#PanelCutting.Edge","page":"Boxes","title":"PanelCutting.Edge","text":"Edge(::Face, ::Face)\n\nThe edge of the box that connects the two specified faces.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#Grain-Direction","page":"Boxes","title":"Grain Direction","text":"","category":"section"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"For each face of a box, one can specify the grain direction.","category":"page"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Modules = [ PanelCutting ]\nOrder = [ :type ]\nFilter = t -> t <: PanelCutting.GrainDirection","category":"page"},{"location":"box_example/#PanelCutting.GDEither","page":"Boxes","title":"PanelCutting.GDEither","text":"GDEither\n\nUse GDEither() if you don't care whether the grain runs parallel to the long or short edges of the panel.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.GDLong","page":"Boxes","title":"PanelCutting.GDLong","text":"GDLong\n\nUse GDLong() to indicate that the grain of the face should run parallel to its longer edges.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.GDShort","page":"Boxes","title":"PanelCutting.GDShort","text":"GDShort\n\nUse GDShort() to indicate that the grain of the face should run parallel to its shorter edges.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.GrainDirection","page":"Boxes","title":"PanelCutting.GrainDirection","text":"GrainDirection\n\nGrainDirection is the abstract type for the choices of how the grain direction of the stock is oriented with respect to the shape of the panel.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#Joint-Type","page":"Boxes","title":"Joint Type","text":"","category":"section"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Modules = [ PanelCutting ]\nOrder = [ :type ]\nFilter = t -> t <: PanelCutting.JointType","category":"page"},{"location":"box_example/#PanelCutting.ButtJoint","page":"Boxes","title":"PanelCutting.ButtJoint","text":"ButtJoint(shortened)\n\nIf the joint type specified for a pair of Faces is a ButtJoint, then the face specified by shortened is shortened by the thickness of the other face.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.DadoJoint","page":"Boxes","title":"PanelCutting.DadoJoint","text":"DadoJoint(tongued::Face, tongue_length::LengthType)\n\nIf the joint type specified for a pair of faces is a DadoJoint, then the face specified by tongued is shortened by the thickness of the other face and then lengthened by tongue_length.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.FingerJoint","page":"Boxes","title":"PanelCutting.FingerJoint","text":"FingerJoint\n\nIf the joint type specified for a pair of faces is FingerJoint then the size of neither panel needs to be adjusted for that joint.\n\nIf you intend to make blind finger or dovetail joints, use DadoJoint.\n\nIf you want a miter joint, use FingerJoint.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.JointType","page":"Boxes","title":"PanelCutting.JointType","text":"JointType\n\nThe abstract supertype for objects describing the joint type bwtween two faces.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#Related-Definitions","page":"Boxes","title":"Related Definitions","text":"","category":"section"},{"location":"box_example/","page":"Boxes","title":"Boxes","text":"Box\ndistance\ndo_faces\nneighbors\nopposite\nWantedPanels","category":"page"},{"location":"box_example/#PanelCutting.Box","page":"Boxes","title":"PanelCutting.Box","text":"Box(length::LengthType, width::LengthType, height::LengthType)\n\nDefine a box of the spcified dimensions.\n\n\n\n\n\n","category":"type"},{"location":"box_example/#PanelCutting.distance","page":"Boxes","title":"PanelCutting.distance","text":"distance(::Box, ::Face, ::Face)\n\nReturn the outside dimension of the box between the two faces.\n\n\n\n\n\n","category":"function"},{"location":"box_example/#PanelCutting.do_faces","page":"Boxes","title":"PanelCutting.do_faces","text":"do_faces(::Function, ::Box)\n\nApply the function to each face of the Box that is not open/missing.\n\n\n\n\n\n","category":"function"},{"location":"box_example/#PanelCutting.neighbors","page":"Boxes","title":"PanelCutting.neighbors","text":"neighbors(face1::Face, face2::Face)::Boll\n\nReturn true if face1 is a neighbor of face2.\n\n\n\n\n\nneighbors(face::Face)\n\nReturn the Faces that are adjacent to the specified Face.\n\n\n\n\n\n","category":"function"},{"location":"box_example/#PanelCutting.opposite","page":"Boxes","title":"PanelCutting.opposite","text":"opposite(::Face)::Face\n\nReturn the Face that is opposite to the specified face.\n\n\n\n\n\n","category":"function"},{"location":"box_example/#PanelCutting.WantedPanels","page":"Boxes","title":"PanelCutting.WantedPanels","text":"WantedPanels(::Box)\n\nReturn the collection of WantedPanels to make the Box.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.jl","page":"Home","title":"PanelCutting.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package implements a utility for determining the optimal sequence of cuts to produce a set of rectangular panels of specified sizes from sheet good stock (e.g. plywood).","category":"page"},{"location":"","page":"Home","title":"Home","text":"New users will probably want to go straight to the box example to get started.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Pages = [ \"index.md\" ]\nDepth = 6","category":"page"},{"location":"#Panels","page":"Home","title":"Panels","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The search is mediated by a progression of panels of various types:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [ PanelCutting ]\nOrder = [ :type ]\nFilter = t -> t <: PanelCutting.AbstractPanel","category":"page"},{"location":"#PanelCutting.AvailablePanel","page":"Home","title":"PanelCutting.AvailablePanel","text":"AvailablePanel\n\nA sheet of plywood we can buy from the lumber yard.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.BoughtPanel","page":"Home","title":"PanelCutting.BoughtPanel","text":"BoughtPanel\n\na BoughtPanel is created to wrap an AvailablePanel when we add it to the working set.  This ensured that when it is cut it has a distinct identity from any other BoughtPanel of the same size.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.FinishedPanel","page":"Home","title":"PanelCutting.FinishedPanel","text":"FinishedPanel\n\nFinishedPanel wraps a Panel that matches an AbstractWantedPanel and associates that AbstractWantedPanel with the cut Panel.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.FlippedPanel","page":"Home","title":"PanelCutting.FlippedPanel","text":"FlippedPanel\n\nFlippedPanel wraps a WantedPanel to indicate that its want can be satisfied by a panel even if its length and width are swapped.\n\nThis allows the user to control whether flipping is allowed of if they care about grain direction.\n\nWhen either the original or the flipped panel is finished then its counterpart will be removed from the unsatisfied wants as well.  The function wantsmatch is used for this test.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.Panel","page":"Home","title":"PanelCutting.Panel","text":"Panel\n\nPanel represents a panel that has been cut from an AvailablePanel but does not yet match an AbstractWantedPanel.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.ScrappedPanel","page":"Home","title":"PanelCutting.ScrappedPanel","text":"ScrappedPanel\n\nScrappedPanel wraps a Panel that is not big enough to cut any remaining AbstractWantedPanel from.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.WantedPanel","page":"Home","title":"PanelCutting.WantedPanel","text":"WantedPanel\n\nWantedPanel describes a panel that we need to have cut from some sheet stock.  A Set of AbstractWantedPanels establishes the goal of our search.\n\n\n\n\n\n","category":"type"},{"location":"","page":"Home","title":"Home","text":"Panels\nprogenitor\nPanelOverlapError","category":"page"},{"location":"#PanelCutting.Panels","page":"Home","title":"PanelCutting.Panels","text":"Panels\n\nAn immutable collections of Panels\n\nOur SearchState objects contain several collections of panels.  We'd like these collections to be immutable, like the SearchStates themselves.\n\nWhen transitioning from one SearchState to its possible successor states, these collections could change in the following ways:\n\na WantedPanel and possibly its flipped counterpart, might be removed and a FinishedPanel added\none or two CuttablePanels added to stock panels\nCuttablePanels moved from stock to waste if they are too small for any remaining wanted panels\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.progenitor","page":"Home","title":"PanelCutting.progenitor","text":"progenitor(panel)\n\nReturn the BoughtPanel that this panel was cut from.\n\nAn AbstractPanel is its own progenitor.\n\nA WantedPanel is its own progenitor.\n\nA FlippedPanel is its own progenitor.\n\nprogenitor is used in the overlap test: panels can not overlap if they have different progenitors.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.PanelOverlapError","page":"Home","title":"PanelCutting.PanelOverlapError","text":"PanelOverlapError\n\nAn error that is thrown when panels that shouldn'y overlap do.\n\n\n\n\n\n","category":"type"},{"location":"#Methodology","page":"Home","title":"Methodology","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"We start with a goal of producing a set of WantedPanels of specified sizes.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We then select an AvailablePanel and cut it.  Each cut potentially produces two new offcut Panels.","category":"page"},{"location":"","page":"Home","title":"Home","text":"When one of these Panels matches a WanterPanel we associate that Panel with the WantedPanel using a FinishedPanel.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We give Panels an X and Y 'origin' origin as well as a length (along x) and width (along y) to simplify SVG generation.","category":"page"},{"location":"#Everything-Else","page":"Home","title":"Everything Else","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"AllOf\narea\nSTYLESHEET\nSVG_PANEL_MARGIN\nPanelCutting.callerFile\ncompatible\ncut\nelt\nfitsin\ninPluto\nmajor\nminor\norFlipped\nother\npanelUID\npanelrect\nreplace0\nreport\nPanelCutting.runCmd\nsmaller\nSearcher\nSupplier\nsvgdistance","category":"page"},{"location":"#PanelCutting.AllOf","page":"Home","title":"PanelCutting.AllOf","text":"Allof(iterables...)\n\ncombine the iterables into a single iterable.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.area","page":"Home","title":"PanelCutting.area","text":"area(panel)\n\nReturn the area of the panel.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.STYLESHEET","page":"Home","title":"PanelCutting.STYLESHEET","text":"The CSS stylesheet we use for SVG rendering in reports.\n\n\n\n\n\n","category":"constant"},{"location":"#PanelCutting.SVG_PANEL_MARGIN","page":"Home","title":"PanelCutting.SVG_PANEL_MARGIN","text":"The space between panels in an SVG drawing, and space between panels and SVG edge.\n\n\n\n\n\n","category":"constant"},{"location":"#PanelCutting.callerFile","page":"Home","title":"PanelCutting.callerFile","text":"callerFile()\n\nReturn the path of the file of the function that called callerFile's caller. Also return the line number.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.compatible","page":"Home","title":"PanelCutting.compatible","text":"compatible(panel, panel2):Bool\n\nReturn true if the panels have the same thickness and material.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.cut","page":"Home","title":"PanelCutting.cut","text":"cut(panel, axis, at; kerf, cost)::(panel1, panel2)\n\nCut panel at the specified distance along axis. The first returned panel is the piece cut to that distance. The second is what remains (accounting for kerf).\n\nAn empty Tuple is returned if the cut can't be made.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.elt","page":"Home","title":"PanelCutting.elt","text":"elt(f, tagname::AbstractString, things...)\nelt(tagname::AbstractString, things...)\n\nReturn an XML element.  f is called with a single argument: either an XML.AbstractXMLNode or a Pair describing an XML attribute to be added to the resulting element.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.fitsin","page":"Home","title":"PanelCutting.fitsin","text":"fitsin(small::AbstractPanel, big::AbstractPanel)::Bool\n\nSee if small can be cut from big.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.inPluto","page":"Home","title":"PanelCutting.inPluto","text":"inPluto()::Bool\n\nReturn true if the notebook is being run in Pluto, artyher than directly in Julia (e.g. command line or REPL).\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.major","page":"Home","title":"PanelCutting.major","text":"major(panel)\n\nReturn the greater of the Panel's two dimensions.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.minor","page":"Home","title":"PanelCutting.minor","text":"minor(panel)\n\nReturn the lesser of the Panel's two dimensions.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.orFlipped","page":"Home","title":"PanelCutting.orFlipped","text":"orFlipped(::WantedPanel)\n\nReturn a Vector of AbstractWantedPanel consisting of the WantedPanel and possibly its corresponding FlippedPanel.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.other","page":"Home","title":"PanelCutting.other","text":"other(axis)\n\nreturns the axis that is perpendicular to the specified axis.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.panelUID","page":"Home","title":"PanelCutting.panelUID","text":"panelUID()\n\nGenerate a unique identifier for each panel when it is created. We do this because Julia does not have a notion of equality that distibguishes between two separately created immutable structs with the same contents.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.panelrect","page":"Home","title":"PanelCutting.panelrect","text":"panelrect(panel::AbstractPanel, numbering::FinishedPanelNumbering)\n\nReturn an SVG element that will draw the representation of the panel.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.replace0","page":"Home","title":"PanelCutting.replace0","text":"replace0(defaultX, defaultY, newX, newY)\n\nReturn newX and newY so long as they are not 0. If zero, use the corresponding default value.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.report","page":"Home","title":"PanelCutting.report","text":"report(::Searcher)\n\nGenerate an HTML fragment that provides a detailed report of our cut search and results.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.runCmd","page":"Home","title":"PanelCutting.runCmd","text":"runCmd(cmd::Cmd, cmdOutput::IO)::IO\n\nRun the external command cmd, which will write output to cmdOutput. The stream that's returnd can be written to to provide inoput to the command.  The second return value is the stderr stream.\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.smaller","page":"Home","title":"PanelCutting.smaller","text":"smaller(p1::AbstractPanel, p2::AbstractPanel)::Bool\n\nAn ordering function for sorting panels by size. smaller(p1, p2) does not imply fitsin(p1, p2).\n\n\n\n\n\n","category":"function"},{"location":"#PanelCutting.Searcher","page":"Home","title":"PanelCutting.Searcher","text":"Searcher\n\nThis Searcher implements A* search using a PriorityQueue.\n\nOne could implement other searchers to implement, for example, depth or breadth first search.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.Supplier","page":"Home","title":"PanelCutting.Supplier","text":"Supplier(name::String, costpercut, kerf, available_stock::Vector{AvailablePanel})\n\nA single supplier of sheet stock.\n\nSome suppliers will cut shet stock down to the customer's specifications.  kerf is the width of their saw custs. cost_per_cut is what they charge for each cut.\n\n\n\n\n\n","category":"type"},{"location":"#PanelCutting.svgdistance","page":"Home","title":"PanelCutting.svgdistance","text":"svgdistance(d)\n\nTurn a Unitful length quantity to a floating point number we can use in SVG.\n\n\n\n\n\n","category":"function"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"}]
}