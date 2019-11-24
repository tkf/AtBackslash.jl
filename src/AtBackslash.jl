module AtBackslash

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end AtBackslash

export @\

using Base.Meta: isexpr

function is_interpolation(ex)
    isexpr(ex, :$) || return false
    if length(ex.args) != 1 || isexpr(ex.args[1], :tuple)
        error("Only single-argument \$ is supported. Got: ", ex)
    end
    return true
end

"""
    @\\(NCT1, NTC2, ..., NTCn) :: NamedTuple
    @\\(; NCT1, NTC2, ..., NTCn) :: NamedTuple
    @\\(expr)
"""
macro \(args...)
    @gensym input

    replace_symbols(x) = x
    replace_symbols(x::QuoteNode) =
        if x.value isa Symbol
            :($input.$(x.value))
        else
            x
        end
    replace_symbols(x::Symbol) =
        if x === :_
            input
        else
            esc(x)
        end
    replace_symbols(ex::Expr) =
        if isexpr(ex, :...) && ex.args == [:_]
            :($input...)
        elseif isexpr(ex, :parameters)
            args = map(ex.args) do x
                if x isa Symbol
                    Expr(:(=), esc(x), replace_symbols(x))
                elseif x isa QuoteNode && x.value isa Symbol
                    Expr(:(=), esc(x.value), replace_symbols(x))
                else
                    replace_symbols(x)
                end
            end
            Expr(ex.head, args...)
        elseif is_interpolation(ex)
            # Should I still replace `_`?
            esc(ex.args[1])
        elseif isexpr(ex, :.)
            Expr(:., replace_symbols(ex.args[1]), ex.args[2:end]...)
        elseif isexpr(ex, :macrocall)
            esc(ex)
        else
            Expr(ex.head, replace_symbols.(ex.args)...)
        end

    if args == (:_,)
        # Should I?
        error("`@\\_` not supported. Use `identity`.")
    end

    #! format: off
    if (
        length(args) == 1 &&
        ((args[1] isa QuoteNode && args[1].value isa Symbol) || args[1] isa Symbol)
    )
        ex, = args
        error(
            "Ambiguous expression: `@\\($ex)`\n",
            "Use `@\\(_.$ex)` if you mean `x -> x.$ex`.\n",
            "Use `@\\(; $ex)` if you mean `x -> ($ex = x.$ex,)`.",
        )
    end
    #! format: on

    # Handle: @\(_..., a=x+1, b) :: NamedTuple
    all(args) do x
        (x isa Symbol ||
         (x isa QuoteNode && x.value isa Symbol) ||
         (is_interpolation(x) && x.args[1] isa Symbol) ||
         (isexpr(x, :(=)) && x.args[1] isa Symbol) ||
         (isexpr(x, :...) && x.args == [:_]))
    end && begin
        return :($input -> $(replace_symbols(Expr(:tuple, Expr(:parameters, args...)))))
    end

    # Handle: @\(; KEY => VAL) :: NamedTuple
    if length(args) == 1 && isexpr(args[1], :parameters)
        return :($input -> $(replace_symbols(Expr(:tuple, args[1]))))
    end

    # Handle: @\[a, b] :: Array
    # Handle: @\(x > y) :: Bool
    if length(args) == 1
        return :($input -> $(replace_symbols(args[1])))
    end

    error("Unsupported expression:\n", "@\\", Expr(:tuple, args...))
end

end # module
