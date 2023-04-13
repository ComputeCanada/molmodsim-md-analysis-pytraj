---
title: "Cross-correlation Analysis"
teaching: 25
exercises: 0
questions:
- "How to perform cross-correlation analysis?"
- "How to visualize cross-correlation matrices"
objectives:
- "Learn to perform cross-correlation analysis"
- "Learn to visualize cross-correlation matrices"
keypoints:
- " "
---

### Cross-correlation analysis.
Collective motions of atoms in proteins are crucial for the biological function. Molecular dynamics trajectories offer insight into collective motions, which are difficult to see experimentally. By analyzing atomic motions in the simulation, we can identify how all atoms in the system are dynamically linked. 

This type of analysis can be performed with the dynamic cross-correlation module *`atomiccorr`*. The module computes a matrix of atom-wise cross-correlation coefficients. Matrix elements indicate how strongly two atoms `i` and `j` move together.  Correlation values range between -1 and 1, where 1 represents full correlation, and -1 represents anticorrelation.

[View Notebook]({{ site.repo_url }}/blob/{{ site.default_branch }}/code/Notebooks/pytraj_xcorr.ipynb)

[Dynamical cross-correlation matrices](https://pubmed.ncbi.nlm.nih.gov/7563068/)

