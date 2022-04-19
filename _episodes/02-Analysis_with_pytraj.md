---
title: "Trajectory Analysis with PYTRAJ in Jupyter Notebook"
teaching: 25
exercises: 0
questions:
- "How to visualize simulation in Jupyter notebook?"
- "How can I use PYTRAJ to analyze MD-trajectories?"
- "How do I calculate dynamical properties from trajectory data?"
- "How can I characterize motions of macromolecules?"
objectives:
- "Learn how to use NGLView to visualize MD-trajectories."
- "Learn how to calculate and plot RMSD"
- "Learn how to perform Dynamic Cross Correlation Analysis"
- "Learn how to perform Principal Component Analysis"
- "Learn how to run analysis in parallel using MPI"
keypoints:
- "By keeping everything in one easy accessible place Jupyter notebooks greatly simplify the management and sharing of your work"
---

## Computing RMSD with pytraj
We are now ready to use pytraj in Jupyter notebook. First load pytraj, numpy, and matplotlib modules. Then move into the directory where the input data files are located.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_rmsd.ipynb)

~~~
import pytraj as pt
import numpy as np
from matplotlib import pyplot as plt

%cd ~/scratch/workshop/pdb/6N4O/simulation/sim_pmemd/4-production
~~~
{: .language-python}

Load the topology and the trajectory:

~~~
traj=pt.iterload('mdcrd_nowat.nc', top='prmtop_nowat.parm7') 
~~~
{: .language-python}

- You can use a single filename, a list of filenames or a pattern. 
- The *ptraj.iterload* method returns a frame iterator object. This means that it registers what trajectories will be processed without actually loading them into memory. One frame will be loaded at a time when needed at the time of processing. This saves memory and allows for analysis of large trajectories. 
- The *ptraj.load* method returns a trajectory object. In this case all trajectory frames are loaded into memory.
- You can also select slices from each of the trajectories, for example:

~~~
traj_slice=pt.iterload('mdcrd_nowat.nc', top='prmtop_nowat.parm7', frame_slice=[(100, 110)]) 
~~~
{: .language-python}

will load only frames from 100 to 110 from `mdcrd_nowat.nc`.

