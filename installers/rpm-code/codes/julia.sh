#!/bin/bash

julia_main() {
    codes_dependencies common
    declare major_minor=1.12
    declare version_dir=julia-$major_minor.3
    declare d=${codes_dir[prefix]}/$version_dir
    install -d -m 755 "$d"
    codes_curl https://julialang-s3.julialang.org/bin/linux/x64/$major_minor/"$version_dir"-linux-x86_64.tar.gz \
        | tar xz --strip-components=1 -C "$d"
    codes_execstack_clear "$d"
    chmod -R a+rX "$d"
    ln -s "$d"/bin/julia "${codes_dir[bin]}"/julia
}
