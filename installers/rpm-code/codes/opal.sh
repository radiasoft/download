#!/bin/bash
opal_main() {
    # NOTE: trilinos is not added as an rpm dependency see ../radiasoft-download.sh
    codes_dependencies trilinos h5hut boost
    opal_mithra
    codes_download https://gitlab.psi.ch/OPAL/src/-/archive/OPAL-2021.1.0/src-OPAL-2021.1.0.tar.bz2
    perl -pi -e '
        # https://stackoverflow.com/a/20991533
        # boost is compiled multithreaded, because it does not mean "pthreads",
        # but just that the code takes a bit more care on values in static sections.
        # If we do not turn this ON, it will not find the variant compiled.
        s{(?<=Boost_USE_MULTITHREADED )OFF}{ON};
        # otherwise fails with -lmpi_mpifh not found, because
        # that is part of openmpi, not mpich
        s{.*mpi_mpifh.*}{};
        s{-fPIE}{};
        s{add_link_options.*-pie.*}{};
    ' CMakeLists.txt
    # need to specify CC and CXX otherwise build uses wrong
    # compiler.
    H5HUT_PREFIX="${codes_dir[prefix]}" \
        BOOST_DIR="${codes_dir[prefix]}" \
        HDF5_INCLUDE_DIR=/usr/include \
        HDF5_LIBRARY_DIR="$BIVIO_MPI_LIB" \
	MITHRA_INCLUDE_DIR="${codes_dir[include]}" \
	MITHRA_LIBRARY_DIR="${codes_dir[lib]}" \
        CC=mpicc CXX=mpicxx \
        codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
	-D ENABLE_OPAL_FEL=yes \
        -D ENABLE_SAAMG_SOLVER=TRUE \
        -D CMAKE_POSITION_INDEPENDENT_CODE=FALSE \
        -D USE_STATIC_LIBRARIES=FALSE
    codes_make all
    # We need to strip because the binary is very large
    # https://github.com/radiasoft/download/issues/140
    install -m 755 --strip src/opal "${codes_dir[bin]}"/opal
}

opal_mithra() {
    codes_download https://github.com/aryafallahi/mithra/archive/2.0.tar.gz mithra-2.0 mithra 2.0
    opal_mithra_patch
    # makefile handwritten without appropriate dependencies
    CFLAGS='-fPIC' make install
    mkdir "${codes_dir[include]}/mithra"
    install -m 644 ./include/mithra/* "${codes_dir[include]}/mithra"
    install -m 644 './lib/libmithra.a' "${codes_dir[lib]}"
    cd ..
}

opal_mithra_patch() {
    patch src/solver.cpp <<'EOF'
*** solver.cpp~	2020-09-29 12:50:06.000000000 +0000
--- solver.cpp	2022-01-19 21:46:24.260093371 +0000
***************
*** 403,412 ****
  	    zMin = std::min(zMin, iter->rnp[2]);
  	    bz += iter->gbnp[2] / std::sqrt(1 + iter->gbnp.norm2());
  	  }
! 	MPI_Allreduce(&zMin, &zMin, 1, MPI_DOUBLE, MPI_MIN, MPI_COMM_WORLD);
! 	MPI_Allreduce(&bz, &bz, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
  	unsigned int Nq = chargeVectorn_.size();
! 	MPI_Allreduce(&Nq, &Nq, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
  	bz /= Nq;

  	mesh_.totalTime_ = 1 / (c0_ * (bz + beta_)) * (zEnd - beta_ * c0_ * dt_ - zMin + bz / beta_* Lu);
--- 403,416 ----
  	    zMin = std::min(zMin, iter->rnp[2]);
  	    bz += iter->gbnp[2] / std::sqrt(1 + iter->gbnp.norm2());
  	  }
!         double r;
! 	MPI_Allreduce(&zMin, &r, 1, MPI_DOUBLE, MPI_MIN, MPI_COMM_WORLD);
!         zMin = r;
! 	MPI_Allreduce(&bz, &r, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
!         bz = r;
  	unsigned int Nq = chargeVectorn_.size();
! 	MPI_Allreduce(&Nq, &r, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
!         Nq = r;
  	bz /= Nq;

  	mesh_.totalTime_ = 1 / (c0_ * (bz + beta_)) * (zEnd - beta_ * c0_ * dt_ - zMin + bz / beta_* Lu);
***************
*** 456,462 ****
  	if ( ip == rank_ ) recvCV = sendCV;

  	/* Now broadcast the data from i'th processor to all other processors.				*/
! 	MPI_Bcast(&recvCV[0], sizeSend, MPI_DOUBLE, ip, MPI_COMM_WORLD);

  	/* And now place all the charges in the charge vector of the corresponding processor.  		*/
  	unsigned int i = 0;
--- 460,466 ----
  	if ( ip == rank_ ) recvCV = sendCV;

  	/* Now broadcast the data from i'th processor to all other processors.				*/
! 	MPI_Bcast(recvCV.data(), sizeSend, MPI_DOUBLE, ip, MPI_COMM_WORLD);

  	/* And now place all the charges in the charge vector of the corresponding processor.  		*/
  	unsigned int i = 0;
***************
*** 1583,1601 ****
        }

      /* Now communicate the charges which propagate throughout the borders to other processors.		*/