[View *ptraj.iterload* manual](https://amber-md.github.io/pytraj/latest/_api/pytraj.io.html#pytraj.io.iterload)

Other ways to select frames and atoms:
~~~
print(traj[-1])    # The last frame
print(traj[0:8])   # Frames 0 to 7
print(traj[0:8:2]) # Frames 0 to 7 with stride 2
print(traj[::2])   # All frames with stride 2
~~~
{: .language-python}

To compute RMSD we need a reference structure. We will use the initial pdb file to see how different is our simulation from  the experimental structure. 
- Load the reference frame
~~~
ref_coor = pt.load('inpcrd_nowat.pdb')
~~~
  {: .language-python}

- You can also use any trajectory frame, for example ref_crd = traj[0] as a reference structure.  

Before computing RMSD automatically center and image molecules/residues/atoms that are outside of the box back into the box.

~~~
traj=traj.autoimage()
~~~
{: .language-python}

Generate time axis for RMSD plot. The trajectory was saved every 0.001 ns, and we have 2000 frames.
~~~
time=np.linspace(0, 1.999, 2000)
~~~
{: .language-python}

Compute and plot RMSD of the protein backbone atoms.
- We can compute and plot rmsd using the initial pdb file and a frame from the trajectory as reference structure.
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

>## Exercise
>1. Compute and plot RMSD of all nucleic acid atoms (residues U,A,G,C) excluding hydrogens for all frames.  
>2. Compute and plot RMSD of all protein atoms excluding hydrogens for frames 1000-1999.  
>3. Repeat using coordinates from frame 500 as a reference.  
>[View Atom selection syntax](https://amber-md.github.io/pytraj/latest/atom_mask_selection.html#atom-selections)
>
>> ## Solution
>>
>>~~~
>>traj=pt.iterload('mdcrd_nowat.nc', top='prmtop_nowat.parm7')
>>rmsd_ref = pt.rmsd(traj, ref=ref_coor, nofit=False, mask='(:U,A,G,C)&!(@H=)')
>>
>>rmsd_ref = pt.rmsd(traj[1000:2000], ref=ref_coor, nofit=False, mask='(:1-859)&!(@H=)')
>>time=np.linspace(1.0, 2.0, 1000)
>>
>>~~~
>>{: .language-python}
>{:.solution}
{:.challenge}



### Distributed parallel RMSD calculation with pytraj
[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_rmsd_mpi.ipynb)

~~~
import pytraj as pt
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns
import pickle

%cd ~/scratch/workshop/pdb/6N4O/simulation/sim_pmemd/4-production
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
traj=pt.iterload('mdcrd_nowat.nc', top='prmtop_nowat.parm7') 
ref_coor = pt.load('inpcrd_nowat.pdb')

# call pmap_mpi function for MPI.
# we don't need to specify the number of CPUs, 
# because we will use srun to run the script
data = pt.pmap_mpi(pt.rmsd, traj, mask='@C,N,O', ref=ref_coor)

# pmap_mpi sends data to rank 0
# rank 0 saves data 
if rank == 0:
    with open("rmsd.dat", "wb") as fp: 
         pickle.dump(data, fp)
~~~
{: .language-python}

Run the script on the cluster. We will take advantage of the resources we have already allocated with `salloc` command and simply use `srun` without requesting anything:   
~~~
! srun python rmsd.py
~~~
{: .language-python}

In practice you will be submitting large analysis jobs to the queue with the `sbatch` command from a normal submission script requesting the desired number of MPI tasks (ntasks).

When the job is done we import the results saved in the file `rmsd.dat` into Python and generate time axis as we have done before:

~~~
with open("rmsd.dat", "rb") as fp: 
    rmsd=pickle.load(fp)
data=rmsd.get('RMSD_00001')
time=np.linspace(0,1.999,2000)
~~~
{: .language-python}

- Set *seaborn* plot theme parameters and plot the data
~~~
sns.set_theme()
sns.set_style("darkgrid")
plt.plot(time,rmsd)
plt.xlabel("Time, ns")
plt.ylabel("RMSD, $ \AA $")
~~~
  {: .language-python}

### Interactive trajectory visualization with NGLView
Data Visualization is one of the essential skills required to conduct a successful research involving molecular dynamics simulations. It allows you (or other people in the team) to better understand the nature of a process you are studying, and it gives you the ability to convey the proper message to a general audience in a publication. 

NGLView is a Jupyter widget for interactive viewing molecular structures and trajectories in notebooks. It runs in a browser and employs WebGL to display molecules like proteins and DNA/RNA with a variety of representations. It is also available as a standalone [Web application](http://nglviewer.org/ngl/).

Open a new notebook. Import pytraj, nglview and make sure you are in the right directory    
~~~
import pytraj as pt
import nglview as nv
%cd ~/scratch/workshop/pdb/6N4O/simulation/sim_pmemd/4-production
~~~
{: .language-python}   

Load the trajectory:  
~~~
traj=pt.iterload('mdcrd_nowat.nc', top = 'prmtop_nowat.parm7')
~~~
{: .language-python}

Take care of the molecules that moved out of the initial box.  The `autoimage` function will automatically center and image molecules/residues/atoms that are outside of the box back into the initial box.
~~~
traj = traj.autoimage()
~~~  
{: .language-python}

Create NGLview widget 
~~~
view = nv.show_pytraj(traj)
~~~  
{: .language-python}

- The default representation is ball and sticks
- The defaults selection is all atoms

Render the view. Try interacting with the viewer using [Mouse](http://nglviewer.org/ngl/api/manual/interaction-controls.html#mouse) and [Keyboard](http://nglviewer.org/ngl/api/manual/interaction-controls.html#keyboard) controls.
~~~
view 
~~~  
{: .language-python}

Create second view and clear it
~~~
view2=nv.show_pytraj(traj)
view2.clear()
~~~
{: .language-python}

Add cartoon representation
~~~
view2.add_cartoon('protein', colorScheme="residueindex", opacity=1.0)
~~~
{: .language-python}

- [Coloring schemes](https://nglviewer.org/ngl/api/manual/usage/coloring.html)

Render the view.
~~~
view2 
~~~  
{: .language-python}

Change background color and projection
~~~
view2.background="black"
view2.camera='orthographic'
~~~  
{: .language-python}

Add more representations. You can find samples of all representations [here](http://proteinformatics.charite.de/ngl/doc/#User_manual/Usage/Molecular_representations). 

~~~
view2.remove_cartoon()
view2.add_hyperball(':B or :C and not hydrogen', colorScheme="element")
~~~
{: .language-python}

Change animation speed and step
~~~
view2.player.parameters = dict(delay=0.5, step=1)
~~~  
{: .language-python}

Make animation smoother
~~~
view.player.interpolate = True
~~~  
{: .language-python}

Try visualizing different atom selections. Selection language is described [here](https://nglviewer.org/ngl/api/manual/usage/selection-language.html)

- You can use GUI
~~~
view4=nv.show_pytraj(traj)
view4.display(gui=True)
~~~
  {: .language-python}

- Use filter to select atoms  
- Create nucleic representation
- Use hamburger menu to change representation properties 
- Change `surfaceType` to av
- Use `colorValue` to change color
- Check wireframe box
- Try full screen
- Add nucleic representation hyperball

Set size of the widget programmatically
~~~
view3=nv.show_pytraj(traj)
view3._remote_call('setSize', target='Widget', args=['700px', '440px'])
~~~  
{: .language-python}

~~~
view3
view3.clear()
~~~
{: .language-python}

- Add representations
~~~
view3.add_ball_and_stick('protein', opacity=0.3, color='grey')
view3.add_hyperball(':B or :C and not hydrogen', colorScheme="element")
view3.add_tube(':B or :C and not hydrogen')
view3.add_spacefill('MG',colorScheme='element')
~~~  
  {: .language-python}

Try changing display projection
~~~
view3.camera='orthographic'
~~~  
{: .language-python}
https://github.com/ComputeCanada/molmodsim-pytraj-analysis/blob/gh-pages/code/Notebooks/pytraj_nglview.ipynb

### Useful links

- AMBER/pytraj  
  - [Atom mask selection](https://amber-md.github.io/pytraj/latest/atom_mask_selection.html#atom-selections)

- NGL viewer 
  - [Documentation](http://nglviewer.org/nglview/latest/)
  - [Coloring schemes](https://nglviewer.org/ngl/api/manual/usage/coloring.html)
  - [Molecular representations](http://proteinformatics.charite.de/ngl/doc/#User_manual/Usage/Molecular_representations)
  - [Selection language](https://nglviewer.org/ngl/api/manual/usage/selection-language.html)
  - [Index](http://nglviewer.org/nglview/latest/genindex.html)
  - [Tutorial](https://ambermd.org/tutorials/analysis/tutorial_notebooks/nglview_notebook/index.html)
- Color maps
  - [Matplotlib](https://matplotlib.org/3.1.0/tutorials/colors/colormaps.html) 
  - [Seaborn](https://seaborn.pydata.org/tutorial/color_palettes.html)


#### References

1. [NGL viewer: web-based molecular graphics for large complexes](https://academic.oup.com/bioinformatics/article/34/21/3755/5021685)


### Principal component analysis
Principal components can be thought of as a way to explain variance in data. Through PCA, very complex molecular motion is decomposed into orthogonal components. Once these components are sorted, the most significant motions can be identified. 

PCA involves diagonalizing the covariance matrix to eliminate instantaneous linear correlations between atomic coordinate fluctuations. We call the largest eigenvectors of the covariance matrix, principal components (PC). After PC are sorted according to their contribution to the overall fluctuations of the data, the first PC describes the largest variance and so forth. 

Researchers have found that only a few of the largest principal components are able to accurately describe the dominant motion of the system. Thus, a PCA provides insight into the dynamics of a system by identifying the most prominent motions. 

PCA is a complex procedure with many steps. It uses the coordinate covariance matrix calculated from the molecular dynamics trajectory. 
1. To prepare the trajectory for PCA, the coordinates are fitted to a reference frame to eliminate global translations and rotations. 
2. Next, the coordinate covariance matrix (the matrix of deviations from the average structure) is calculated and diagonalized. The diagonalization procedure yields the eigenvectors and the eigenvalues (the contribution of each eigenvector to the total fluctuations). 
3. Once we determine which eigenvectors (PCs) are the largest, we can project trajectory coordinates onto each of them. The term trajectory here refers to a transformed trajectory, in which the coordinates represent each atom's deviation from its average position. When we project this trajectory onto a PC, we will obtain a pseudo-trajectory that is a representation of motion along the principal component.

PCA steps are performed automatically by the *pca* module of *ptraj*.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_pca.ipynb)

#### Visualizing normal modes with VMD plugin Normal Mode Wizard

Download the file "modes.nmd"
~~~
scp user100@moledynii.ace-net.training:scratch/workshop/pdb/6N4O/simulation/sim_pmemd/4-production/modes.nmd .
~~~
{: .language-bash}

- Open VMD
- Go to `Extensions` -> `Analysis` -> `Normal Mode Wizard` -> `Load NMD File`
- Navigate to the file `modes.nmd`
- In the popup window `NMWiz - PCA models` chose the `Active mode` and press `Animation` - `Make` box.

### Cross-correlation analysis.
Collective motions of atoms in proteins are crucial for the biological function. Molecular dynamics trajectories offer insight into collective motions, which are difficult to see experimentally. By analyzing atomic motions in the simulation, we can identify how all atoms in the system are dynamically linked. 

This type of analysis can be performed with the dynamic cross-correlation module *atomiccorr*. The module computes a matrix of atom-wise cross-correlation coefficients. Matrix elements indicate how strongly two atoms i and j move together.  Correlation values range between -1 and 1, where 1 represents full correlation, and -1 represents anticorrelation.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_xcorr.ipynb)

[Dynamical cross-correlation matrices](https://pubmed.ncbi.nlm.nih.gov/7563068/)
