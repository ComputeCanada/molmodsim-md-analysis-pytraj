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

## Computing RMSD 
We are now ready to use pytraj in Jupyter notebook. First load pytraj, numpy, and matplotlib modules. Then move into the directory where the input data files are located.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_rmsd.ipynb)

~~~
import pytraj as pt
import numpy as np
from matplotlib import pyplot as plt

%cd ~/scratch/Ago-RNA_sim/sim_pmemd/2-production/
~~~
{: .python}

Load the topology and the trajectory:

~~~
traj=pt.iterload('mdcrd', top = 'prmtop.parm7')
~~~
{: .python}

The `iterload` method can load multiple trajectories, supplied as a python list. You can also select slices from each of the trajectories, for example:

~~~
test=pt.iterload('mdcrd', top = 'prmtop.parm7', frame_slice=[(100, 110)]) 
~~~

will load only frames from 100 to 110 from mdcrd.

Other ways to select frames and atoms:

~~~
print(test)
print(test[-1]) # last frame
print(test[0:8])
print(test[0:8:2])
print(test[::2])
print(test[0:8:2, ':U'])
print(test[0:8:2, ':U@P'])
traj[8:2:-2, '!:WAT']
traj[8:2:-2, '!:WAT & !@H']
~~~
{: .python}

Load the reference frame
~~~
ref_crd = pt.load('../../inpcrd.pdb')
~~~
{: .python}

You can also use any trajectory frame, for example ref_crd = trj[0] as a reference structure.  

Before computing RMSD automatically center and image molecules/residues/atoms that are outside of the box back into the box.

~~~
traj=traj.autoimage()
~~~
{: .python}

Generate X-axis for RMSD plot. The trajectory was saved every 0.001 ns.
~~~
tstep = 0.001 
time = np.arange(0, traj.n_frames-1)*tstep
~~~
{: .python}

We want to compute RMSD for protein backbone atoms. To select these atoms we need to know the index numbers of protein residues. Protein comes first in the system, and to find the number of the last residue we can grep C-terminal oxygen:

~~~
!grep OXT ../../inpcrd.pdb 
~~~

Finally compute and plot RMSD: 

~~~
rmsd_data = pt.rmsd(traj, ref = ref_crd, nofit = False, mask = ':1-859@C,N,O')
plt.plot(time,rmsd_data)
plt.xlabel("Time, ns")
plt.ylabel("RMSD, Angstrom")
~~~
{: .python}

#### Parallel trajectory analysis using MPI
[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_rmsd_mpi.ipynb)

~~~
%cd ~/scratch/Ago-RNA_sim/sim_pmemd/2-production/
import numpy as np
import pickle
~~~
{: .python}

To process trajectory in parallel we need to create a python script file rmsd.py instead of entering commands in the notebook.  This script when executed with srun will use all available MPI tasks. Each task will process its share of frames and send the result to the master task. The master task will "pickle" the computed rmsd data and save it as a python object.   

To create the python script directly from the notebook we will use Jupyter magic command %%file.  

~~~
%%file rmsd.py

import pytraj as pt
import pickle
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.rank

# load data files
traj = pt.iterload(['mdcrd'], top='prmtop.parm7')
ref_crd = pt.load('../../inpcrd.pdb')

# call pmap_mpi for MPI. We dont need to specify n_cores=x here since we will use srun.

data = pt.pmap_mpi(pt.rmsd, traj, mask=':1-859,@C,N,O', ref=ref_crd)

# computed RMSD data is sent to the master task (rank==0),
# and saved in the file rmsd.dat 
if rank == 0:
    print(data)
    with open("rmsd.dat", "wb") as fp: 
         pickle.dump(data, fp)
~~~
{: .python}


Run the script on the cluster. We will take advantage of the resources we have already allocated with salloc command and simply use srun without requesting anything:   

~~~
! srun python rmsd.py
~~~
{: .python}

In practice you will be submitting large analysis jobs to the queue with the sbatch command from a normal submission script requesting the desired number of MPI tasks (ntasks).


When the job is done we import the results saved in the file rmsd.dat into python and plot RMSD as we have done above:

~~~
with open("rmsd.dat", "rb") as fp: 
    rmsd=pickle.load(fp)
data=rmsd.get('RMSD_00001')
tstep=0.001
time=np.arange(0, len(data))*tstep

plt.plot(time,data)
plt.xlabel("Time, ns")
plt.ylabel("RMSD, Angstrom")
~~~
{: .python}


### Interactive trajectory visualization with NGLView

Data Visualization is one of the essential skills required to conduct a successful research involving molecular dynamics simulations. It allows you (or other people in the team) to better understand the nature of a process you are studying, and it gives you the ability to convey the proper message to a general audience in a publication. 