!     MPI_Send(&ubp.qSB[0],ubp.qSB.size(),MPI_DOUBLE,rankB_,msgtag1,MPI_COMM_WORLD);

      MPI_Probe(rankF_,msgtag1,MPI_COMM_WORLD,&status);
      MPI_Get_count(&status,MPI_DOUBLE,&ub_.nL);
      ubp.qRF.resize(ub_.nL);
!     MPI_Recv(&ubp.qRF[0],ub_.nL,MPI_DOUBLE,rankF_,msgtag1,MPI_COMM_WORLD,&status);

!     MPI_Send(&ubp.qSF[0],ubp.qSF.size(),MPI_DOUBLE,rankF_,msgtag2,MPI_COMM_WORLD);

      MPI_Probe(rankB_,msgtag2,MPI_COMM_WORLD,&status);
      MPI_Get_count(&status,MPI_DOUBLE,&ub_.nL);
      ubp.qRB.resize(ub_.nL);
!     MPI_Recv(&ubp.qRB[0],ub_.nL,MPI_DOUBLE,rankB_,msgtag2,MPI_COMM_WORLD,&status);

      /* Now insert the newly incoming particles in this processor to the list of particles.            */
      unsigned i = 0;
--- 1587,1605 ----
        }

      /* Now communicate the charges which propagate throughout the borders to other processors.		*/
!     MPI_Send(ubp.qSB.data(),ubp.qSB.size(),MPI_DOUBLE,rankB_,msgtag1,MPI_COMM_WORLD);

      MPI_Probe(rankF_,msgtag1,MPI_COMM_WORLD,&status);
      MPI_Get_count(&status,MPI_DOUBLE,&ub_.nL);
      ubp.qRF.resize(ub_.nL);
!     MPI_Recv(ubp.qRF.data(),ub_.nL,MPI_DOUBLE,rankF_,msgtag1,MPI_COMM_WORLD,&status);

!     MPI_Send(ubp.qSF.data(),ubp.qSF.size(),MPI_DOUBLE,rankF_,msgtag2,MPI_COMM_WORLD);

      MPI_Probe(rankB_,msgtag2,MPI_COMM_WORLD,&status);
      MPI_Get_count(&status,MPI_DOUBLE,&ub_.nL);
      ubp.qRB.resize(ub_.nL);
!     MPI_Recv(ubp.qRB.data(),ub_.nL,MPI_DOUBLE,rankB_,msgtag2,MPI_COMM_WORLD,&status);

      /* Now insert the newly incoming particles in this processor to the list of particles.            */
      unsigned i = 0;
EOF
}
