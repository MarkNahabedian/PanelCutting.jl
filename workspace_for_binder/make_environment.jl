
# julia make_environment.jl

using Pkg

rm("./Project.toml"; force=true)
rm("./Manifest.toml"; force=true)

Pkg.activate(".")

Pkg.add([
    PackageSpec(;name="DataStructures",   version="0.18"),
    PackageSpec(;name="DisplayAs",        version="0.1"),
    PackageSpec(;name="Match",            version="1"),
    PackageSpec(;name="NativeSVG",        url="https://github.com/MarkNahabedian/NativeSVG.jl"),
    PackageSpec(;name="PanelCutting",
                url="https://github.com/MarkNahabedian/PanelCutting.jl"),
    PackageSpec(;name="Plots",            version="1.24.3"),  # later version might be broken.
    PackageSpec(;name="Revise",           version="3"),
    PackageSpec(;name="Unitful",          #=version="1"=#),
    # PackageSpec(;name="UnitfulCurrency", version="0.2"),
    PackageSpec(;name="UnitfulUS",        #=version="0.2"=#),
    PackageSpec(;name="VectorLogging",    url="https://github.com/MarkNahabedian/VectorLogging.jl")
    ])


