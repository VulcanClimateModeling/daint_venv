#!/bin/bash

version=vcm_1.0
env_file=env.daint.sh
venv_dir=/project/s1053/install/venv
dst_dir=${venv_dir}/${version}
install_dir=${dst_dir}_tmp

# versions
fv3config_sha1=1eb1f2898e9965ed7b32970bed83e64e074a7630
gt4py_url="git+git://github.com/VulcanClimateModeling/gt4py.git"
cuda_version=cuda102

# module environment
source ./env.sh
source ./env/machineEnvironment.sh
source ./env/${env_file}

# echo commands and stop on error
set -e
set -x

# delete any left-over temporary directories
if [ -d ${install_dir} ] ; then
    /bin/rm -rf ${install_dir}
fi

# setup virtual env
python3 -m venv ${install_dir}
source ${install_dir}/bin/activate
pip install --upgrade pip
pip install --upgrade wheel

# installation of standard packages
pip install numpy
pip install matplotlib
pip install cupy-${cuda_version}
pip install pytest pytest-profiling pytest-subtests hypothesis

# installation of fv3 dependencies
pip install cftime f90nml pyyaml xarray zarr

# build and install mpi4py from sources
rm -rf ./mpi4py
export MPICC=cc
git clone https://github.com/mpi4py/mpi4py.git
cp ./mpi.cfg ./mpi4py
cd mpi4py
python setup.py build --mpi=mpi
python setup.py install
cd ../

# installation of our packages
pip install git+git://github.com/VulcanClimateModeling/fv3config.git@${fv3config_sha1}
pip install ${gt4py_url}#egg=gt4py[${cuda_version}]
python -m gt4py.gt_src_manager install

# deactivate virtual environment
deactivate

# echo module environment
echo "Note: this virtual env has been created on `hostname`."
cat ./env/${env_file} >> ${install_dir}/bin/activate

# move new venv in place (as quickly as possible)
if [ -d ${dst_dir}_old ] ; then
  /bin/rm -rf ${dst_dir}_old
fi
if [ -d ${dst_dir} ] ; then
  mv ${dst_dir} ${dst_dir}_old
fi
mv ${install_dir} ${dst_dir}
if [ -d ${dst_dir}_old ] ; then
  /bin/rm -rf ${dst_dir}_old
fi

# goodbye, Earthling!
exit 0

