
# Describe a box to generate WantedPanels for it.

export Face, Top, Bottom, Left, Right, Front, Back
export do_faces
export opposite, neighbors
export Edge
export GrainDirection, GDLong, GDShort, GDEither
export JointType, FingerJoint, ButtJoint, DadoJoint
export Box, WantedPanels

"""
    Face

Face is the abstract supertype for the tokens that identify each face
of a Box.

Subtypes are Top, Bottom, Left, Right, Front and Back, which are all
singleton types.
"""
abstract type Face end


"""
    opposite(::Face)::Face

Return the `Face` that is opposite to the specified face.
"""
function opposite end

map(eval,
    let
        structs = []
        opposites = []
        np = []
        pairs = Set(((:Top, :Bottom), (:Left, :Right), (:Front, :Back)))
        for p in pairs
            function make(x)
                if x isa Symbol
                    Expr(:call, x)
                else
                    Expr(:tuple, map(make, x)...)
                end
            end
            others = make(collect(setdiff(pairs, Set([p]))))
            for t in p
                push!(structs,
                      :(struct $t <: Face end),
                      Expr(:call, Base.Docs.doc!, @__MODULE__,
                           Expr(:call, Base.Docs.Binding, @__MODULE__,
                                QuoteNode(t)),
                           Expr(:call, Base.Docs.docstr,
                                "The **" * lowercase(string(t)) *
                                    "** face of a `Box`.",
                                Dict{Symbol, Any}(
                                    :path => @__FILE__,
                                    :linenumber => @__LINE__,
                                    :module => @__MODULE__))))
                push!(np,
                      :(neighbor_pairs(::$t) = $others))
            end
            push!(opposites,
                  :(opposite(::$(p[1])) = begin $(p[2])() end),
                  :(opposite(::$(p[2])) = begin $(p[1])() end))
        end
        [ structs..., opposites..., np... ]
    end)


"""
   neighbors(face1::Face, face2::Face)::Boll

Return true if face1 is a neighbor of face2.
"""
neighbors(face1::Face, face2::Face)::Bool = face2 in neighbors(face1)


"""
    neighbors(face::Face)

Return the `Face`s that are adjacent to the specified `Face`.
"""
neighbors(face::Face) = Base.Iterators.Flatten(neighbor_pairs(face))


"""
    Edge(::Face, ::Face)

The edge of the box that connects the two specified faces.
"""
struct Edge
    face1::Face
    face2::Face

    function Edge(face1::Face, face2::Face)
        @assert face1 != face2
        @assert face1 != opposite(face2)
        @assert neighbors(face1, face2)
        new(face1, face2)
    end
end

Base.hash(e::Edge) = hash(e.face1) + hash(e.face2)

Base.:(==)(fp1::Edge, fp2::Edge) =
    (fp1.face1 == fp2.face1 && fp1.face2 == fp2.face2) ||
    (fp1.face1 == fp2.face2 && fp1.face2 == fp2.face1)



"""
    GrainDirection

GrainDirection is the abstract type for the choices of how the grain
direction of the stock is oriented with respect to the shape of the
panel.
"""
abstract type GrainDirection end


"""
    GDLong

Use `GDLong()` to indicate that the grain of the face should run
parallel to its longer edges.
"""
struct GDLong <: GrainDirection end


"""
    GDShort

Use `GDShort()` to indicate that the grain of the face should run
parallel to its shorter edges.
"""
struct GDShort <: GrainDirection end


"""
    GDEither

Use `GDEither()` if you don't care whether the grain runs parallel to the
long or short edges of the panel.
"""
struct GDEither <: GrainDirection end


"""
    JointType

The abstract supertype for objects describing the joint type bwtween
two faces.
"""
abstract type JointType end


"""
    FingerJoint

If the joint type specified for a pair of faces is FingerJoint
then the size of neither panel needs to be adjusted for that joint.

If you intend to make blind finger or dovetail joints, use DadoJoint.

If you want a miter joint, use FingerJoint.
"""
struct FingerJoint <: JointType end


"""
    ButtJoint(shortened)

If the joint type specified for a pair of Faces is a ButtJoint, then the
face specified by `shortened` is shortened by the thickness of the
other face.
"""
struct ButtJoint <: JointType
    shortened::Face
end


