#!/usr/bin/env bash

version=vcm_1.0
env_file=env.daint.sh
dst_dir=${1:-/project/s1053/install/venv/${version}}
src_dir=$(pwd)

# versions
cuda_version=cuda
# gt4py checks out the latest stable tag below

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

# installation of standard packages that are backend specific
python3 -m pip install cupy Cython
python3 -m pip install clang-format


# installation of gt4py
rm -rf gt4py
git clone git://github.com/VulcanClimateModeling/gt4py.git gt4py
cd gt4py
if [ -z "${GT4PY_VERSION}" ]; then
    wget 'https://raw.githubusercontent.com/VulcanClimateModeling/fv3core/master/GT4PY_VERSION.txt'
    GT4PY_VERSION=`cat GT4PY_VERSION.txt`
fi
git checkout ${GT4PY_VERSION}
cd ../
python3 -m pip install "gt4py/[${cuda_version}]"

# load gridtools modules
module load gridtools/1_1_3
module load gridtools/2_1_0_b

# deactivate virtual environment
deactivate

# echo module environment
echo "Note: this virtual env has been created on `hostname`."
cat ${src_dir}/env/${env_file} ${dst_dir}/bin/activate > ${dst_dir}/bin/activate~
mv ${dst_dir}/bin/activate~ ${dst_dir}/bin/activate


exit 0
