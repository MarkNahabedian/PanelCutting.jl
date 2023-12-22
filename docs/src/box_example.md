# Using the Box type to define your panels

It's inconvenient to have to modify the dimensions of panels depending
on what type of joinery will be used.  The `Box` type is intended to
address this difficulty.

The outside dimensions of a `Box` are specified by its length, width
and height.




By default a box has six faces.  Each face is identified by an
instance of a singleton type:

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.Face
```

For each face of the box, one can specify that that face is
open/missing, or the material and thickness of stock from which to cut
that face.


### Grain Direction

For each face of a box, one can specify the grain direction.

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.GrainDirection
```


## Edges

Between each pair of adjacent faces is an `Edge`.  For each edge, the
type of joinery to be used at that edge can be specified.

```@docs
Edge
```


### Joint Type

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.JointType
```

## Defining a box

A box is first specified by its outside dimensions.

```@docs
Box
```

```@example box1
using PanelCutting, Unitful

my_box = Box(0.3u"m", 0.2u"m", 0.1u"m")
```

Once the box is defined, one can specify the thickness and material of
each face, whether a face is open, and its grain direction:

```@example box1
my_box.open[Top()] = true

do_faces(my_box) do face
    my_box.thickness[face] = 5u"mm"
    my_box.material[face] = "Baltic Birch"
end
```

One can also specify the joint type to be used for each edge:

```@example box1
let
    sides = [Left(), Back(), Right(), Front()]
    for i in 0:(length(sides) - 1)
        e = Edge(sides[i + 1],
                 sides[1 + (i + 1) % length(sides)])
        my_box.joint_types[e] = FingerJoint()
    end
    for n in neighbors(Bottom())
        edge = Edge(Bottom(), n)
        my_box.joint_types[edge] = DadoJoint(Bottom(), 2u"mm")
    end
end
```

Once the box is fully specified, we can ask for its `WantedPanel`s:

```@example box1
WantedPanels(my_box)
```

## Related Functions

```@docs
distance
do_faces
neighbors
opposite
WantedPanels
```

