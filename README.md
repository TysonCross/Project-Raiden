# Project-Raiden

<p align="center">
The University of The Witwatersrand 
</p>
<p align="center">
Group05: ELEN4012 Lab Project on high-speed video footage lightning detection
</p>
<p align="center">
By: Tyson Cross and Jason Smit 
</p>
<p align="center">
Under the supervision of Dr Hugh Hunt  
</p>

## Legal notice

All work presented here is the intellectual property of The University of The Witwatersrand, South Africa,
unless otherwise stipulated in the work or the section below (*External licences*).
A copy of the Intellectual Property Policy can be found on the university
[website](https://libguides.wits.ac.za/ld.php?content_id=18737801).

#### External licences
The project makes use of external packages. These packages carry their own licences which are linked here or within
the code that makes use of it. The code makes use of progressbar.m  which is covered by the licence found
under [./matlab/Licences/progressbar.lic](./matlab/Licences/progressbar.lic). This code is used to present a
visual representation of the progress during resizing of images as well as the overall progress when using the application.

cprintf.m is covered by the licence found under [./matlab/Licences/cprintf.lic](./matlab/Licences/progressbar.lic).
This code is used to improve the readability of the output produced when training a network.

## Overview
This repository is the working repository for our fourth year Information Engineering lab .
A brief overview of the folders contents is presented below under their respective headings.
 
## Admin
This folder contains the planning, shared graphics, reports that have been submitted, research and spreadsheets that have
been used by the group.

## Logs
This folders presents the logs of individual sessions of training, where the filename specifies the network and the date 
that training was performed on the network.

## Matlab
Contains all the Matlab scripts created, where each script describes its function in the header of the script. The main training 
is the _CNN_Segmentation_Train_and_Evaluate.m_ script found at the root of the Matlab folder.  Further scripts and applications
can be found under the folders within the Matlab folder.

## Nuke
Contains the Nuke scripts used in in creating the masks for the exported sequences.

## Resolve
Contains the projects with the timelines for the clips that have been exported

## Tools, experiments, config
These folders are no longer used, but were candidate folders for use in a project that was based on python and tensor flow.
