---
title: "Principal Component Analysis"
teaching: 25
exercises: 0
questions:
- "How to perform principal component analysis?"
- "How to visualize principal components with VMD"
objectives:
- "Perform principal component analysis"
- "Visualize principal components with VMD"
keypoints:
- " "
---

### Principal component analysis
Principal components can be thought of as a way to explain variance in data. Through PCA, very complex molecular motion is decomposed into orthogonal components. Once these components are sorted, the most significant motions can be identified. 

PCA involves diagonalizing the covariance matrix to eliminate instantaneous linear correlations between atomic coordinate fluctuations. We call the largest eigenvectors of the covariance matrix, principal components (PC). After PC are sorted according to their contribution to the overall fluctuations of the data, the first PC describes the largest variance and so forth. 

Researchers have found that only a few of the largest principal components are able to accurately describe the dominant motion of the system. Thus, a PCA provides insight into the dynamics of a system by identifying the most prominent motions. 

PCA is a complex procedure with many steps. It uses the coordinate covariance matrix calculated from the molecular dynamics trajectory. 
1. To prepare the trajectory for PCA, the coordinates are fitted to a reference frame to eliminate global translations and rotations. 
2. Next, the coordinate covariance matrix (the matrix of deviations from the average structure) is calculated and diagonalized. The diagonalization procedure yields the eigenvectors and the eigenvalues (the contribution of each eigenvector to the total fluctuations). 
3. Once we determine which eigenvectors (principal components) are the largest, we can project trajectory coordinates onto each of them. The term trajectory here refers to a transformed trajectory, in which the coordinates represent each atom's deviation from its average position. When we project this trajectory onto a PC, we will obtain a pseudo-trajectory that is a representation of motion along the principal component.

All PCA steps are performed automatically by the *`pca`* module of *`ptraj`*.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_pca.ipynb)


~~~
import pytraj as pt
import nglview as nv
import numpy as np
import parmed
from matplotlib import pyplot as plt

%cd ~/workshop_pytraj/example_02
~~~
{: .language-python}

Register all trajectory frames for analysis and move molecules back to the initial box.
~~~
frames=pt.iterload('mdcrd_nowat.xtc', top = 'prmtop_nowat.parm7')
frames = frames.autoimage()
~~~
{: .language-python}

- The results are saved in the structure *data*
- Projection values of each frame to each of the 5 modes are saved in the arrays data[0][0], ... , data[0][4]
- Eigvenvalues of the first 5 modes are saved in the array data[1][0]
- Eigvenvectors of first 5 modes are saved in the arrays data[1][1][0], ... , data[1][1][4]

#### Perform PCA analysis

- Analyze 39 nucleic acid residues, 6 backbone atoms in each residue. The total number of atoms included in the analysis is 234, so eigenvectors will be 234 elements long.
- Request calculations of the three first principal components  

~~~
data = pt.pca(frames, mask=":860-898@O3',C3',C4',C5',O5',P", n_vecs=5)
~~~
{: .language-python}

~~~
print('Projection values of each frame to the first mode = {} \n'.format(data[0][0]))
print('Eigvenvalues of the first 5 modes:\n', data[1][0])
print('Eigvenvector of the first mode:\n', data[1][1][0])
~~~
{: .language-python}

- Plot projection of each frame on the first two modes
- Color by frame number

[Available color maps](https://matplotlib.org/3.1.0/tutorials/colors/colormaps.html)

~~~
plt.scatter(data[0][0], data[0][1], cmap='viridis', marker='o', c=range(frames.n_frames), alpha=0.5)
plt.xlabel('PC1')
plt.ylabel('PC2')
cbar = plt.colorbar()
cbar.set_label('frame #')
~~~
{: .language-python}

When you look at such plot and see two or more clusters this means that several different conformations exist in the simulation. Our graph shows that the first component separates data into two clusters. The first cluster existed in the beginning of the simulation, and later in the simulation the average projection on this component shifted from 10 to -5. This example trajectory is too short for any reliable conclusion. The results suggest that the system may not yet reached equilibrium.

#### Visualizing normal modes with VMD plugin Normal Mode Wizard

Download the file "modes.nmd"
~~~
scp user100@moledyn.ace-net.training:workshop_pytraj/example_02/modes.nmd .
~~~
{: .language-bash}

- Open VMD
- Go to `Extensions` -> `Analysis` -> `Normal Mode Wizard` -> `Load NMD File`
- Navigate to the file `modes.nmd`
- In the popup window `NMWiz - PCA models` chose the `Active mode` and press `Animation` - `Make` box.

