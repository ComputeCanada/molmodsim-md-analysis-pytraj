---
title: "Trajectory Visualization in Jupyter Notebook"
teaching: 25
exercises: 0
questions:
- "How to visualize simulation in Jupyter notebook?"
objectives:
- "Learn how to use NGLView to visualize trajectories."
keypoints:
- " "
---


### Interactive trajectory visualization with NGLView
Data Visualization is one of the essential skills required to conduct a successful research involving molecular dynamics simulations. It allows you (or other people in the team) to better understand the nature of a process you are studying, and it gives you the ability to convey the proper message to a general audience in a publication. 

NGLView is a Jupyter widget for interactive viewing molecular structures and trajectories in notebooks. It runs in a browser and employs WebGL to display molecules like proteins and DNA/RNA with a variety of representations. It is also available as a standalone [Web application](http://nglviewer.org/ngl/).

Open a new notebook. Import pytraj, nglview and make sure you are in the right directory    
~~~
import pytraj as pt
import nglview as nv
%cd ~/workshop_pytraj/example_02
~~~
{: .language-python}   

Quick test - download and visualize 1si4.pdb. 
~~~
import nglview as nv
view = nv.show_pdbid("1si4")
view
~~~

Load the trajectory:  
~~~
traj=pt.iterload('mdcrd_nowat.xtc', top = 'prmtop_nowat.parm7', frame_slice=[(0,1000)])
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


