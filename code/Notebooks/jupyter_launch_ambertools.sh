#!/bin/bash
ml --force purge
ml StdEnv/2020 gcc openmpi python ambertools/20
source $EBROOTAMBERTOOLS/amber.sh
source ~/env-pytraj/bin/activate
unset XDG_RUNTIME_DIR
jupyter notebook --ip $(hostname -f) --no-browser
