#!/bin/bash

pymesh_python_install() {
    cd PyMesh
    perl -pi -e 's{.*third_party.*(cgal|eigen|tetgen|clipper|qhull|cork|carve|draco|mmg|tbb|json).*}{}' setup.py
    NUM_CORES=$(codes_num_cores) codes_python_install
}

pymesh_main() {
    local x=(
        eigen3-devel
        gmp-devel
        gmp-devel
        json-devel
        mpfr-devel
        sparsehash-devel
        tbb-devel
        tetgen-devel
    )
    # ImportError: /lib64/libmmg.so.5: undefined symbol: MMG5_lenedg
    # mmg-devel
    #mmg2d-devel
    #mmg3d-devel
    #mmgs-devel
    # CGAL-devel brings in boost 1.69 so don't bring in

    codes_yum_dependencies "${x[@]}"
    codes_dependencies common boost
    codes_download_nonrecursive=1 codes_download https://github.com/PyMesh/PyMesh.git
    for f in libigl pybind11 triangle; do
        git submodule update --init --depth=5 third_party/"$f"
    done
    # optional
    #    git submodule update --init --depth=50 third_party/geogram
    # fmt is strange, can't specify depth
    #    git submodule update --init --recursive third_party/fmt
    # cgal is very large so use --depth=5 fmt needs --depth=10
    #    git submodule update --init --depth=5 $(find third_party/* -maxdepth 0 -type d | egrep -iv '(geogram|fmt|mmg|cgal)')
}
