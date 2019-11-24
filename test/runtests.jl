module TestAtBackslash

using AtBackslash: @\, AtBackslash
using Documenter: doctest
using Test: @test, @testset

@testset "All bound" begin
    @test (x = 1, y = 2) |> @\(_..., a = :x + :y, y = 10) === (x = 1, y = 10, a = 3)
    @test (x = 1, y = 2) |> @\(:y, :x) === (y = 2, x = 1)
    @test (x = 1, y = 2) |> @\(:x < :y) === true
    @test (x = 1, y = 2) |> @\(:x < :y < 3) === true
    @test (x = 1, y = 2) |> @\(:x + 10) == 11
    @test (x = 1, y = 2) |> @\(; :x) === (x = 1,)
    @test (x = 1, y = 2) |> @\[:x, :y] == [1, 2]
    @test (x = 1, y = 2) |> @\[:x :y] == [1 2]
    @test (x = 1, y = 2) |> @\[:x :y; :y :x] == [1 2; 2 1]
    @test (x = 1, y = 2) |> @\[_] == [(x = 1, y = 2)]
    @test (x = 1, y = 2) |> @\[_ _] == [(x = 1, y = 2) (x = 1, y = 2)]
    @test (x = 1, y = 2) |> @\[(; :x, :y)] == [(x = 1, y = 2)]
    @test (x = 1, y = 2) |> @\[(; x = :x, y = :y)] == [(x = 1, y = 2)]
    @test (x = 1, y = 2, name = :x) |> @\(_[:name]) == 1
    @test (x = 1, y = 2, name = :x) |> @\(; :name => _[:name] + 10) === (x = 11,)
    @test (x = 1, y = 2, name = :x) |> @\((; :name => _[:name] + 10)) === (x = 11,)
    @test (x = 1, y = 2, name = :x) |> @\(; :name => _[:name] + 10, :y) === (x = 11, y = 2)
    @test (x = 1, y = 2, name = :x) |> @\((; :name => _[:name] + 10, :y)) === (
        x = 11,
        y = 2,
    )
    @test (x = 1, y = 2, name = :x) |> @\(; :name => _[:name] + 10, y = :y) === (
        x = 11,
        y = 2,
    )
    @test (x = 1, y = 2, name = :x) |> @\((; :name => _[:name] + 10, y = :y)) === (
        x = 11,
        y = 2,
    )
end

struct ObjectProxy
    dict::AbstractDict{Symbol}
end

Base.getproperty(obj::ObjectProxy, name::Symbol) = getfield(obj, :dict)[name]

@testset "NonNamedTuple" begin
    @test 1 + 2im |> @\(:re, :im) == (re = 1, im = 2)
    @test ObjectProxy(Dict(:x => 1)) |> @\(:x, y = :x + 1) == (x = 1, y = 2)
end

@testset "Shadowing" begin
    x = :nonlocal
    @test (x = 1, y = 2) |> @\[:x, :y] == [1, 2]
    @test (x = 1, y = 2) |> @\(_..., a = :x + :y, y = 10) === (x = 1, y = 10, a = 3)
    @test (x = 1, y = 2) |> @\(:x, :y) === (x = 1, y = 2)
end

@testset "Free variable" begin
    z = 3
    @test (x = 1, y = 2) |> @\[:x, :y, z] == [1, 2, 3]
    @test (x = 1, y = 2) |> @\(_..., a = :x + :y, y = z) === (x = 1, y = 3, a = 3)
    @test (x = 1, y = 2) |> @\(z, :x) === (z = 3, x = 1)
end

@testset "macrocall" begin
    z = 3
    result = (x = 1, y = 2) |> @\(:x, z = @timed(z))
    @test result.x === 1
    @test result.z[1] === z
    @test result.z[5].total_time isa Number
end

@testset "Explicit nonlocal" begin
    x = :nonlocal
    @test (x = 1, y = 2) |> @\(a = :x, b = x) == (a = 1, b = :nonlocal)
    @test (x = 1, y = 2) |> @\(x, :y) == (x = :nonlocal, y = 2)
    @test (x = 1, y = 2) |> @\(x = string(x, :y)) == (x = "nonlocal2",)
    @test (x = 1, y = 2) |> @\(string(x, :y)) == "nonlocal2"
    @test (x = 1, y = 2) |> @\(; x) == (x = :nonlocal,)
    @test (x = 1, y = 2) |> @\[x, :y] == [:nonlocal, 2]
end

@testset "Interpolation" begin
    x = :nonlocal
    @test (x = 1, y = 2) |> @\(a = :x, b = x, c = $:x) == (a = 1, b = :nonlocal, c = :x)
    @test (x = 1, y = 2) |> @\(identity(:x)) == 1
    @test (x = 1, y = 2) |> @\(identity(x)) == :nonlocal
    @test (x = 1, y = 2) |> @\(identity($:x)) == :x
    @test (x = 1, y = 2) |> @\($:x) == :x
    @test (x = 1, y = 2) |>
          @\(merge((; a = $:x), (; :x, y = x))) == (a = :x, x = 1, y = :nonlocal)
end

macro test_error(ex)
    quote
        let err = nothing
            @test try
                $(esc(ex))
                false
            catch err
                true
            end
            err
        end
    end
end

@testset "Error handling" begin
    ⊏ = occursin

    @testset "@\\ :arg" begin
        err = @test_error @eval @\ :arg
        @test raw"""
        Ambiguous expression: `@\(:arg)`
        Use `@\(_.:arg)` if you mean `x -> x.:arg`.
        Use `@\(; :arg)` if you mean `x -> (:arg = x.:arg,)`.
        """ ⊏ sprint(showerror, err)
    end

    @testset "@\\ arg" begin
        err = @test_error @eval @\ arg
        @test raw"""
        Ambiguous expression: `@\(arg)`
        Use `@\(_.arg)` if you mean `x -> x.arg`.
        Use `@\(; arg)` if you mean `x -> (arg = x.arg,)`.
        """ ⊏ sprint(showerror, err)
    end

    @testset "@\\(; \$(f(x)))" begin
        ex = :(@\(; $(Expr(:$, :(f(x))))))
        err = @test_error @eval $ex
        @test "syntax: invalid named tuple element \"f(x)\"" ⊏ sprint(showerror, err)
    end

    @testset "@\\(; \$(x, y))" begin
        ex = :(@\(; $(Expr(:$, :((x, y))))))
        err = @test_error @eval $ex
        @test "Only single-argument \$ is supported. Got: " ⊏ sprint(showerror, err)
    end

    @testset "@\\_" begin
        ex = :(@\_)
        err = @test_error @eval $ex
        @test "`@\\_` not supported. Use `identity`." ⊏ sprint(showerror, err)
    end

    @testset "Unsupported expression" begin
        ex = :(@\ import Base import Base)
        err = @test_error @eval $ex
        @test "Unsupported expression:" ⊏ sprint(showerror, err)
    end
end

@testset "doctest" begin
    doctest(AtBackslash; manual=false)
end

end  # module
