# An Example

Suppose we want to make an open-topped box whose outside dimensions
are 12 inches long, 6 inches wide and 4 inches deep out of 1/4 inch
plywood.

```@example 1
using PanelCutting
using Unitful
using UnitfulUS

box_length = 12u"inch"
box_width = 6u"inch"
box_depth = 4u"inch"
stock_thickness = (1/4)u"inch"
```


## What Do We Want?

To use `PanelCutting` we must first describe the target
dimensions of sheet stock after it is cut.  For each panel we must
make a `WantedPanel`.

Note that these dimensions don't account for any joinery.  For this
simple example all panels are butt jointed, with the sides and ends
sitting on top of the bottom and the ends inset between the sides.

Also note that we do not yet include the thickness of stock when
selecting material to cut.  so far my projects have been simple enough
that I've only needed one thickness of stock.  In the furure we should
also model stock thickness and material type.

```@example 1
WANTED = [
    WantedPanel(
        label = "bottom",
        # the bottom will occupy the full footprint of the box with
        # the sides and ends sitting on top of it
        length = box_length,
        width = box_width),
    # Sometimes we need several instances of the same shaped panel.
    # WantedPanel can take a pre-multiplier:
    (2 * WantedPanel(
        label = "side",
        length = box_length - 2 * stock_thickness,
        width = box_depth - stock_thickness)
     )...,  # Pre-multiplying gives a Vector, which we must spread.
    (2 * WantedPanel(
        label = "end",
        length = box_width - 2 * stock_thickness,
        width = box_depth - stock_thickness)
     )...
         ]
```

If you don't care about grain direction you can include a flipped
version of a `WantedPanel`:

```@example 1
orFlipped(WantedPanel(
    label = "bottom",
    length = box_length,
    width = box_width))
```

but we will not include these in our example.


## What Are We Starting With?

We must describe what sheet stock is available to cut from.  We
do this with `AvailablePanel`.  Each size of `AvailablePanel` only
needs to be instantiated once.  It is assumed that the supply of
`AvailablePanel`s is unlimited for our purposes.  These sizes and
prices are taken from my local plywood supplier.  My supplier will
accurately cut down stock to specified dimensions at a reasonable
price, so we also note the cost per cut and the kerf width:

```@example 1
BOULTER_PLYWOOD = Supplier(
    name = "Boulter Plywood",
    kerf = (1/8)u"inch",
    cost_per_cut = money(1.50),
    available_stock = [
        AvailablePanel(
            label = "1/4 5 × 5 Baltic Birch",
            length = 5u"ft",
            width = 5u"ft",
            cost=69.00   # I've not been able to get UnitfulCurrency to work
        ),
        AvailablePanel(
            label = "1/4 30 × 60 Baltic Birch",
            length = 60u"inch",
            width = 30u"inch",
            cost=42.00
        ),
        AvailablePanel(
            label = "1/4 30 × 30 Baltic Birch",
            length = 30u"inch",
            width = 30u"inch",
            cost=26.00)
      ])
```


## What To Buy And Where To Cut?

Now that we have described what we want and what we're starting with,
we can search for an optimal cut pattern.


```@example 1
# The cut optimization is performed by a Searcher:
searcher = Searcher(BOULTER_PLYWOOD, WANTED)
search(searcher)
```

The most efficient cut pattern (least expensive in terms of stock used
and number of cuts) is in `searcher.cheapest`. The resulting panels
there are represented by `FinishedPanel`s which have tracked how they
were cut:

```@example 1
searcher.cheapest.finished
```

We can generate a more readable report for our box:

```@example 1
report(searcher;
       includeCutDiagram=true,
       includeCutGraph=false,
       filename="example_panel_cut_report.html")
```
You can see the report
[here](example_panel_cut_report.html).

