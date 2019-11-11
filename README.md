# AtBackslash

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/AtBackslash.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/AtBackslash.jl/dev)
[![Build Status](https://travis-ci.com/tkf/AtBackslash.jl.svg?branch=master)](https://travis-ci.com/tkf/AtBackslash.jl)
[![Codecov](https://codecov.io/gh/tkf/AtBackslash.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/AtBackslash.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/AtBackslash.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/AtBackslash.jl?branch=master)


`AtBackslash` exports a macro `@\` to easily create functions that
work with named tuples as input and/or output.

The symbol literal like `:x` in the tuple argument is expanded to be
the property/field of the named tuple of the input and output:

```julia
julia> using AtBackslash

julia> (x = 1, y = 2, z = 3) |> @\(:x, :y)
(x = 1, y = 2)
```

It also supports normal "verbose" syntax for creating a named tuple:

```julia
julia> (x = 1, y = 2) |> @\(x = :x, y = :y)
(x = 1, y = 2)
```

which is handy when adding new properties:

```julia
julia> (x = 1, y = 2) |> @\(:x, z = :x + :y)
(x = 1, z = 3)
```

The argument can be explicitly referred to by `_`:

```julia
julia> (x = 1, y = 2) |> @\(_..., z = :x + :y)
(x = 1, y = 2, z = 3)
```

```julia
julia> (x = 1, y = 2) |> @\_.x
1
```

```julia
julia> 1 |> @\(x = _, y = 2_)
(x = 1, y = 2)
```

Automatic conversions of `:x` and `(; :x, :y)` work at any level of
expression:

```julia
julia> (x = 1, y = 2) |> @\ merge((; :x, :y), (a = :x, b = :y))
(x = 1, y = 2, a = 1, b = 2)
```

```julia
julia> (x = 1, y = 2) |> @\(:x < :y < 3)
true
```

Use `$:x` to avoid automatic conversion to `_.x`:

```julia
julia> (x = 1, y = 2) |> @\(x = $:x, :y)
(x = :x, y = 2)
```

Use plain names to refer to the ones in the outer scope:

```julia
julia> let z = 3
           (x = 1, y = 2) |> @\(:x, :y, z)
       end
(x = 1, y = 2, z = 3)
```

The input can be any object that support `getproperty`.  For example,
it works with `Complex`:

```julia
julia> 1 + 2im |> @\(:re, :im)
(re = 1, im = 2)
```
