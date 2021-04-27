#!/usr/bin/env bash

version=vcm_1.0
env_file=env.daint.sh
dst_dir=${1:-/project/s1053/install/venv/${version}}
src_dir=$(pwd)

# versions
fv3config_sha1=1eb1f2898e9965ed7b32970bed83e64e074a7630
cuda_version=cuda102
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

# installation of standard packages
python3 -m pip install kiwisolver numpy matplotlib cupy-${cuda_version} Cython h5py six zipp
python3 -m pip install pytest pytest-profiling pytest-subtests hypothesis gitpython 
python3 -m pip install clang-format gprof2dot

# installation of fv3 dependencies
python3 -m pip install cftime f90nml pandas pyparsing python-dateutil pytz pyyaml xarray zarr

# build and install mpi4py from sources
rm -rf ${src_dir}/mpi4py
export MPICC=cc
git clone https://github.com/mpi4py/mpi4py.git
cd mpi4py/
MPI4PY_VERSION=aac3d8f2a56f3d74a75ad32ac0554d63e7ef90ab
git checkout -f ${MPI4PY_VERSION}

# Setup a MPI config file to make sure mpi4py founds both MPICH
# and CUDA for g2g enabled communication
echo "Building MPI4PY with..."
echo "... Cu in $CUDA_HOME"
echo "... MPI in $MPICH_DIR"
cat > ${src_dir}/mpi4py/mpi.cfg <<EOF
# Some Linux distributions have RPM's for some MPI implementations.
# In such a case, headers and libraries usually are in default system
# locations, and you should not need any special configuration.

# If you do not have MPI distribution in a default location, please
# uncomment and fill-in appropriately the following lines. Yo can use
# as examples the [mpich2], [openmpi],  and [deinompi] sections
# below the [mpi] section (wich is the one used by default).

# If you specify multiple locations for includes and libraries,
# please separate them with the path separator for your platform,
# i.e., ':' on Unix-like systems and ';' on Windows

# Daint configuration
# ---------------------
[mpi]
mpi_dir              = ${MPICH_DIR}
cuda_dir             = ${CUDA_HOME}

mpicc                = `which cc`
mpicxx               = `which CC`

## define_macros        =
## undef_macros         =
include_dirs         = %(mpi_dir)s/include %(cuda_dir)s/include
libraries            = mpich mpl rt pthread cuda cudart
library_dirs         = %(mpi_dir)s/lib %(cuda_dir)s/lib64
runtime_library_dirs = %(mpi_dir)s/lib %(cuda_dir)s/lib64
EOF


# Build mpi4py relyng on the above scratch config
python3 setup.py build --mpi=mpi
python3 setup.py install
cd ../
unset MPICC

# installation of fv3config
python3 -m pip install git+git://github.com/VulcanClimateModeling/fv3config.git@${fv3config_sha1}

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
python3 -m gt4py.gt_src_manager install

# deactivate virtual environment
deactivate

# echo module environment
echo "Note: this virtual env has been created on `hostname`."
cat ${src_dir}/env/${env_file} ${dst_dir}/bin/activate > ${dst_dir}/bin/activate~
mv ${dst_dir}/bin/activate~ ${dst_dir}/bin/activate

exit 0
