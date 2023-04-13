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

