# Using the Box type to define your panels

Sheet stock is typically used for making boxes, cabinets and drawers,
all of which have a rectangular crosssection on each axis.

A [`Box`](@ref) is first specified by its outside dimensions.  The
`Unitful` package (and optionally `UnitfulUS`) are used so we can
specify units for the box dimensions.



```@example box1
using PanelCutting, Unitful, UnitfulUS

my_box = Box(0.3u"m", 0.2u"m", 0.1u"m")
```

The `Box` has six faces which are identified by singleton types.  The
faces come in three opposite pairs: [`Top`](@ref) and
[`Bottom`](@ref), [`Left`](@ref) and [`Right`](@ref), and
[`Front`](@ref) and [`Back`](@ref).

Once a box is defined, one can specify whether each face is open, or
the thickness of the panel for that face.  One can also specify what
material should be used.

```@example box1
my_box.open[Top()] = true

do_faces(my_box) do face
    # All faces are 5mm baltic birch:
    my_box.thickness[face] = (1/4)u"inch"
    my_box.material[face] = "Baltic Birch"
end
```

For each face of a box, one can also specify the grain direction (also
represented by singleton types), one of [`GDLong`](@ref)(the default),
[`GDShort`](@ref) or [`GDEither`](@ref).

```@example box1
my_box.grain_direction[Bottom()] = GDEither()
```

A `Box` also has edges.  An edge is identified by a pair of faces.
`Edge(Front(), Bottom())` specifies the edge where the bottom and
front panels of the box meet.

One can specify the joint type to be used for each edge.  The joint
type affects this sizes of the panels which meet at that edge.  For a
butt joint, one face is shortened by the thickness of the other.  For
a finger joint, both panels would be at full length.  For a
dado/tongue and grrove joint, one panel is shortened by the thickness
of the other but lengthened by the tongue length.

```@example box1
let
    # Use finger joints between each pair of sides:
    sides = [Left(), Back(), Right(), Front()]
    for i in 0:(length(sides) - 1)
        e = Edge(sides[i + 1],
                 sides[1 + (i + 1) % length(sides)])
        my_box.joint_types[e] = FingerJoint()
    end
    # Use a dado joint for each edge of the bottom:
    for n in neighbors(Bottom())
        edge = Edge(Bottom(), n)
        my_box.joint_types[edge] = DadoJoint(Bottom(), 2u"mm")
    end
end
```

Once the box is fully specified, we can ask about the panels it
requires, its `WantedPanel`s:

```@example box1
WantedPanels(my_box)
```


To make our box, we first need sheet stock, which comes from a
Supplier.

```@example box1
BOULTER_PLYWOOD = Supplier(
    name = "Boulter Plywood",
    kerf = (1/8)u"inch",
    cost_per_cut = money(1.50),
    available_stock = [
        AvailablePanel(;
            label = "1/4 5 × 5 Baltic Birch",
            material = "Baltic Birch",
            thickness = (1/4)u"inch",
            length = 5u"ft",
            width = 5u"ft",
            cost = 84.00   # I've not been able to get UnitfulCurrency to work
        ),
        AvailablePanel(;
            label = "1/4 30 × 60 Baltic Birch",
            material = "Baltic Birch",
            thickness = (1/4)u"inch",
            length = 60u"inch",
            width = 30u"inch",
            cost = 51.00
        ),
        AvailablePanel(;
            label = "1/4 30 × 30 Baltic Birch",
            material = "Baltic Birch",
            thickness = (1/4)u"inch",
            length = 30u"inch",
            width = 30u"inch",
            cost = 36.00)
      ])
```

Now we can figure out where to make the cuts.  We can multiply our
list of WantedPanels by an integer if we want to make several boxes.

```@example box1
searcher = Searcher(BOULTER_PLYWOOD, 2 * WantedPanels(my_box))
search(searcher)
searcher.cheapest.finished
```

We would like a clearer description though:

```@example box1
report(searcher;
       includeCutDiagram=true,
       includeCutGraph=false,
       filename="box_example_panel_cut_report.html")
```



## Box Faces

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.Face
```


## Edges

Between each pair of adjacent faces is an `Edge`.  For each edge, the
type of joinery to be used at that edge can be specified.

```@docs
Edge
```


## Grain Direction

For each face of a box, one can specify the grain direction.

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.GrainDirection
```


## Joint Type

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.JointType
```


## Related Definitions

```@docs
Box
distance
do_faces
neighbors
opposite
WantedPanels
```