NGLView is a Jupyter widget for interactive viewing molecular structures and trajectories in notebooks. It runs in a browser and employs WebGL to display molecules like proteins and DNA/RNA with a variety of representations. It is also available as a standalone [Web application](http://nglviewer.org/ngl/).

Open a new notebook. Import pytraj, nglview and make sure you are in the right directory    

~~~
import pytraj as pt
import nglview as nv
%cd ~/scratch/Ago-RNA_sim/sim_pmemd/2-production/
~~~
{: .python}   

Load the trajectory:  

~~~
traj = pt.iterload('mdcrd', top = 'prmtop.parm7')
~~~
{: .python}

Automatically center and image molecules/residues/atoms that are outside of the box back into the box.  

~~~
traj = traj.autoimage()
~~~  
{: .python}

Strip water and ions

~~~
trj=traj.strip(':WAT, Na+, Cl-')
~~~  
{: .python}

Create NGLview widget 

~~~
view = nv.show_pytraj(trj)
~~~  
{: .python}

Delete the default representation

~~~
view.clear()
~~~  
{: .python}

Add protein cartoon representation

~~~
view.add_cartoon('protein', colorScheme="residueindex", opacity=1.0)
~~~  
{: .python}

Render the view. Try interacting with the viewer using [Mouse](http://nglviewer.org/ngl/api/manual/interaction-controls.html#mouse) and [Keyboard](http://nglviewer.org/ngl/api/manual/interaction-controls.html#keyboard) controls.

~~~
view 
~~~  
{: .python}

Add more representations. You can find samples of all representations [here](http://proteinformatics.charite.de/ngl/doc/#User_manual/Usage/Molecular_representations). 

Try using different [coloring schemes](https://nglviewer.org/ngl/api/manual/usage/coloring.html).  

Try visualizing different  selections. Selection language is described [here](https://nglviewer.org/ngl/api/manual/usage/selection-language.html)

~~~
view.add_licorice('protein', opacity=0.3)
view.add_hyperball(':B and not hydrogen', colorScheme="element")
view.add_hyperball(':C and not hydrogen', colorScheme="element")
view.add_spacefill('MG',colorScheme='element')
~~~  
{: .python}

Change background color

~~~
view.background="black"
~~~  
{: .python}

Change animation speed and step

~~~
view.player.parameters = dict(delay=0.5, step=1)
~~~  
{: .python}

Try changing display projection

~~~
view.camera='orthographic'
~~~  
{: .python}

Make animation smoother

~~~
view.player.interpolate = True
~~~  
{: .python}

Set size of the widget programmatically

~~~
view._remote_call('setSize', target='Widget', args=['700px', '400px'])
~~~  
{: .python}

Remove cartoon representation

~~~
view.remove_cartoon()
~~~  
{: .python}

Select all residues within a distance of residue 10

~~~
trj=traj[:10<:5]
~~~
{: .python}

Turn on GUI

~~~
view.display(gui=True)
~~~
{: .python}

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
One way to think of Principal Components is that they are a means of explaining variance in the data. PCA performed on MD trajectories decomposes very complex molecular motion into a set of orthogonal components. Algorithmically PCA performs a linear transformation that diagonalizes the covariance matrix and thus it removes the instantaneous linear correlations among the fluctuations of atomic coordinates. Principal Components are sorted by their contribution to the overall fluctuations. The first PC describes the largest variance in the data, the second PC shows the second largest and so on. PCA is useful for gaining insight into the dynamics of a system. It has been shown that a dominant motion of the system can be described by just a few largest principal components. 

The input to PCA is the coordinate covariance matrix calculated from the molecular dynamics trajectory. The trajectory for PCA is prepared by RMS fitting of the coordinate to a reference frame to eliminate global translational and rotational motions. Then the coordinate covariance matrix (the matrix of deviations from average structure) is computed. Once the matrix is computed, PCs are obtained by diagonalizing it. The diagonalization procedure yield the eigenvectors (we call them the PCs) and the eigenvalues (the contribution of each PC to the total fluctuations). Once the PCs are found we can project the trajectory coordinates on the principal components. By trajectory here we mean the transformed trajectory where coordinates are deviations of each atom form its average position.  Projection of the trajectory on PCs will yield a pseudo-trajectories of motion along each principal component which can be visualized with VMD.

Overall PCA is quite complex procedure involving many steps. All necessary PCA steps are carried out automatically by the *pca* module of *ptraj*.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_pca.ipynb)

#### Visualizing normal modes with VMD plugin Normal Mode Wizard

Download the file "modes.nmd"
~~~
scp user45@moledyn.ace-net.training:scratch/workshop/pdb/6N4O/simulation/sim_pmemd/4-production/modes.nmd .
~~~
{:.bash}

- Open VMD
- Go to `Extensions` -> `Analysis` -> `Normal Mode Wizard` -> `Load NMD File`
- Navigate to the file `modes.nmd`
- In the popup window `NMWiz - PCA models` chose the `Active mode` and press `Animation` - `Make` box.

### Cross-correlation analysis.
Collective motions of atoms in proteins are crucial for the biological function. Collective motions are difficult to observe experimentally, but molecular dynamics trajectories can provide this information. The dynamic correlation between all atoms within the system can be obtained by analyzing atomic motions in the simulation. 

The pytraj dynamic cross-correlation module *atomiccorr* computes a matrix of atom-wise cross-correlation coefficients. Each matrix element describes the degree to which a pair of atoms i and j move together. The correlation values lie between -1 and 1, where 1 describes full correlation, and -1 corresponds to anti-correlation.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_xcorr.ipynb)

[Dynamical cross-correlation matrices](https://pubmed.ncbi.nlm.nih.gov/7563068/)
