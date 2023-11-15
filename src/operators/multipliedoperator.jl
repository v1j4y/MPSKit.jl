"""
    Structure representing a multiplied operator. Consists of
        - An operator op (MPO, Hamiltonian, ...)
        - An object f that gets multiplied with the operator (Number, function, ...) 
"""
struct MultipliedOperator{O,F}
    op::O
    f::F
end

"""
    Structure representing a time-dependent operator. Consists of
        - An operator op (MPO, Hamiltonian, ...)
        - An function f that gives the time-dependence according to op(t) = f(t)*op
"""
const TimedOperator{O} = MultipliedOperator{O,<:Function}

"""
    Structure representing a time-independent operator that will be multiplied with a constant coefficient. Consists of
        - An operator (MPO, Hamiltonian, ...)
        - A number f that gets multiplied with the operator
"""
const UntimedOperator{O} = MultipliedOperator{O,<:Union{Real,Nothing}}
const OnlyOperator{O} = MultipliedOperator{O,<:Nothing}

#constructors for (un)TimedOperator
TimedOperator(x::O, f::F) where {F<:Function,O} = MultipliedOperator(x, f)
UntimedOperator(x::O, c::C) where {C<:Real,O} = MultipliedOperator(x, c)

OnlyOperator(x) = MultipliedOperator(x,nothing)
TimedOperator(x) = OnlyOperator(x)
UntimedOperator(x) = OnlyOperator(x)

# promoting operators to MultipliedOperator
Base.promote_rule(::Type{<:MultipliedOperator},::Type{S}) where {S} = MultipliedOperator
Base.promote_rule(::Type{<:UntimedOperator},::Type{<:MultipliedOperator}) = MultipliedOperator
Base.promote_rule(::Type{<:UntimedOperator},::Type{O}) where {O} = UntimedOperator
Base.promote_rule(::Type{S},::Type{T}) where {S<:UntimedOperator,T<:UntimedOperator} = UntimedOperator

Base.convert(::Type{T},x::T) where {T<:MultipliedOperator} = x # maybe this can be prevented by defining an appropriate promote_rule?
Base.convert(::Type{<:MultipliedOperator},x::O) where {O} = OnlyOperator(x)

# For internal use only
ConvertOperator(x::UntimedOperator) = x.f * x.op
ConvertOperator(x::MultipliedOperator{O,Nothing}) where {O} = x.op
ConvertOperator(x::TimedOperator, t::Number) = x.f(t) * x.op
ConvertOperator(x::O,args...) where {O} = x

# For users
(x::UntimedOperator)() = ConvertOperator(x)
(x::TimedOperator)(t::Number)  = ConvertOperator(x,t)

# what to do when we multiply by a scalar
function Base.:*(op::OnlyOperator, b::Number)
    return UntimedOperator(op.op, b)
end
function Base.:*(op::UntimedOperator, b::Number)
    return UntimedOperator(op.op, b * op.f)
end
function Base.:*(op::TimedOperator, b::Number)
    return TimedOperator(op.op, t -> b * op.f(t))
end
Base.:*(b::Number, op::MultipliedOperator) = op * b
#should probably also define a method that allows f(t)*TimedOperator, but I don't know how to dispatch on this

# don't know a better place to put this
# environment for MultipliedOperator
function environments(st, x::MultipliedOperator, args...; kwargs...)
    return environments(st, x.op, args...; kwargs...)
end
