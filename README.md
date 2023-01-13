# 3D RECONSTRUCTION USING SINGLE CAMERA AND MIRROR SETUP
## Camera calibration example - Corner extraction-calibration-additional tools 

[![N|Solid](https://cldup.com/dTxpPi9lDf.thumb.png)](https://nodesource.com/products/nsolid)

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)
 This is a release of a Camera Calibration Toolbox for Matlab® with a complete documentation. This document may also be used as a tutorial on camera calibration since it includes general information about calibration, references and related links.
Please report bugs/questions/suggestions to Jean-Yves Bouguet at jean-yves.bouguet@intel.com.

The C implementation of this toolbox is included in the Open Source Computer Vision library distributed by Intel and freely available online.

**Content**

- System requirements
- Getting started
- Calibration examples
- Description of the calibration parameters
- Description of the functions in the calibration toolbox
- Doing your own calibration
- Undocumented features of the toolbox
- References
- A few links related to camera calibration

**System requirements**
  This toolbox works on Matlab 5.x and Matlab 6.x (up to Matlab 6.5) on Windows, Unix and Linux systems (platforms it has been fully tested) and does not require any specific Matlab toolbox (for example, the optimization toolbox is not required). The toolbox should also work on any other platform supporting Matlab 5.x and 6.x.


**Getting started**

- Go to the download page, and retrieve the latest version of the complete camera calibration toolbox for Matlab.
- Store the individual matlab files (.m files) into a unique folder TOOLBOX_calib (default folder name).
- Run Matlab and add the location of the folder TOOLBOX_calib to the main matlab path. This procedure will let you call any of the matlab toolbox functions from anywhere. Under Windows, this may be easily done by using the path editing menu. Under Unix or Linux, you may use the command path or addpath (use the help command for function description).
- Run the main matlab calibration function calib_gui (or calib).
- A mode selection window appears on the screen:


This selection window lets you choose between two modes of operation of the toolbox: standard or memory efficient. In standard mode, all the images used for calibration are loaded into memory once and never read again from disk. This minimizes the overall number of disk access, and speeds up all image processing and image display functions. However, if the images are large, or there are a lot of them, then the OUT OF MEMORY error message may be encountered. If this is the case, the new memory efficient version of the toolbox may be used. In this mode, every image is loaded one by one and never stored permanently in memory.
![image](https://user-images.githubusercontent.com/65610334/211983174-64161d3e-ad95-41e0-b7f5-759fc5859001.png)

If you choose to run the standard version of the toolbox now, you can always switch to the other memory efficient mode later in case the OUT OF MEMORY error message is encountered. The two modes of operation are totally compatible (for input and output) and interchangeable.

Since both modes have the exact same user interface, in the context of this documentation, let us select the standard mode by clicking on the top button of the window. The main calibration toolbox window appears on the screen (replacing the mode selection window):

![image](https://user-images.githubusercontent.com/65610334/212239726-dc0b18db-3d44-41d3-8bcd-25f7dd49af58.png)

Note that the mode selection step can be bypassed altogether by directly running calib_gui(0) for the normal mode or calib_gui(1) for the memory efficient mode (try help calib_gui for more information).

- You are now ready to use the toolbox for calibration.
- 
**Calibration example**

- First calibration example - Corner extraction, calibration, additional tools
    This section takes you through a complete calibration example based on a total of 20 (and 25) images of a planar checkerboard. This example lets you learn how to use all the features of the toolbox: loading calibration images, extracting image corners, running the main calibration engine, displaying the results, controlling accuracies, adding and suppressing images, undistorting images, exporting calibration data to different formats... This example is highly recommended for someone who is just starting using the toolbox. 

**First calibration example - Corner extraction, calibration, additional tools**
This section takes you through a complete calibration example based on a total of 20 (and 25) images of a planar checkerboard placed in the mirror setup.

This example lets you learn how to use all the features of the toolbox: loading calibration images, extracting image corners, running the main calibration engine, displaying the results, controlling accuracies, adding and suppressing images, undistorting images, exporting calibration data to different formats... This example is highly recommended for someone who is just starting using the toolbox.

 - Download the calibration images all at once from Dataset folder or one by one, and store the 20 images into a seperate folder named calib_example. 
 ![Images](https://user-images.githubusercontent.com/65610334/212243538-0619adad-a8d8-41ab-a801-c1aee23537e4.png)

- From within matlab, go to the example folder calib_example containing the images. 
- From within matlab, go to the example folder calib_example containing the images. 
Click on the Image names button in the Camera calibration tool window. Enter the basename of the calibration images (Image) and the image format (tif).All the images (the 20 of them) are then loaded in memory (through the command Read images that is automatically executed) in the variables I_1, I_2 ,..., I_20.The number of images is stored in the variable n_ima (=20 here).

![Calibration Images](https://user-images.githubusercontent.com/65610334/212247154-20bdaa4c-e473-4a52-afed-8535061711e3.png)
- Extract the grid corners:
Click on the Extract grid corners button in the Camera calibration tool window.
Extraction of the grid corners on the images
Number(s) of image(s) to process ([] = all images) = 

  **Press "enter" (with an empty argument) to select all the images (otherwise, you would enter a list of image indices like [2 5 8 10 12] to extract corners of a subset of images).**

  Then, select the default window size of the corner finder: wintx=winty=5 by pressing "enter" with empty arguments to the wintx and winty question. 
This leads to a effective window of size 11x11 pixels.
    **Extraction of the grid corners on the images
    Number(s) of image(s) to process ([] = all images) = 
    Window size for corner finder (wintx and winty):
    wintx ([] = 26) = 13
    winty ([] = 26) = 13
    Window size = 27x27**
Do you want to use the automatic square counting mechanism (0=[]=default)
  or do you always want to enter the number of squares manually (1,other)?


The corner extraction engine includes an automatic mechanism for counting the number of squares in the grid. This tool is specially convenient when working with a large number of images since the user does not have to manually enter the number of squares in both x and y directions of the pattern. On some very rare occasions however, this code may not predict the right number of squares. This would typically happen when calibrating lenses with extreme distortions. At this point in the corner extraction procedure, the program gives the option to the user to disable the automatic square counting code. In that special mode, the user would be prompted for the square count for every image. In this present example, it is perfectly appropriate to keep working in the default mode (i.e. with automatic square counting activated), and therefore, simply press "enter" with an empty argument. (NOTE: it is generally recommended to first use the corner extraction code in this default mode, and then, if need be, re-process the few images with "problems")

**Processing image 1...
Using (wintx,winty)=(13,13) - Window size = 27x27      (Note: To reset the window size, run script clearwin)
Click on the four extreme corners of the rectangular complete pattern (the first clicked corner is the origin)...**

![Calib1](https://user-images.githubusercontent.com/65610334/212251855-ccf59d9a-ce84-41ec-8a53-35a0da8d8b96.jpg)

Ordering rule for clicking: The first clicked point is selected to be associated to the origin point of the reference frame attached to the grid. The other three points of the rectangular grid can be clicked in any order. This first-click rule is especially important if you need to calibrate externally multiple cameras (i.e. compute the relative positions of several cameras in space)

