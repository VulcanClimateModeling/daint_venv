#!/bin/bash

version=vcm_1.0
env_file=env.daint.sh
dst_dir=${1:-/project/s1053/install/venv/${version}}
src_dir=$(pwd)

# versions
fv3config_sha1=1eb1f2898e9965ed7b32970bed83e64e074a7630
gt4py_url="git+git://github.com/VulcanClimateModeling/gt4py.git"
cuda_version=cuda102

# module environment
source ${src_dir}/env.sh
source ${src_dir}/env/machineEnvironment.sh
source ${src_dir}/env/${env_file}

# echo commands and stop on error
set -e
set -x

# delete any pre-existing venv directories
if [ -d ${dst_dir} ] ; then
    /bin/rm -rf ${dst_dir}
fi

# setup virtual env
python3 -m venv ${dst_dir}
source ${dst_dir}/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade wheel

# installation of standard packages
python3 -m pip install kiwisolver numpy matplotlib cupy-${cuda_version} Cython h5py six zipp
python3 -m pip install pytest pytest-profiling pytest-subtests hypothesis gitpython clang-format

# installation of fv3 dependencies
python3 -m pip install cftime f90nml pandas pyparsing python-dateutil pytz pyyaml xarray zarr

# build and install mpi4py from sources
rm -rf ${src_dir}/mpi4py
export MPICC=cc
git clone https://github.com/mpi4py/mpi4py.git
cp ${src_dir}/mpi.cfg ${src_dir}/mpi4py
cd mpi4py/
python3 setup.py build --mpi=mpi
python3 setup.py install
cd ../
unset MPICC

# installation of our packages
python3 -m pip install git+git://github.com/VulcanClimateModeling/fv3config.git@${fv3config_sha1}
python3 -m pip install ${gt4py_url}#egg=gt4py[${cuda_version}]
python3 -m gt4py.gt_src_manager install

# deactivate virtual environment
deactivate

# echo module environment
echo "Note: this virtual env has been created on `hostname`."
cat ${src_dir}/env/${env_file} ${dst_dir}/bin/activate > ${dst_dir}/bin/activate~
mv ${dst_dir}/bin/activate~ ${dst_dir}/bin/activate

exit 0

