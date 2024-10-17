# SimulationsEVS

Computational simulation model of the early visual system.

## Requirements

Needed is MATLAB (Mathworks). The software has been tested on a PC with 
Windows 11 running Matlab R2023b.

## Installation guide

Download the code, including the subfolders, into a folder. In MATLAB, change
your working directory into that folder or add the folder to the MATLAB path.

## Instructions for use

This framework uses four core functions to run a leaky integrate-and-fire 
neuron model simulation of (at this moment) monkey V1 and V2. Work is 
underway to widen its applicability. The four functions are:

1. runBuildConnectivity.m
2. runBuildStimulation.m
3. runSimulation.m 
4. runSimBatchAggregator.m

The program runBuildConnectivity.m (1) creates a .mat file containing the 
synaptic connectivity and simulation parameters. It in turn uses the 
subfunction buildConnectivity() to create the actual connectivity matrix. 
You can set the simulation parameters and model connectivity by editing the
fields of the sConnParams structure in this file. See the function 
buildConnectivity() for more information. This function effectively creates 
the "anatomy" of your model network, which you can then use to run a 
simulation.

The second script that is required to run the simulation is 
runBuildStimulation (2), which creates the input that will feed into the 
network through a simplified retina/LGN filter layer. This function can 
create visual stimuli in retinal degrees, just as you would for an actual 
visual neuroscience experiment.

The main workhorse is accessed through runSimulation.m (3). These functions
use string-based inputs with parameter delimited by commas so compiled 
version can also be started from the command line. 

The difference between 
the two functions is that (3a) will simulate a single retina, which means 
that shared noise will propagate to cortex and induce information-limiting 
correlations. If you want to remove this source of shared fluctuations, you 
will have to use (3b). The drawback of (3b) is that simulating independent 
inputs for all V1 cells is computationally very intensive, so it will 
noticeably slow down the simulation speed.

Finally, if you run the simulation on a cluster with independent workers in
a massively parallel manner, you can use runSimBatchAggregator.m (4) to 
combine the separate simulation runs from a single connectivity structure 
into one data file. See the runSimBatchAggregator.m file for more 
information.

## Demo

At the MATLAB prompt:

    runBuildConnectivity
    runBuildStimulation
    runSimulation('indret=0,time=0:5:10,conn=Conn256N1200.mat,stim=Ret256Noise1.0Ori160_x9R1.mat,idx=1,att=0_2,tag=SmallExample')

to run the example simulation. See help runSimulation for details on the arguments.
For the small example on a 9th Gen Intel Core i5 desktop PC, 
runBuildConnectivity takes 18 s, runBuildStimulation takes 52 s, and 
runSimulation takes 18 s, plus 40 s for saving the data. runBuildConnectivity 
is set for only a small example run. To run a larger example,
set boolUseSmallExample = false in line 14 of runBuildConnectivity. 

## Author

These functions were written by Jorrit Montijn in Alexandre Pouget's lab in 
Geneva, over the course of 2016-2018.


