#!/bin/bash

bmad_python_install() {
    codes_download bmad-sim/pytao 53246bc2893ae2333edb504c5bf7824641be3cf9
    install_pip_install .
}

bmad_main() {
    # bc needed by build
    codes_yum_dependencies cairo-devel pango-devel plplot-fortran-devel bc
    codes_dependencies common xraylib
    _bmad_deps
    # bc is only used to compute compile time
    echo 'IGNORE: bc: command not found'
    _bmad_compile
    _bmad_install
}

_bmad_compile() {
    declare v=20250421-0
    codes_download https://github.com/bmad-sim/bmad-ecosystem/releases/download/"$v"/bmad_dist.tar.gz bmad_dist_"$v" bmad "$v"
    declare p=${codes_dir[prefix]}
    cat > util/user_prefs <<EOF
    export ACC_SET_GMAKE_JOBS=$(codes_num_cores)
    export BMAD_USER_INC_DIRS='$p/include/fgsl;$p/include/xraylib;$p/lib/fortran/modules/lapack95;/usr/lib64/gfortran/modules'
    export BMAD_USER_LIB_DIRS='$p/lib'
EOF
    rm -rf PGPLOT fftw fgsl gnu_utilities_src gsl hdf5 lapack* openmpi plplot xraylib
    (
        set +eou pipefail
        source util/dist_source_me
        util/dist_build_production
    )
}

_bmad_install() {
    declare -a b=(
        tao
        bmad_to_astra
        dynamic_aperture
        # Not installed
        # bbu
        # beam_file_translate_format
        # beam_track_example
        # bmad_to_blender
        # bmad_to_csrtrack
        # bmad_to_gpt
        # bmad_to_mad_sad_elegant
        # bmad_to_merlin
        # bmad_to_opal_example
        # bmad_to_slicktrack
        # cartesian_map_fit
        # compare_tracking_methods_plot
        # compare_tracking_methods_text
        # construct_taylor_map
        # controller_response_plot
        # csr_example
        # dark_current_tracker
        # dispersion_simulation
        # e_cooling
        # element_attributes
        # em_field_query_example
        # envelope_ibs
        # errors_mad_to_bmad
        # f77_to_f90
        # frequency_map
        # generalized_gradient_fit
        # ibs_linac
        # ibs_ring
        # lapack_examples
        # lattice_cleaner
        # lattice_geometry_example
        # long_term_tracking
        # lux
        # mais_ripken
        # make_a_matching_knob
        # multi_turn_tracking_example
        # particle_track_example
        # photon_init_plot
        # photon_surface_data
        # plot_example
        # ptc_flat_file_to_bmad
        # ptc_layout_example
        # ptc_profiler
        # ptc_spin_orbital_normal_form
        # sad_to_bmad_postprocess
        # simple_bmad_program
        # sodom2
        # spin_amplitude_dependent_tune
        # spin_matching
        # spin_stroboscope
        # srdt_lsq_soln
        # synrad
        # synrad3d
        # synrad_aperture_to_wall
        # tune_plane_res_plot
        # tune_scan
        # wake_fit
        # wall_generator
    )
    cd production/bin
    install -m 555 "${b[@]}" "${codes_dir[prefix]}"/bin
    cd ../lib
    install -m 644 *.so "${codes_dir[prefix]}"/lib
    cd ../..
}

_bmad_deps() {
    declare p=$PWD
    codes_download jsberg-bnl/bmad-dependencies-lean
    codes_cmake \
        -DBUILD_FGSL=ON \
        -DBUILD_HDF5=OFF \
        -DBUILD_LAPACK95=ON \
        -DBUILD_PLPLOT=OFF \
        -DBUILD_XRAYLIB=OFF \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make lapack95
    # Runs configure inside so no -j, and is simple file so fast
    make fgsl
    codes_make_install
    cd "$p"
}
