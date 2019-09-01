# Project-Raiden

<p align="center">
The University of The Witwatersrand 
</p>
<p align="center">
Group05: ELEN4012 Lab Project: Semantic segmentation of high speed lightning footage using machine learning
</p>
<p align="center">
Tyson Cross and Jason Smit 
</p>
<p align="center">
Supervisor:  Dr Hugh Hunt  
</p>

## Legal notice

All work presented here is the intellectual property of The University of The Witwatersrand, South Africa,
unless otherwise stipulated in the work or the section below (*External licences*).
A copy of the Intellectual Property Policy can be found on the university
[website](https://libguides.wits.ac.za/ld.php?content_id=18737801).

#### External functions and licences
The project makes use of external packages, which are not distributed with this software, but must be independently
downloaded and installed. These packages carry their own licences which are linked here or within
the code that makes use of it. 

progressbar.m (by Steve Hoelzer) is covered by the licence foundbunder [./Licences/progressbar.lic](./Licences/progressbar.lic)
This code is used to present a visual representation of the progress during resizing of images while using the application. The file can be dowloaded from [https://www.mathworks.com/matlabcentral/fileexchange/6922-progressbar](https://www.mathworks.com/matlabcentral/fileexchange/6922-progressbar)

cprintf.m (by Yair Altman) is covered by the licence found under [./Licences/cprintf.lic](./Licences/progressbar.lic).
This code is used to improve the readability of the output produced when training a network. The file can be downloaded from [https://www.mathworks.com/matlabcentral/fileexchange/24093-cprintf-display-formatted-colored-text-in-the-command-window](https://www.mathworks.com/matlabcentral/fileexchange/24093-cprintf-display-formatted-colored-text-in-the-command-window)

dirwalk.m (by Evgeny Pr) is covered by the licence found under [./Licences/dirwalk.lic](./Licences/dirwalk.lic). This code is used to get a list of files on disk beneath a specified directory. The file can be downladed from: [https://www.mathworks.com/matlabcentral/fileexchange/32036-dirwalk-walk-the-directory-tree](https://www.mathworks.com/matlabcentral/fileexchange/32036-dirwalk-walk-the-directory-tree)

export_fig.m (by  Oliver J. Woodford and Yair Altman) is covered by the licence found under [./Licences/export_fig.lic](./Licences/export_fig.lic). This code enables the exporting of figures from matlab with LaTeX fonts (not included).
The file can be downloaded from [https://www.mathworks.com/matlabcentral/fileexchange/23629-export_fig](https://www.mathworks.com/matlabcentral/fileexchange/23629-export_fig)

## Overview
This repository is the working repository for our fourth year Information Engineering lab .
A brief overview of the folders contents is presented below under their respective headings.
 
## Admin
This folder contains the planning, research and spreadsheets that have
been used by the group, along with progress reports and meeting minutes.

## config
This folder contains the Conda environment and python env list of the libraries and tools used in the project environment

## matlab
Contains all the Matlab scripts created, where each script describes its function in the header of the script. The main training and evaluation script is the _trainSegmentNetwork.m_ script found at the root of the _matlab_ folder.  Further scripts and applications
can be found under the _utilities_ folder within the _matlab_ folder.

## nuke
Contains the Nuke scripts used in creating the masks for the exported sequences.

## resolve
Contains the projects with the timelines for the clips that have been exported from the high-speed CINE format videos.
