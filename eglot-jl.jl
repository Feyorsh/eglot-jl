# Usage:
#   julia --project=path/to/eglot-jl path/to/eglot-jl/eglot-jl.jl [SOURCE_PATH] [DEPOT_PATH]

# For convenience, Pkg isn't included in eglot-jl
# Project.toml. Importing Pkg here relies on the standard library
# being available on LOAD_PATH
import Pkg

# Resolving the environment is necessary for cases where the shipped
# Manifest.toml is not compatible with the Julia version.
for _ in 1:2
    try
        Pkg.resolve(io=stderr)
        @info "Environment successfully resolved"
        break
    catch err
        # Downgrading from 1.6 to 1.5 sometimes causes temporary errors
        @warn "Error while resolving the environment; retrying..." err
    end
end

# In julia 1.4 this operation takes under a second. This can be
# crushingly slow in older versions of julia though.
Pkg.instantiate()

# Get the source path. In order of increasing priority:
# - default value:  pwd()
# - command-line:   ARGS[1]
src_path = length(ARGS) >= 1 ? ARGS[1] : pwd()

# Get the depot path. In order of increasing priority:
# - default value:  ""
# - environment:    ENV["JULIA_DEPOT_PATH"]
# - command-line:   ARGS[2]
depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
if length(ARGS) >= 2 && ARGS[2] != ""
    depot_path = ARGS[2]
end

# Get the store path for SymbolServer. In order of increasing priority:
# - default value:  inside the SymbolServer package directory
# - environment:    ENV["JULIA_SYMSERVER_STORE_PATH"]
symserver_store_path = get(ENV, "JULIA_SYMSERVER_STORE_PATH", nothing)

# Get the project environment from the source path
project_path = something(Base.current_project(src_path), Base.load_path_expand(LOAD_PATH[2])) |> dirname

# Make sure that we only load packages from this environment specifically.
empty!(LOAD_PATH)
push!(LOAD_PATH, "@")

using LanguageServer, SymbolServer

@info "Running language server" env=Base.load_path()[1] src_path project_path depot_path
server = LanguageServerInstance(stdin, stdout, project_path, depot_path, nothing, symserver_store_path)
run(server)
