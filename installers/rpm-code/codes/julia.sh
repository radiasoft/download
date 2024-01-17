#!/bin/bash

julia_main() {
    codes_dependencies common
    declare v=julia-1.9.3
    declare d=${codes_dir[prefix]}/$v
    install -d -m 755 "$d"
    codes_curl https://julialang-s3.julialang.org/bin/linux/x64/1.9/"$v"-linux-x86_64.tar.gz \
        | tar xz --strip-components=1 -C "$d"
    ln -s "$d"/bin/julia "${codes_dir[bin]}"/julia
}
