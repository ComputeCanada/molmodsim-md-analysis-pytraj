---
title: "Using PYTRAJ in Jupyter Notebook"
teaching: 25
exercises: 0
questions:
- "What tools are available to analyze my MD-data?"
- "How to setup Jupyter for MD analysis"
objectives:
- "Learn how to set up and use Jupyter notebook in CC environment."
keypoints:
- "By keeping everything in one easy accessible place Jupyter notebooks greatly simplify the management and sharing of your work"
---

## Introduction
PYTRAJ is a Python front end to the AMBER [CPPTRAJ](https://amber-md.github.io/cpptraj/CPPTRAJ.xhtml) package. CPPTRAJ provides a variety of high level analysis commands, and at the same time it is suitable for batch processing. With PYTRAJ/CPPTRAJ you can do many operations on the raw MD trajectories. For example, convert among trajectory formats, process groups of trajectories generated with ensemble methods, image with periodic boundary conditions, create average structures, create subsets of the system. PYTRAJ is able to handle many files at the same time, and it can handle very large trajectories.

PYTRAJ offers more than 50 types of analyses such as RMS fitting, measuring distances, B-factors, radii of gyration, radial distribution functions, time correlations, and many more. PYTRAJ supports MPI, and usage of MPI is straightforward. You don't really need to understand deeply about MPI or write complicated code.

Other useful MD analysis software: [MDAnalysis](https://userguide.mdanalysis.org/stable/index.html), [MDTraj](https://mdtraj.org/),[Pteros](https://yesint.github.io/pteros/), [LOOS/PyLOOS](http://grossfieldlab.github.io/loos/index.htmland). These packages provide libraries that can be used to compose analysis programs. While this approach offers great flexibility, the learning curve is steep, and you will need to spend more time to master them.

References:  
1. [PTRAJ and CPPTRAJ: Software for Processing and Analysis of Molecular Dynamics Trajectory Data](https://pubs.acs.org/doi/full/10.1021/ct400341p)


## Using PYTRAJ in Jupyter notebook
The use of Jupyter notebook becomes increasingly popular for data analysis and visualization. One of the most attractive features of Jupyter is how well it combines different medium (your code, notes, and visualizations) in one solution. By keeping everything in one easy accessible place notebooks greatly simplify the management and sharing of your work.

Before going into details of MD analysis with PYTRAJ we need to create a Python virtual environment. A virtual environment is a framework for management of multiple isolated Python environments. We use it on CC systems for installation of Python packages in user accounts.

### Installing Python Virtual Environment and Jupyter Notebook.
In this lesson we will be using PYTRAJ with AmberTools20. To start using these tools first you need to load modules required for AmberTools. Then load `python` and `scipy-stack modules`:

~~~
module load StdEnv/2020 gcc/9.3.0 openmpi/4.0.3 python scipy-stack
~~~
{: .bash}

The next step is to install and activate a virtual environment. We need a virtual environment because we will be installing Python modules required for this lesson and virtual environment is the best way to install and manage Python modules on CC systems.

~~~
virtualenv ~/env-pytraj
source ~/env-pytraj/bin/activate
~~~
{: .bash}

Once a virtual environment is installed and activated we can install Jupyter Notebook server. We begin installation by installing IPython kernel, the Python backend for Jupyter Notebook. Kernel is a process that runs independently and interacts with the Jupyter Notebook server and its user interface. The Jupyter Notebook automatically ensures that the IPython kernel is available in the default environment. However, as we will be using Python in a specific virtual environment set up for using AmberTools, we need to install IPython kernel into the newly created environment. 

~~~
pip install --no-index jupyter ipykernel
~~~
{: .bash}

To make the environment *env-pytraj* accessible from notebook we need one more step: add the kernel specification for the new Python to Jupyter. You can use any name for the kernel, for example 'env-pytraj'.

~~~
python -m ipykernel install --user --name=env-pytraj
~~~
{: .bash} 

Finally, install three more packages that we will be using: 
1. **NGLview**, a Jupyter widget for molecular visualization.
2. **Pickle**, a module providing functions for serialization of Python objects (conversion into a byte stream). Objects need to be serialized for storage on a hard disk and loading back into Python. 
3. **Seaborn**, a Python data visualization library extending a popular *matplotlib*. It provides a high-level interface for drawing, templates for attractive and informative statistical graphics.

~~~
pip install nglview pickle5 seaborn 
~~~
{: .bash}

As NGL viewer is a Jupyter notebook widget, we need to install and enable Jupyter widgets extension

~~~
jupyter nbextension install widgetsnbextension --py --sys-prefix 
jupyter-nbextension enable widgetsnbextension --py --sys-prefix
~~~
{: .bash}

The *nglview* Python module provides NGLview Jupyter extension. We don't need to install it, but we need to enable it before it can be used:
~~~
jupyter-nbextension enable nglview --py --sys-prefix
~~~
{: .bash}

We are now ready to start Jupyter notebook server. The new Python kernel with the name `env-pytraj` will be available for notebooks.

### Launching Jupyter notebook server
This example is for launching Jupyter on the training cluster. Procedure is the same on all other Compute Canada systems. the only difference is the name of the login and compute nodes. 

To make AmberTools available in a notebook we need to load the `ambertools` module and activate the virtual environment before starting Jupyter server. As launching a server involves a sequence of several commands, it is convenient to save all commands in a file. You can later simply execute commands from this file (we call this "source file") instead of typing commands every time.

Let's create Jupyter startup file for use with AmberTools module, *jupyter_launch_ambertools.sh*, with the following content: 

~~~
#!/bin/bash
ml StdEnv/2020 gcc openmpi python scipy-stack ambertools
source $EBROOTAMBERTOOLS/amber.sh
source ~/env-pytraj/bin/activate
unset XDG_RUNTIME_DIR
jupyter notebook --ip $(hostname -f) --no-browser
~~~
{: .file-content}

Before starting Jupyter server we need to allocate CPUs and RAM for our notebook. Let's request two MPI tasks because we will learn to how to analyze data in parallel. Submit request of an interactive resource allocation using the *salloc* command:

~~~
salloc --mem-per-cpu=2000 --time=2:0:0 --ntasks=2
~~~
{: .bash}

Wait for the allocation to complete. When it's done you will see that the command prompt changed:

~~~
[user45@login1 ~]$ salloc -c4 --mem-per-cpu=1000 --time=10:0:0
salloc: Granted job allocation 168
salloc: Waiting for resource configuration
salloc: Nodes node1 are ready for job
[user45@node1 ~]$  
~~~
{:.output}

In this example salloc allocated the resources and logged you into the compute node node1. Note the name of the node where notebook server will be running. Now we can start Jupyter server by executing commands from the file *jupyter_launch_ambertools.sh*

~~~
bash ./jupyter_launch_ambertools.sh
~~~
{: .bash}

**Do not close this window**, closing it will terminate the server. Note the **port number** (the default is 8888, but if you or another user start a second server, port number will be incremented). Note the **notebook access token**, you will need it to connect to the Jupyter notebook.

### Connecting to Jupyter server

The message in the example above informs that notebook server is listening at port 8888 of the node node1. Compute nodes cannot be accessed directly from the Internet, but we can connect to the login node, and the login node can connect any compute node. Thus, connection to a compute node should be also possible. How do we connect to the node node1 at port 8888? We can instruct ssh client program to map port 8888 of node1 to our local computer. This type of connection is called "ssh tunneling" or "ssh port forwarding". Ssh tunneling allows transporting networking data between computers over an encrypted SSH connection.

![schematic of two SSH-tunnels]({{ page.root }}/fig/ssh_tunnel.svg)

Open **another** terminal tab or window and run the command:
~~~
ssh user45@moledyn.ace-net.training -L 8888:node1:8888
~~~
{: .bash}

Replace the *port number* and the *node name* with the appropriate values.

This SSH session created tunnel from your computer to node1. The tunnel will be active only while the session is running. Do not close this window and do not logout, this will close the tunnel and disconnect you from the notebook.

Now in the browser on your local computer you can type localhost:8888, and enter the token when prompted.

In Jupyter open new notebook. Ensure that you are creating notebook with the python kernel matching the active environment (env-pytraj), or kernel will fail to start!

> ## Using MobaXterm (on Windows)
>
> Users of MobaXterm can use the "SSH Session" as usual to open the *first* terminal tab which they 
> can use to start the interactive job (*salloc*) and the Jupyter server.
>
> To establish the SSH-tunnels with a *second* SSH-session, we want to first open a *Local terminal*:
> ![MobaXterm: Button "Start local terminal"]({{ page.root }}/fig/mobaxterm_local_terminal.png)
>
> In the *local terminal* we then use the same `ssh` command as shown above to create the SSH-tunnel
> ![SSH command in local terminal]({{ page.root }}/fig/mobaxterm_ssh_command.png)
{: .callout}

> ## Uninstalling virtual environment from Jupyter:
>
> ~~~
> jupyter kernelspec list
> jupyter kernelspec uninstall env-pytraj
> ~~~
> {: .bash}
{: .callout}

### Plotting energy components from simulation logs

We are now ready to use pytraj in Jupyter notebook.  Let's plot energies from the simulation logs of our equilibration runs. 

First load pandas, and matplotlib modules. Then move into the directory where the input data files are located.

~~~
import pandas as pd
import matplotlib.pyplot as plt

%cd ~/scratch/workshop/pdb/1RGG/AMBER/3_equilibration/
~~~
{:.python}

~~~
! extract_energies.sh equilibration_1.log
~~~
{:.bash}

File *extract_energies.sh* 

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

~~~
df=pd.read_table('energy.dat', delim_whitespace=True)
df.columns=["Time", "Etot", "Temp", "Press", "Volume"]
df.plot(subplots=True, x="Time", xlabel="Time, ps", figsize=(6, 8))
plt.show()
~~~
{:.python}
