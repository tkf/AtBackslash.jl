using Documenter, AtBackslash

makedocs(;
    modules=[AtBackslash],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/AtBackslash.jl/blob/{commit}{path}#L{line}",
    sitename="AtBackslash.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/AtBackslash.jl",
)
