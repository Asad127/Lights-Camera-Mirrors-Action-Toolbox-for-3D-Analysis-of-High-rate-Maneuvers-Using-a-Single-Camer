# **3D RECONSTRUCTION USING SINGLE CAMERA AND MIRROR SETUP**
## **Camera calibration  - Corner extraction-calibration-additional tools** 
# **System requirements**
  This toolbox works on Matlab 5.x and Matlab 6.x (up to Matlab 6.5) on Windows, Unix and Linux systems (platforms it has been fully tested) and does not require any specific Matlab toolbox (for example, the optimization toolbox is not required). The toolbox should also work on any other platform supporting Matlab 5.x and 6.x.


# **Getting started**
If you are new to the camera calibration toolbox. Go to the following website http://robots.stanford.edu/cs223b04/JeanYvesCalib/ and try the first few examples to get to know about camera calibration.This  is highly recommended for someone who is just starting using the toolbox. 

# Calibration Dataset Collection
The following section explains the camera calibration dataset in details. Setup for calibration and multi-view capturing of object is shown in the follwowing figure.


  ![123](https://user-images.githubusercontent.com/65610334/212621713-6e8b4379-a18b-4971-83ee-c91948d93592.jpeg)

- **Print a checker pattern and note the size of the square on the checker pattern.**
-**Place your camera on the camera stand and place it at a certain distance from the mirror setup/container.**
- **Now, we need to define a region where we can move our checker pattern.**
- **Place your checker pattern in the region define and capture the image of the checker pattern.**
- **Make sure that the checker pattern can be seen in all views i-e original, mirror, and the other mirrored view. (Note: Camera stand and mirror setup should not move)**
- **Change the position of the checker pattern in the calibrated region and capture an image in which the checker pattern can be seen in all views.**
- **Repeat the above steps to capture at least 15-20 images of the checker pattern at different positions in the region defined.**

# **Calibrating Original view**

**Calibration original view - Corner extraction, calibration, additional tools**

This section explains how to use all the features of the toolbox: loading calibration images, extracting image corners, running the main calibration engine, displaying the results, controlling accuracies, adding and suppressing images, undistorting images, exporting calibration data to different formats...
## **Steps**
 - Download the calibration images all at once from the following link https://github.com/Asad127/3D-RECONSTRUCTION/tree/main/Dataset or one by one, and store all the images into a seperate folder named calib_data.
 ![Images](https://user-images.githubusercontent.com/65610334/212243538-0619adad-a8d8-41ab-a801-c1aee23537e4.png)

- From within matlab, go to the example folder calib_data containing the images. 
- From within matlab, go to the example folder calib_data containing the images. 
Click on the Image names button in the Camera calibration tool window. Enter the basename of the calibration images (Image) and the image format (tif).All the images (the 20 of them) are then loaded in memory (through the command Read images that is automatically executed) in the variables I_1, I_2 ,..., I_20.The number of images is stored in the variable n_ima (=20 here).

![Calibration Images](https://user-images.githubusercontent.com/65610334/212247154-20bdaa4c-e473-4a52-afed-8535061711e3.png)
- **Extract the grid corners:**
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

**Ordering rule for clicking**: 
The first clicked point is selected to be associated to the origin point of the reference frame attached to the grid. The other three points of the rectangular grid can be clicked in any order. This first-click rule is especially important if you need to calibrate externally multiple cameras (i.e. compute the relative positions of several cameras in space)

![Corners](https://user-images.githubusercontent.com/65610334/212264385-240dc658-19eb-4212-bf70-1002ec21c2cd.jpg)
The boundary of the calibration grid is then shown below: 
![bd](https://user-images.githubusercontent.com/65610334/212264520-26a30d6e-2eff-41bc-867e-8f561fecaf16.jpg)

Enter the sizes dX and dY in X and Y of each square in the grid (in this case, dX=dY=13mm=default values): 
**Processing image 1...**
Using (wintx,winty)=(13,13) - Window size = 27x27      (Note: To reset the window size, run script clearwin)
Click on the four extreme corners of the rectangular complete pattern (the first clicked corner is the origin)...
Size dX of each square along the X direction ([]=30mm) = 13
Size dY of each square along the Y direction ([]=30mm) = 13
![corners11](https://user-images.githubusercontent.com/65610334/212265637-e70c9ba5-b7da-4542-bac6-321273b4a3c2.jpg)
If the guessed grid corners (red crosses on the image) are not close to the actual corners,
it is necessary to enter an initial guess for the radial distortion factor kc (useful for subpixel detection)
Need of an initial guess for distortion? ([]=no, other=yes) 
**Corner extraction...**
![extraxted corners](https://user-images.githubusercontent.com/65610334/212265827-fec020ae-8599-48cf-b542-401dc5c90dc8.jpg)

**Follow the same procedure for the rest of images in the dataset.**

After corner extraction, the matlab data file calib_data.mat is automatically generated. This file contains all the information gathered throughout the corner extraction stage (image coordinates, corresponding 3D grid coordinates, grid sizes, ...). This file is only created in case of emergency when for example matlab is abruptly terminated before saving. Loading this file would prevent you from having to click again on the images.

**Main Calibration step**

After corner extraction, click on the button Calibration of the Camera calibration tool to run the main camera calibration procedure.
Calibration is done in two steps: first initialization, and then nonlinear optimization.
The initialization step computes a closed-form solution for the calibration parameters based not including any lens distortion (program name: init_calib_param.m).
The non-linear optimization step minimizes the total reprojection error (in the least squares sense) over all the calibration parameters (9 DOF for intrinsic: focal, principal point, distortion coefficients, and 6*20 DOF extrinsic => 129 parameters). For a complete description of the calibration parameters, click on that link. The optimization is done by iterative gradient descent with an explicit (closed-form) computation of the Jacobian matrix (program name: go_calib_optim.m).

Aspect ratio optimized (est_aspect_ratio = 1) -> both components of fc are estimated (DEFAULT).
Principal point optimized (center_optim=1) - (DEFAULT). To reject principal point, set center_optim=0
Skew not optimized (est_alpha=0) - (DEFAULT)
Distortion not fully estimated (defined by the variable est_dist):
     Sixth order distortion not estimated (est_dist(5)=0) - (DEFAULT) .
Initialization of the principal point at the center of the image.
Initialization of the intrinsic parameters using the vanishing points of planar patterns.

**Initialization of the intrinsic parameters - Number of images: 12**

**Calibration parameters after initialization:**

- Focal Length:          fc = [ 1529.18846   1529.18846 ]
Principal point:       cc = [ 1631.50000   734.50000 ]
Skew:             alpha_c = [ 0.00000 ]   => angle of pixel = 90.00000 degrees
Distortion:            kc = [ 0.00000   0.00000   0.00000   0.00000   0.00000 ]

**Main calibration optimization procedure - Number of images: 12**
Gradient descent iterations: 1...2...3...4...5...6...7...8...9...10...done
Estimation of uncertainties...done

**Calibration results after optimization (with uncertainties):**

- Focal Length:          fc = [ 1507.97898   1496.24779 ] ± [ 26.82888   26.88096 ]
Principal point:       cc = [ 1536.92900   695.75342 ] ± [ 38.21710   42.19543 ]
Skew:             alpha_c = [ 0.00000 ] ± [ 0.00000  ]   => angle of pixel axes = 90.00000 ± 0.00000 degrees
Distortion:            kc = [ -0.12315   0.13155   0.00248   -0.01555  0.00000 ] ± [ 0.05752   0.11221   0.00904   0.00697  0.00000 ]
Pixel error:          err = [ 0.23942   0.24756 ]

**Note: The numerical errors are approximately three times the standard deviations (for reference).**

The Calibration parameters are stored in a number of variables. For a complete description of them, visit this page. Notice that the skew coefficient alpha_c and the 6th order radial distortion coefficient (the last entry of kc) have not been estimated (this is the default mode). Therefore, the angle between the x and y pixel axes is 90 degrees. In most practical situations, this is a very good assumption. However, later on, a way of introducing the skew coefficient alpha_c in the optimization will be presented.

Observe that only 10 gradient descent iterations are required in order to reach the minimum. This means only 10 evaluations of the reprojection function + Jacobian computation and inversion. The reason for that fast convergence is the quality of the initial guess for the parameters computed by the initialization procedure.
For now, ignore the recommendation of the system to reduce the distortion model. The reprojection error is still too large to make a judgement on the complexity of the model. This is mainly because some of the grid corners were not very precisely extracted for a number of images.

Click on Reproject on images in the Camera calibration tool to show the reprojections of the grids onto the original images. These projections are computed based on the current intrinsic and extrinsic parameters. Input an empty string (just press "enter") to the question Number(s) of image(s) to show ([] = all images) to indicate that you want to show all the images:
Number(s) of image(s) to show ([] = all images) = 


The following figures shows the first four images with the detected corners (red crosses) and the reprojected grid corners (circles). 


![Asad](https://user-images.githubusercontent.com/65610334/212270143-6e7e929a-3dee-4e6a-903a-d3b5ce15f6cf.jpg)

Number(s) of image(s) to show ([] = all images) = 
Pixel error:      err = [0.23942   0.24756] (all active images)

The reprojection error is also shown in the form of color-coded crosses: 

![error11](https://user-images.githubusercontent.com/65610334/212270799-077fa4b1-0888-40b4-b471-e7cf41e0760e.jpg)
In order to exit the error analysis tool, right-click on anywhere on the figure (you will understand later the use of this option).
Click on Show Extrinsic in the Camera calibration tool. 
he extrinsic parameters (relative positions of the grids with respect to the camera) are then shown in a form of a 3D plot: 

![extrrr](https://user-images.githubusercontent.com/65610334/212271252-c6ea1ed7-6e7b-4539-b9c6-5a6faf816d34.jpg)

On this figure, the frame (Oc,Xc,Yc,Zc) is the camera reference frame. The red pyramid corresponds to the effective field of view of the camera defined by the image plane. To switch from a "camera-centered" view to a "world-centered" view, just click on the Switch to world-centered view button located at the bottom-left corner of the figure.

![ww](https://user-images.githubusercontent.com/65610334/212271620-ba55ff88-e193-4bd2-9fcd-66547ce13fa1.jpg)

****************************************************************************************************************************************************************************************************************************************************************************************
****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************

## **Calibrating Mirror View**

**Calibrating using mirror view - Corner extraction, calibration, additional tools**

This section explains how to use all the features of the toolbox: loading calibration images, extracting image corners, running the main calibration engine, displaying the results, controlling accuracies, adding and suppressing images, undistorting images, exporting calibration data to different formats...
## **Steps**
 - Download the calibration images all at once from Dataset folder or one by one, and store the 20 images into a seperate folder named calib_example. 
 ![Images](https://user-images.githubusercontent.com/65610334/212243538-0619adad-a8d8-41ab-a801-c1aee23537e4.png)

- From within matlab, go to the example folder calib_data containing the images. 
- From within matlab, go to the example folder calib_data containing the images. 
Click on the Image names button in the Camera calibration tool window. Enter the basename of the calibration images (Image) and the image format (tif).All the images (the 20 of them) are then loaded in memory (through the command Read images that is automatically executed) in the variables I_1, I_2 ,..., I_20.The number of images is stored in the variable n_ima (=20 here).

![Calibration Images](https://user-images.githubusercontent.com/65610334/212247154-20bdaa4c-e473-4a52-afed-8535061711e3.png)
- **Extract the grid corners:**
Click on the Extract grid corners button in the Camera calibration tool window.
Extraction of the grid corners on the images
Number(s) of image(s) to process ([] = all images) = **press enter**

  **Press "enter" (with an empty argument) to select all the images (otherwise, you would enter a list of image indices like [2 5 8 10 12] to extract corners of a subset of images).**

  Then, select the default window size of the corner finder: wintx=winty=5 by pressing "enter" with empty arguments to the wintx and winty question. 
This leads to a effective window of size 11x11 pixels.
    **Extraction of the grid corners on the images
    Number(s) of image(s) to process ([] = all images) =  **press enter**
    Window size for corner finder (wintx and winty):
    wintx ([] = 26) = 13
    winty ([] = 26) = 13
    Window size = 27x27**
Do you want to use the automatic square counting mechanism (0=[]=default)
  or do you always want to enter the number of squares manually (1,other)? **press enter**

The corner extraction engine includes an automatic mechanism for counting the number of squares in the grid. This tool is specially convenient when working with a large number of images since the user does not have to manually enter the number of squares in both x and y directions of the pattern.

**Processing image 1...
Using (wintx,winty)=(13,13) - Window size = 27x27      (Note: To reset the window size, run script clearwin)
Click on the four extreme corners of the rectangular complete pattern (the first clicked corner is the origin)...**

![Calib1](https://user-images.githubusercontent.com/65610334/212251855-ccf59d9a-ce84-41ec-8a53-35a0da8d8b96.jpg)
***************************************************************************************************************************************************************************************************************************************************************************************
*******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
## Note 
**The clicking ordering rule in the mirror will be the reflected order compared to the original view.**
***************************************************************************************************************************************************************************************************************************************************************************************
*******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************

**Ordering rule for clicking:** 

The first clicked point is selected to be associated to the origin point of the reference frame attached to the grid. The other three points of the rectangular grid can be clicked in any order. This first-click rule is especially important if you need to calibrate externally multiple cameras (i.e. compute the relative positions of several cameras in space)

![asddd](https://user-images.githubusercontent.com/65610334/212284205-98c2ad36-cfc8-4c32-bb10-5470510179c5.jpg)
The boundary of the calibration grid is then shown below: 
![BBIMAGES](https://user-images.githubusercontent.com/65610334/212285450-3e0ecadc-eb91-4ae3-a029-32efa048535f.jpg)

Enter the sizes dX and dY in X and Y of each square in the grid (in this case, dX=dY=13mm=default values): 
**Processing image 1...**
Using (wintx,winty)=(13,13) - Window size = 27x27      (Note: To reset the window size, run script clearwin)
Click on the four extreme corners of the rectangular complete pattern (the first clicked corner is the origin)...
Size dX of each square along the X direction ([]=30mm) = 13
Size dY of each square along the Y direction ([]=30mm) = 13
![casaasaa](https://user-images.githubusercontent.com/65610334/212286733-16bbf630-b0c9-4b64-ad22-22fe9e80503e.jpg)
If the guessed grid corners (red crosses on the image) are not close to the actual corners,
it is necessary to enter an initial guess for the radial distortion factor kc (useful for subpixel detection)
Need of an initial guess for distortion? ([]=no, other=yes) 
Corner extraction...

![extracted acdcc](https://user-images.githubusercontent.com/65610334/212286285-18da988a-4855-4b63-885e-e1035fa1f071.jpg)

**Follow the same procedure for the rest of images in the dataset.**

After corner extraction, the matlab data file calib_data.mat is automatically generated. This file contains all the information gathered throughout the corner extraction stage (image coordinates, corresponding 3D grid coordinates, grid sizes, ...). This file is only created in case of emergency when for example matlab is abruptly terminated before saving. Loading this file would prevent you from having to click again on the images.

**Main Calibration step**

After corner extraction, click on the button Calibration of the Camera calibration tool to run the main camera calibration procedure.
Calibration is done in two steps: first initialization, and then nonlinear optimization.
The initialization step computes a closed-form solution for the calibration parameters based not including any lens distortion (program name: init_calib_param.m).
The non-linear optimization step minimizes the total reprojection error (in the least squares sense) over all the calibration parameters (9 DOF for intrinsic: focal, principal point, distortion coefficients, and 6*20 DOF extrinsic => 129 parameters). For a complete description of the calibration parameters, click on that link. The optimization is done by iterative gradient descent with an explicit (closed-form) computation of the Jacobian matrix (program name: go_calib_optim.m).

Aspect ratio optimized (est_aspect_ratio = 1) -> both components of fc are estimated (DEFAULT).
Principal point optimized (center_optim=1) - (DEFAULT). To reject principal point, set center_optim=0
Skew not optimized (est_alpha=0) - (DEFAULT)
Distortion not fully estimated (defined by the variable est_dist):
     Sixth order distortion not estimated (est_dist(5)=0) - (DEFAULT) .
Initialization of the principal point at the center of the image.
Initialization of the intrinsic parameters using the vanishing points of planar patterns.

**Initialization of the intrinsic parameters - Number of images: 12**

**Calibration parameters after initialization:**

- Focal Length:          fc = [ 1439.23693   1439.23693 ]
- Principal point:       cc = [ 1631.50000   734.50000 ]
- Skew:             alpha_c = [ 0.00000 ]   => angle of pixel = 90.00000 degrees
- Distortion:            kc = [ 0.00000   0.00000   0.00000   0.00000   0.00000 ]

Main calibration optimization procedure - Number of images: 12
Gradient descent iterations: 1...2...3...4...5...6...7...8...9...10...11...12...13...done
Estimation of uncertainties...done


**Calibration results after optimization (with uncertainties):**

- Focal Length:          fc = [ 1450.42395   1449.67211 ] ± [ 44.81565   36.31254 ]
- Principal point:       cc = [ 1570.68503   759.76341 ] ± [ 52.54308   54.49669 ]
- Skew:             alpha_c = [ 0.00000 ] ± [ 0.00000  ]   => angle of pixel axes = 90.00000 ± 0.00000 degrees
- Distortion:            kc = [ -0.24718   0.51654   0.01726   -0.01352  0.00000 ] ± [ 0.12459   0.34828   0.00662   0.01536  0.00000 ]
- Pixel error:          err = [ 0.29234   0.26648 ]

**Note: The numerical errors are approximately three times the standard deviations (for reference).**

The Calibration parameters are stored in a number of variables. For a complete description of them, visit this page. Notice that the skew coefficient alpha_c and the 6th order radial distortion coefficient (the last entry of kc) have not been estimated (this is the default mode). Therefore, the angle between the x and y pixel axes is 90 degrees. In most practical situations, this is a very good assumption. However, later on, a way of introducing the skew coefficient alpha_c in the optimization will be presented.

Observe that only 13 gradient descent iterations are required in order to reach the minimum. This means only 13 evaluations of the reprojection function + Jacobian computation and inversion. The reason for that fast convergence is the quality of the initial guess for the parameters computed by the initialization procedure.
For now, ignore the recommendation of the system to reduce the distortion model. The reprojection error is still too large to make a judgement on the complexity of the model. This is mainly because some of the grid corners were not very precisely extracted for a number of images.

Click on Reproject on images in the Camera calibration tool to show the reprojections of the grids onto the original images. These projections are computed based on the current intrinsic and extrinsic parameters. Input an empty string (just press "enter") to the question Number(s) of image(s) to show ([] = all images) to indicate that you want to show all the images:
Number(s) of image(s) to show ([] = all images) = 


The following figures shows the first four images with the detected corners (red crosses) and the reprojected grid corners (circles). 



![Unadsm](https://user-images.githubusercontent.com/65610334/212606564-7dcd28b3-393d-4c4e-9730-6ce153e7e08f.jpg)


**Number(s) of image(s) to show ([] = all images) = 
Pixel error:      err = [0.23616   0.25538] (all active images)**

The **reprojection error** is also shown in the form of **color-coded crosses:** 

![r5](https://user-images.githubusercontent.com/65610334/212606286-b63e08bc-d689-41c8-81f0-7d249d653b8b.jpg)
In order to exit the error analysis tool, right-click on anywhere on the figure (you will understand later the use of this option).

Click on **Show Extrinsic in the Camera calibration tool**. 

The extrinsic parameters (relative positions of the grids with respect to the camera) are then shown in a form of a 3D plot: 

![3d](https://user-images.githubusercontent.com/65610334/212606407-4e0ecebd-f88a-4601-be5e-90e711b6797d.jpg)

On this figure, the frame (Oc,Xc,Yc,Zc) is the camera reference frame. The red pyramid corresponds to the effective field of view of the camera defined by the image plane. To switch from a "camera-centered" view to a "world-centered" view, just click on the Switch to world-centered view button located at the bottom-left corner of the figure.

![3d2](https://user-images.githubusercontent.com/65610334/212606469-06ea4d63-1fd7-4d36-91d9-511b0091f3a8.jpg)

## **Camera Matrix**

- Once you do the camera calibration for the original view, extract the focal length, principal point, rotation, and translation vector and save it into a mat file.
- Repeat the above step for the mirror view.
- Now merge both files to a single file containing your camera matrix for original and mirror view.
- The mergerd file should look like this https://github.com/Asad127/3D-RECONSTRUCTION/blob/main/Code/merged_params.mat.

## **3D Reconstruction of different objects**

## **Points selection**
-Place the object in the calibrated region you want to reconstruct it. Make sure that the should be seen perfectly in the calibrated mirrors.


![Image2](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)
- Run the point_marker.mat file and select the points in the original view you want to reconstruct it.
- Repeat the same procedure and select the corresponding points in the mirror view.(Note: The corresponding points in the mirror will be the reflected points compared to the original points)

![ddd Diagram](https://user-images.githubusercontent.com/65610334/212617135-aa878f26-fa2d-4e7f-841a-9f663eefbc5b.jpg)

## **3D Reconstruction**
- Now you have the marked corresponding **2d** points for the object you want to reconstruct it.
- Load the **merged parameter file** which contains the camera matrix for the original and mirror view.
- Run the following file https://github.com/Asad127/3D-RECONSTRUCTION/blob/main/Code/3reconstruction.m to reconstruct different objects.
- The ouput of the above code is as follows:
![R4](https://user-images.githubusercontent.com/65610334/212618909-913d524c-792e-44d0-b6eb-37a7c7d00d78.jpg)

- The illustration 3d world points  is shown below:
              ![untitl211221ed](https://user-images.githubusercontent.com/65610334/212619094-96753fd8-5b20-4c7d-8798-07dada5a0c29.jpg)

- While the error histogram between the 2d original points and 2d estimated points is as follows:

 ![R4_Hist](https://user-images.githubusercontent.com/65610334/212619373-74e057af-ee18-4eb2-b671-9f77acc565dc.jpg)

## **Note**
**We have provided the marked 2d points of different objects for 3d reconstruction in the marked points folder. You can use them to reconstruct different objects.**
## License
**ROMI LAB
SEECS-NUST-PAKISTAN**



  
