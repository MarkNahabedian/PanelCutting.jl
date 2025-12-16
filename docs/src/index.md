# PanelCutting.jl

This package implements a utility for determining the optimal sequence
of cuts to produce a set of rectangular panels of specified sizes from
sheet good stock (e.g. plywood).

New users will probably want to go straight to the
[box example](box_example.md) to get started.


```@contents
Pages = [ "index.md" ]
Depth = 6
```


## Panels

The search is mediated by a progression of **panels** of various types:

```@autodocs
Modules = [ PanelCutting ]
Order = [ :type ]
Filter = t -> t <: PanelCutting.AbstractPanel
```

```@docs
Panels
progenitor
PanelOverlapError
```


## Methodology

We start with a goal of producing a set of `WantedPanel`s of specified
sizes.

We then select an `AvailablePanel` and cut it.  Each cut
potentially produces two new offcut Panels.

When one of these Panels matches a `WanterPanel` we associate that `Panel`
with the `WantedPanel` using a `FinishedPanel`.

We give Panels an X and Y 'origin' origin as well as a length (along
x) and width (along y) to simplify SVG generation.


## Everything Else

```@docs
AllOf
area
STYLESHEET
SVG_PANEL_MARGIN
compatible
cut
fitsin
inPluto
major
minor
orFlipped
other
panelUID
panelrect
replace0
report
PanelCutting.runCmd
smaller
Searcher
Supplier
svgdistance
```

## Index

```@index
```
