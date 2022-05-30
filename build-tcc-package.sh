#!/usr/bin/env bash

# Attempt to build a "host" and "target" package that duplicates
# the contents of the 2022.1.0 tcc download pakage.


# ############################################################################

# First draft: copy this script into docker container and run.
# Second draft: two scripts, one to start container and one to perform build duties.
# Third draft: setup folder to be mounted by container.
# See Dockerfile in tcc repo(s) for a definition of build environment.
# Add acipca-tools package to the Dockerfile, needed for target builds.


# ############################################################################

dirBuildSource=/home/ubuntu/src/tcc
# Preconfigured folders to attach to the Docker build container:
printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
"${dirBuildSource}/2022.1/" \
"${dirBuildSource}/build-host/" \
"${dirBuildSource}/build-target/" \
"${dirBuildSource}/libraries.compute.tcc-tools/" \
"${dirBuildSource}/libraries.compute.tcc-tools.docs/" \
"${dirBuildSource}/libraries.compute.tcc-tools.infrastructure/"

# Preconfigured folders (above) should be checked out on branch/tag to be built.
# Ultimately, might be better to copy in and copy out of the container.
# For now, don't forget to:
# $ chmod -R 777 ${dirBuildSource}/build* ${dirBuildSource}/libraries*
# $ chmod -R 755 ${dirBuildSource}/2022.1


# Start Docker container and attach build source and build target folders as a volume.
dirBuildRoot=/home/tcc/build
dockerImage=amr-registry.caas.intel.com/idev/tcc/nn/base_public
echo "Using ${dockerImage} as source of Docker build container."
dockerCommand="docker run -it -v ${dirBuildSource}:${dirBuildRoot}:z ${dockerImage}"
echo "${dockerCommand}"
# eval "${dockerCommand}"



# ############################################################################

# Perform a "host build" (cmake + make).
# Note that ${dirBuildRoot}/build is used twice: for host build and again for target build.
# Doing this to minimize path differences between the host and target build results.
set -ex
rm -rf ${dirBuildRoot}/build*
mkdir ${dirBuildRoot}/build
cd ${dirBuildRoot}/build
cmake -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${dirBuildRoot}/build/host -DHOST_STRUCTURE=ON -DPACKAGE_TYPE=PUBLIC ${dirBuildRoot}/libraries.compute.tcc-tools
# make VERBOSE=1 -j$(nproc) 2>&1 | tee <build-root>/build/build_log.txt
make VERBOSE=1  # 2>&1 | tee ${dirBuildRoot}/build/build_log.txt
make doc        # -j$(nproc)
make install    # -j$(nproc)

# End of host build ???
# Rename the "build" folder to "build-host"
cd ..
mv ${dirBuildRoot}/build ${dirBuildRoot}/build-host


# ############################################################################

# Part one of "target build" (cmake + make).
set -ex
# rm -rf ${dirBuildRoot}/build*
mkdir ${dirBuildRoot}/build
cd ${dirBuildRoot}/build
cmake -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${dirBuildRoot}/build/usr -DHOST_STRUCTURE=OFF -DPACKAGE_TYPE=PUBLIC ${dirBuildRoot}/libraries.compute.tcc-tools
# make VERBOSE=1 -j$(nproc) 2>&1 | tee <build-root>/build/build_log.txt
make VERBOSE=1  # 2>&1 | tee ${dirBuildRoot}/build/build_log.txt
make doc        # -j$(nproc)
make install    # -j$(nproc)

# Part two: turn the usr folder into a tar.gz file.
rm -rf ${dirBuildRoot}/build/tcc_tools*.tar.gz
tar --owner=root --group=root --exclude='usr/tests' -cvzf ${dirBuildRoot}/build/tcc_tools_target_2022.1.0.tar.gz usr

# Part three: add efi module (by way of edk2 project).
set -ex
mkdir -p /opt
cd /opt
rm -rf edk2
git clone https://github.com/tianocore/edk2.git
cd edk2
git checkout tags/edk2-stable202105 -B edk2-stable202105
git submodule update --init
make -C BaseTools

rm -rf ${dirBuildRoot}/build/edk2
cp -r /opt/edk2 ${dirBuildRoot}/build/
cd ${dirBuildRoot}/build
make -C edk2/BaseTools
cd edk2
# shellcheck source=/dev/null
source edksetup.sh
patch -p1 < ${dirBuildRoot}/libraries.compute.tcc-tools.infrastructure/ci/edk2/tcc_target.patch
sed -i "s+path_to_detector.inf+${dirBuildRoot}/libraries.compute.tcc-tools/tools/rt_checker/efi/Detector.inf+g" ShellPkg/ShellPkg.dsc
build

cd ${dirBuildRoot}/build
rm -rf usr
tar -xzf tcc_tools_target_2022.1.0.tar.gz
cp edk2/Build/Shell/RELEASE_GCC5/X64/tcc_rt_checker.efi usr/share/tcc_tools/tools/
tar -czvf tcc_tools_target_2022.1.0.tar.gz usr

# End of target build.
# Rename the "build" folder to "build-target"
cd ${dirBuildRoot}
mv ${dirBuildRoot}/build ${dirBuildRoot}/build-target
