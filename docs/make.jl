
insert!(LOAD_PATH, 1, joinpath(@__DIR__, ".."))

using Documenter
using PanelCutting

DocMeta.setdocmeta!(PanelCutting, :DocTestSetup, :(using PanelCutting); recursive=true)

makedocs(;
    modules=[PanelCutting],
    authors="MarkNahabedian <naha@mit.edu> and contributors",
    repo="https://github.com/MarkNahabedian/PanelCutting.jl/blob/{commit}{path}#{line}",
    sitename="PanelCutting.jl",
    checkdocs = :exports,
    warnonly = [:missing_docs],
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MarkNahabedian.github.io/PanelCutting.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md"
        "Example 1" => "example_1.md"
        "Boxes" => "box_example.md"
    ]
)

deploydocs(;
    repo="github.com/MarkNahabedian/PanelCutting.jl",
    devbranch="master"
)

