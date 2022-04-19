#!/bin/bash
ml --force purge
ml StdEnv/2020 gcc openmpi python ambertools/20
virtualenv ~/env-pytraj
source ~/env-pytraj/bin/activate
pip install --no-index jupyter ipykernel
python -m ipykernel install --user --name=env-pytraj
pip install nglview pickle5 seaborn 
jupyter nbextension install widgetsnbextension --py --sys-prefix 
jupyter-nbextension enable widgetsnbextension --py --sys-prefix
jupyter-nbextension enable nglview --py --sys-prefix

