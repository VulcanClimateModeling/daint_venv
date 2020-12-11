#!/bin/bash

version=vcm_1.0
env_file=env.daint.sh
dst_dir=/project/s1053/install/venv/${version}

# versions
fv3config_sha1=2212b33a2ec8e2e05df10e1c9ca0f1815d4f9a8d
gt4py_url="git+git://github.com/VulcanClimateModeling/gt4py.git"
cuda_version=cuda102

# module environment
source ./env.sh
source ./env/machineEnvironment.sh
source ./env/${env_file}

# echo commands and stop on error
set -e
set -x

# setup virtual env
if [ -d ${dst_dir} ] ; then /bin/rm -rf ${dst_dir} ; fi
python3 -m venv ${dst_dir}
source ${dst_dir}/bin/activate
pip install --upgrade pip
pip install --upgrade wheel

# installation of standard packages
pip install numpy
pip install matplotlib
pip install cupy-${cuda_version}
pip install pytest pytest-profiling pytest-subtests

# installation of fv3 dependencies
pip install cftime f90nml pyyaml xarray zarr

# build and install mpi4py
MPICC=cc python -m pip install --upgrade git+https://github.com/mpi4py/mpi4py.git

# installation of our packages
pip install git+git://github.com/VulcanClimateModeling/fv3config.git@${fv3config_sha1}
pip install ${gt4py_url}#egg=gt4py[${cuda_version}]
python -m gt4py.gt_src_manager install
deactivate

# add note when activated
cat >> ${dst_dir}/bin/activate <<EOF1
