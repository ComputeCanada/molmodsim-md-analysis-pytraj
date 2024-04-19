---
title: "The Basics of PYTRAJ"
teaching: 25
exercises: 0
questions:
- "How to load MD-trajectories into PYTRAJ?"
- "How to calculate RMSD to a reference?"
objectives:
- "Learn how to calculate and plot RMSD"
- "Learn how to run analysis in parallel using MPI"
keypoints:
- "By keeping everything in one easy accessible place Jupyter notebooks greatly simplify the management and sharing of your work"
---

### Computing RMSD
We are now ready to use pytraj in a Jupyter notebook.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_rmsd.ipynb)

~~~
import pytraj as pt
import numpy as np
from matplotlib import pyplot as plt

%cd ~/workshop_pytraj/example_02
~~~
{: .language-python}

Load the topology and the trajectory:
~~~
traj=pt.iterload('mdcrd_nowat.xtc', top='prmtop_nowat.parm7') 
~~~
{: .language-python}

- You can load a single filename, a list of filenames or a pattern. 
- There are two functions for loading trajectories
- The `ptraj.iterload` method returns a frame iterator object. This means that it registers what trajectories will be processed without actually loading them into memory. One frame will be loaded at a time when needed at the time of processing. This saves memory and allows for analysis of large trajectories. 
- The `ptraj.load` method returns a trajectory object. In this case all trajectory frames are loaded into memory.

You can also select slices from each of the trajectories, for example load only frames from 100 to 110 from `mdcrd_nowat.xtc`:
~~~
traj_slice=pt.iterload('mdcrd_nowat.xtc', top='prmtop_nowat.parm7', frame_slice=[(100, 110)]) 
~~~
{: .language-python}

[View *ptraj.iterload* manual](https://amber-md.github.io/pytraj/latest/_api/pytraj.io.html#pytraj.io.iterload)


To compute RMSD we need a reference structure. We will use the initial pdb file to see how different is our simulation from  the experimental structure. 
Load the reference frame:
~~~
ref_coor = pt.load('inpcrd_nowat.pdb')
~~~
  {: .language-python}

- You can also use any trajectory frame, for example `ref_coor = traj[0]` as a reference structure.  

Before computing RMSD automatically center and image molecules/residues/atoms that are outside of the box back into the box.

~~~
traj=traj.autoimage()
~~~
{: .language-python}

Generate time axis for RMSD plot. The trajectory was saved every 0.001 ns, and we have 3140 frames.
~~~
time=np.linspace(0, 3.139, 3140)
~~~
{: .language-python}

Compute and plot RMSD of the protein backbone atoms. We can compute and plot RMSD using the initial pdb file and a frame from the trajectory as reference structure.
~~~
rmsd_ref = pt.rmsd(traj, ref=ref_coor, nofit=False, mask='@C,N,O')
rmsd_first= pt.rmsd(traj, ref=traj[0], nofit=False, mask='@C,N,O')
plt.plot(time,rmsd_ref)
plt.plot(time,rmsd_first)
plt.xlabel("Time, ns")
plt.ylabel("RMSD, $ \AA $")
plt.show()
~~~
  {: .language-python}

### Slicing trajectories
Other ways to slice a trajectory:
~~~
print(traj[-1])     # The last frame
print(traj[0:8])    # Frames 0 to 7
print(traj[0:8:2])  # Frames 0 to 7 with stride 2
print(traj[::2])    # All frames with stride 2
print(traj(0,20,4)) # Creates frame iterator with (start, stop, step)
~~~
{: .language-python}

>## Exercise
>1. Compute and plot RMSD of all nucleic acid atoms (residues U,A,G,C) excluding hydrogens for all frames.  
>2. Compute and plot RMSD of all protein atoms (residues 1-859) excluding hydrogens for frames 1000-1999.  
>3. Repeat using coordinates from frame 500 as a reference.  
>[View Atom selection syntax](https://amber-md.github.io/pytraj/latest/atom_mask_selection.html#atom-selections)
>
>> ## Solution
>>
>>~~~
>>time1=np.linspace(0,3.139,3140)
>>rmsd1 = pt.rmsd(traj, ref=ref_coor, nofit=False, mask='(:U,A,G,C)&!(@H=)')
>>time2=np.linspace(1,1.999,1000)
>>rmsd2 = pt.rmsd(traj(1000,2000), ref=ref_coor, nofit=False, mask='(:1-859)&!(@H=)')
>>plt.plot(time1,rmsd1)
>>plt.plot(time2,rmsd2)
>>plt.xlabel("Time, ns")
>>plt.ylabel("RMSD, $ \AA $")
>>~~~
>>{: .language-python}
>{:.solution}
{:.challenge}

### Distributed Parallel RMSD Calculation
[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_rmsd_mpi.ipynb)

~~~
import pytraj as pt
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns
import pickle

cd ~/workshop_pytraj/example_02
~~~
{: .language-python}

To process trajectory in parallel we need to create a Python script file `rmsd.py` instead of entering commands in the notebook.  This script when executed with `srun` will use all available MPI tasks. Each task will process its share of frames and send the result to the master task. The master task will "pickle" the computed rmsd data and save it as a Python object.   

To create the Python script directly from the notebook we will use Jupyter magic command %%file.  

~~~
%%file rmsd.py

import pytraj as pt
import pickle
from mpi4py import MPI

# initialize MPI 
comm = MPI.COMM_WORLD

# get the rank of the process
rank = comm.rank

# load the trajectory file
traj=pt.iterload('mdcrd_nowat.xtc', top='prmtop_nowat.parm7') 
ref_coor = pt.load('inpcrd_nowat.pdb')

# call pmap_mpi function for MPI.
# we dont need to specify the number of CPUs, 
# because we will use srun to run the script
data = pt.pmap_mpi(pt.rmsd, traj, mask='@C,N,O', ref=ref_coor)

# pmap_mpi sends data to rank 0
# rank 0 saves data 
if rank == 0:
    with open("rmsd.dat", "wb") as fp: 
         pickle.dump(data, fp)
~~~
{: .language-python}

Run the script on the cluster. We will take advantage of the resources we have already allocated when we launched Jupyter server and simply use `srun` without requesting anything:   
~~~
! srun python rmsd.py
~~~
{: .language-python}

In practice you will be submitting large analysis jobs to the queue with the `sbatch` command from a normal submission script requesting the desired number of MPI tasks (ntasks).

When the job is done we import the results saved in the file `rmsd.dat` into Python:
~~~
with open("rmsd.dat", "rb") as fp: 
    data=pickle.load(fp)
rmsd=data.get('RMSD_00001')
~~~
{: .language-python}

Set `*seaborn*` plot theme parameters and plot the data:
~~~
sns.set_theme()
sns.set_style("darkgrid")
time=np.linspace(0,3.139,3140)
plt.plot(time,rmsd)
plt.xlabel("Time, ns")
plt.ylabel("RMSD, $ \AA $")
~~~
  {: .language-python}