"""
    DadoJoint(tongued::Face, tongue_length::LengthType)

If the joint type specified for a pair of faces is a DadoJoint, then
the face specified by `tongued` is shortened by the thickness of the
other face and then lengthened by `tongue_length`.
"""
struct DadoJoint <: JointType
    tongued::Face
    tongue_length::LengthType
end


"""
    Box(length::LengthType, width::LengthType, height::LengthType)

Define a box of the spcified dimensions.
"""
@Base.kwdef struct Box
    # Outside dimensions:
    length::LengthType              # Front to Back
    width::LengthType               # Left to Right
    height::LengthType              # Top to Bottom

    # Fanel thickness for each Face:
    thickness = DefaultDict((1/4)u"inch")

    # Panel material for each Face
    material = DefaultDict(nothing)

    # missing or open Faces:
    open = DefaultDict(false)

    # Grain direction for each face:
    grain_direction = DefaultDict(GDLong())

    # Joint type for each Edge:
    joint_types = DefaultDict(FingerJoint())
end

Box(length::LengthType, width::LengthType, height::LengthType) =
    Box(; length = length, width = width, height = height)


"""
    do_faces(::Function, ::Box)

Apply the function to each face of the Box that is not open/missing.
"""
function do_faces(f::Function, box::Box)
    for ft in subtypes(Face)
        face = ft()
        if !box.open[face]
            f(face)
        end
    end
end

"""
    distance(::Box, ::Face, ::Face)

Return the outside dimension of the box between the two faces.
"""
distance(box::Box, ::Left, ::Right) = float(box.width)
distance(box::Box, ::Right, ::Left) = float(box.width)
distance(box::Box, ::Top, ::Bottom) = float(box.height)
distance(box::Box, ::Bottom, ::Top) = float(box.height)
distance(box::Box, ::Front, ::Back) = float(box.length)
distance(box::Box, ::Back, ::Front) = float(box.length)


"""
    length_adjust(::Box, face::Face, neighbor::Face)

Return how much length should be added to the relevant dimension of
`face` based on its `JointType` with `neighbor`.
"""
function length_adjust(box::Box, face::Face, neighbor::Face)::LengthType
    length_adjust(box, box.joint_types[Edge(face, neighbor)], face, neighbor)
end

function length_adjust(box::Box, joint::JointType, face::Face, neighbor::Face)::LengthType
    error("No length_adjust method for $box, $joint, $face, $neighbor")
end

function length_adjust(::Box, ::FingerJoint, ::Face, ::Face)::LengthType
    0u"inch"
end

function length_adjust(box::Box, joint::ButtJoint, face::Face, neighbor::Face)::LengthType
    if face == joint.shortened
        - box.thickness[neighbor]
    else
        0u"inch"
    end
end

function length_adjust(box::Box, joint::DadoJoint, face::Face, neighbor::Face)::LengthType
    if face == joint.tongued
        joint.tongue_length - box.thickness[neighbor]
    else
        0u"inch"
    end
end


# How do we know which dimension to adjust?

# A method on Box, Face, Face could give us the unadjusted distance
# betweeen the two faces, but those are not the faces to adjust.
# Maybe we define a Faces naighbors as tow two element tuples.


function WantedPanels(box::Box, face::Face)::Vector{AbstractWantedPanel}
    if box.open[face]
        return []
    end
    thickness = box.thickness[face]
    material = box.material[face]
    grain_direction = box.grain_direction[face]
    dimensions = []
    for np in neighbor_pairs(face)
        d = distance(box, np...)
        for n in np
            if !box.open[n]
                d += length_adjust(box, face, n)
            end
        end
        push!(dimensions, d)
    end
    @assert Base.length(dimensions) == 2
    length = max(dimensions...)
    width = min(dimensions...)
    if grain_direction isa GDShort
        length, width = width, length
    end
    wp = WantedPanel(label = string(typeof(face)),
                     thickness = thickness,
                     material = material,
                     length = length,
                     width = width)
    if grain_direction isa GDEither
        return orFlipped(wp)
    end
    return push!(Vector{AbstractWantedPanel}(), wp)
end


"""
    WantedPanels(::Box)

Return the collection of `WantedPanel`s to make the `Box`.
"""
function WantedPanels(box::Box)::Vector{AbstractWantedPanel}
    wanted = Vector{AbstractWantedPanel}()
    do_faces(box) do face
        push!(wanted, WantedPanels(box, face)...)
    end
    wanted
end

# We can unfold a box into a "disected cube" SVG drawing that shows
# grain direction and joint type.
