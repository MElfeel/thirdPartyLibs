#!/bin/bash

## Builds the TPLs on all LC systems. Must be run from the top level TPL directory.
## Usage ./setupLC-TPL.bash pathToGeosxDirectory pathToInstallDirectory [extra arguments to config-build ]
GEOSX_DIR=$1
INSTALL_DIR=$2

## Eat up the command line arguments so the rest can be forwarded to setupLC-TPL-helper.
shift
shift

## Trap the interupt signal and kill all children.
trap 'killall' INT

killall() {
    trap '' INT TERM     # ignore INT and TERM while shutting down
    echo "**** Shutting down. Killing chid processes ****"     # added double quotes
    kill -TERM 0         # fixed order, send TERM not INT
    wait
    echo DONE
}

mkdir toBeDeleted
mv build-* toBeDeleted
rm -rf toBeDeleted &

echo "Building all LC TPLs from $GEOSX_DIR to be installed at $INSTALL_DIR"
./scripts/setupLC-TPL-helper.bash $GEOSX_DIR $INSTALL_DIR quartz gcc@8.1.0   "srun -N 1 -t 60 -n 1" $@ &
./scripts/setupLC-TPL-helper.bash $GEOSX_DIR $INSTALL_DIR quartz clang@9.0.0 "srun -N 1 -t 60 -n 1" $@ &
./scripts/setupLC-TPL-helper.bash $GEOSX_DIR $INSTALL_DIR quartz icc@19.0.4  "srun -N 1 -t 60 -n 1" $@ &

./scripts/setupLC-TPL-helper.bash $GEOSX_DIR $INSTALL_DIR lassen clang@upstream       "lalloc 1 -qpdebug" $@ &
./scripts/setupLC-TPL-helper.bash $GEOSX_DIR $INSTALL_DIR lassen clang@upstream-NoMPI "lalloc 1 -qpdebug" $@ &

wait
echo "Complete"