---
title: "Plotting Energy Components in Jupyter Notebook"
teaching: 25
exercises: 0
questions:
- "How to extract energy components from simulation logs?"
- "How to load and plot energy components?"
objectives:
- "Learn to extract energy components from simulation logs"
- "Learn to plot energy components"
keypoints:
- " "
---

### Extracting Energy Components from Simulation Logs.
We are now ready to use pytraj in the Jupyter notebook. Let’s plot energies from the simulation logs of our equilibration runs.

First, we load *`pandas`* and *`matplotlib`* modules. Then move into the directory where the input data files are located: 
~~~
import pandas as pd
import matplotlib.pyplot as plt

%cd ~/workshop_pytraj/example_01
~~~
{: .language-python}

Extract some energy components (total energy, temperature, pressure, and volume) from the equilibration log and save them in the file *`energy.dat`*:
~~~
!./extract_energies.sh equilibration_1.log
~~~
{: .language-python}

File *extract_energies.sh* is shell script calling *cpptraj* program to do the job:
~~~
#!/bin/bash
echo "Usage: extract_energies simulation_log_file" 
log=$1

cpptraj << EOF
readdata $log
writedata energy.dat $log[Etot] $log[TEMP] $log[PRESS] $log[VOLUME] time 0.1
EOF
~~~
{:.file-content}

### Plotting energy components
Read the data saved in the file *`energy.dat`* into a pandas dataframe and plot it:
~~~
df=pd.read_table('energy.dat', delim_whitespace=True)
df.columns=["Time", "Etot", "Temp", "Press", "Volume"]
df.plot(subplots=True, x="Time", xlabel="Time, ps", figsize=(6, 8))
plt.show()
~~~
{: .language-python}


