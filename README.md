## **$\color{Red{\textrm{3D RECONSTRUCTION USING SINGLE CAMERA AND MIRROR SETUP.}}$**
***
***

## $\textcolor{yellow}{This\ is\ a\ Big\ Title}$

## **Camera calibration  - Corner extraction-calibration-additional tools** 
***
***

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


-----------------------------------------------------------![W1](https://user-images.githubusercontent.com/65610334/212662591-9ce4ac12-9114-4fb6-8b8c-e9792c70e7bb.png)

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


The corner extraction engine includes an automatic mechanism for counting the number of squares in the grid. 

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


 ----------------------------------------------------------- ![WRR](https://user-images.githubusercontent.com/65610334/212663304-28278a91-0cbf-4638-91e2-a679576e44ff.png)

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
- Principal point:       cc = [ 1631.50000   734.50000 ]
- Skew:             alpha_c = [ 0.00000 ]   => angle of pixel = 90.00000 degrees
- Distortion:            kc = [ 0.00000   0.00000   0.00000   0.00000   0.00000 ]

**Main calibration optimization procedure - Number of images: 12**
Gradient descent iterations: 1...2...3...4...5...6...7...8...9...10...done
Estimation of uncertainties...done

**Calibration results after optimization (with uncertainties):**

- Focal Length:          fc = [ 1507.97898   1496.24779 ] ± [ 26.82888   26.88096 ]
- Principal point:       cc = [ 1536.92900   695.75342 ] ± [ 38.21710   42.19543 ]
- Skew:             alpha_c = [ 0.00000 ] ± [ 0.00000  ]   => angle of pixel axes = 90.00000 ± 0.00000 degrees
- Distortion:            kc = [ -0.12315   0.13155   0.00248   -0.01555  0.00000 ] ± [ 0.05752   0.11221   0.00904   0.00697  0.00000 ]
- Pixel error:          err = [ 0.23942   0.24756 ]

**Note: The numerical errors are approximately three times the standard deviations (for reference).**

The Calibration parameters are stored in a number of variables. 

Click on Reproject on images in the Camera calibration tool to show the reprojections of the grids onto the original images. These projections are computed based on the current intrinsic and extrinsic parameters. Input an empty string (just press "enter") to the question

 ----------------------------------------------------------- ![W3](https://user-images.githubusercontent.com/65610334/212663501-41912859-477e-4ced-8a0d-e7fd0082a60d.png)
  
Number(s) of image(s) to show ([] = all images) to indicate that you want to show all the images:
Number(s) of image(s) to show ([] = all images) = 


The **following figures** shows the  **four images** with the detected corners (red crosses) and the reprojected grid corners (circles). 


![Asad](https://user-images.githubusercontent.com/65610334/212270143-6e7e929a-3dee-4e6a-903a-d3b5ce15f6cf.jpg)

**Number(s) of image(s) to show ([] = all images) = 
Pixel error:      err = [0.23942   0.24756] (all active images)**

The reprojection error is also shown in the form of **color-coded crosses:** 

![error11](https://user-images.githubusercontent.com/65610334/212270799-077fa4b1-0888-40b4-b471-e7cf41e0760e.jpg)
In order to exit the error analysis tool, right-click on anywhere on the figure (you will understand later the use of this option).
Click on Show Extrinsic in the Camera calibration tool. 

-----------------------------------------------------------![W2](https://user-images.githubusercontent.com/65610334/212663777-fa2082bb-9bd2-4e5c-8ff5-215286a4739c.png)

The extrinsic parameters (relative positions of the grids with respect to the camera) are then shown in a form of a 3D plot: 

![extrrr](https://user-images.githubusercontent.com/65610334/212271252-c6ea1ed7-6e7b-4539-b9c6-5a6faf816d34.jpg)

On this figure, the frame (Oc,Xc,Yc,Zc) is the camera reference frame. The red pyramid corresponds to the effective field of view of the camera defined by the image plane. To switch from a "camera-centered" view to a "world-centered" view, just click on the Switch to world-centered view button located at the bottom-left corner of the figure.

![ww](https://user-images.githubusercontent.com/65610334/212271620-ba55ff88-e193-4bd2-9fcd-66547ce13fa1.jpg)

## **Camera matrix for original view**

- The calibration process outputs the camera pose (rotation R and translation T) for each image in the calibration set. 
- Throughout calibration, the camera remains fixed in place and only the checker is moved.
- In order to test for reconstruction, when taking images, we additionally capture an image of the checker in a flat position to serve as our reference for the camera pose. 
- This image may be kept in the original-view calibration set for pose extraction, or we can estimate its pose separately using the Comp. Extrinsic function of the toolbox post-calibration.
- Then, without moving the camera, we remove the checker and introduce the object for reconstruction, and capture its images in various positions. We then use the R and T from the reference image with the checker to serve as the pose for this set of test images as well.
- Once the camera calibration is completed for the original view, extract the focal length and principal point from the variable named KK and cc respectively, and save these extrinsic in the variable named as KK_1.
- Extract the pose of last image from calibration dataset and save it into variable as Tc_1 and Rc_1.
- Use these pose as a reference for reconstructing different objects.
- Save these variables into a .mat file

***
***

## **Calibrating Mirror View**

***Calibrating using mirror view - Corner extraction, calibration, additional tools**

This section explains how to use all the **features** of the toolbox to calibrate the **mirror**.
## **Steps**
 - **The initial procedures necessary to calibrate the mirror are exactly the same as those described in the calibration of the primary original view**.
- **The only thing that is different is the order in which you click because, in the mirror, the points are reflected**.
- **The section below explains visually the order of clicking in the mirror**.


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

- **The first point which is the origin in the mirror view is the reflected version of the origin point original view.**
- **The 2nd point in the mirror view is the reflected version of the 2nd point's original view.**
- **The 3rd point in the mirror view is the reflected version of the 3rd point's original view.**
- **The 4th point in the mirror view is the reflected version of the 4th point's original view.**


![asddd](https://user-images.githubusercontent.com/65610334/212284205-98c2ad36-cfc8-4c32-bb10-5470510179c5.jpg)
The boundary of the **calibration grid** is then shown below: 
![BBIMAGES](https://user-images.githubusercontent.com/65610334/212285450-3e0ecadc-eb91-4ae3-a029-32efa048535f.jpg)
Follow the **same procedure** for **corner extraction** as explained in detail in the **calibration of the original view**.

![casaasaa](https://user-images.githubusercontent.com/65610334/212286733-16bbf630-b0c9-4b64-ad22-22fe9e80503e.jpg)

**Corner extraction...**

![extracted acdcc](https://user-images.githubusercontent.com/65610334/212286285-18da988a-4855-4b63-885e-e1035fa1f071.jpg)

**Follow the same procedure for the rest of images in the dataset.**
**Main Calibration step**

The main calibration step for the mirror view **same** as described for the **original view**.

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

The Calibration parameters are stored in a number of variables.  The **reprojection** on the **images** step is the same as **explained** in the **original view**.


The following figures shows the  four images with the **detected corners (red crosses)** and the reprojected grid corners (circles). 



![Unadsm](https://user-images.githubusercontent.com/65610334/212606564-7dcd28b3-393d-4c4e-9730-6ce153e7e08f.jpg)


**Number(s) of image(s) to show ([] = all images) = 
Pixel error:      err = [0.23616   0.25538] (all active images)**

The **reprojection error** is also shown in the form of **color-coded crosses:** 

![r5](https://user-images.githubusercontent.com/65610334/212606286-b63e08bc-d689-41c8-81f0-7d249d653b8b.jpg)
In order to exit the error analysis tool, right-click on anywhere on the figure (you will understand later the use of this option).

Follow the same technique as indicated in the **calibration of original view** to display the **extrinsic parameter**. 

The extrinsic parameters (relative positions of the grids with respect to the camera) are then shown in a form of a 3D plot: 

![3d](https://user-images.githubusercontent.com/65610334/212606407-4e0ecebd-f88a-4601-be5e-90e711b6797d.jpg)

Simply click the Switch to **world-centered view** button in the bottom-left corner of the image to go from a **"camera-centered" perspective to a "world-centered" view**. 

![3d2](https://user-images.githubusercontent.com/65610334/212606469-06ea4d63-1fd7-4d36-91d9-511b0091f3a8.jpg)


## **Camera Matrix for Mirror View**

- The procedure for extracting the camera matrix for the mirror view is the same as described for the original view.
- Save the camera intrinsics into a variable named KK_2.
- Save the rotation and translation matrix into a variable named Rc_2 and Tc_2 respectively.
- Save these variables into a .mat file


## **Camera Matrix for Original and Mirror View**

- Calibration for both the original and mirror view is completed. Now you have two mat files containing the camera matrix for the original and mirror view.
- Now merge both files to a single file containing your camera matrix for original and mirror view.
- The mergerd file should look like this https://github.com/Asad127/3D-RECONSTRUCTION/blob/main/Code/merged_params.mat.
---------------------------  ![merout](https://user-images.githubusercontent.com/65610334/212697559-11b17a6a-50d7-4ae4-ba68-1dae61a465c6.PNG)

# **3D Reconstruction of Different Objects**
You can remove the calibration checker pattern at this stage if you want to. It is no longer needed.

## **1. World Reference and Choice of Extrinsics (R and T)**
In order to reconstruct an object, we need a reference for the world frame and a pose for the camera relative to that frame. Additionally, we may assume that the camera does not move between image captures, so that the camera pose relative to the reference world frame remains the same for all future images. In our setup, the camera remains fixed and only the checker is moved, so we can apply the assumption that the camera does not move between images. 

The calibration process outputs the camera pose (rotation R and translation T) for each image in the calibration set. In light of this, we capture an image (henceforth the *reference image*) of the checker in a flat position to serve as our world reference for the camera's pose during reconstruction of other test objects. To estimate the pose from the reference image, we can either keep it in the original-view calibration set so that we get the R and T directly during calibration, or we can use the `Comp. Extrinsic` function of the toolbox post-calibration. Since we have two views calibrated separately (the original and reflected sets), we need to do this two times -- once for each view of the reference image.

Usually, we add the reference image as the last image of the calibration set for our own ease, but you can just as easily keep the first image as a reference. We prefer a flat position because it makes the most geometrical sense for our setup. 

>**NOTE:** In the event the assumption of a fixed camera is violated, the camera's pose must first be estimated using some algorithm like Perspective-n-Point (PnP). If the new position still has a view of the checker, the toolbox's `Comp. Extrinsic` function can be used as well.

#### Overall Process

At the end, for the two reference images, we require just a few parameters for the next steps. Since we have two views, let us define `j = {1,2}` where `j = 1` means the original view and `j = 2` means the mirror view. Then, assuming we kept the reference image as the k^th^ image of the calibration set (`k = 1,2,3,...`), then we have:

- Camera Intrinsics (`KK_j` -- already have these from the calibration steps)
- Rotation (`Rc_k` in toolbox -- orientation of the camera relative to world frame in reference image)
    - Rename this to `Rc_j` (ignore this step if `k = j`)
- Translation (`Tc_k` in toolbox -- translation of camera center relative to world frame in reference image)
    - Rename this to `Tc_j` (ignore this step if `k = j`)

Save these variables from their respective calibration workspaces (*original* and *mirror*) separately, rename them according to the view number `j` e.g., `Rc_1` (original) and `Rc_2` (mirror), and then merge them together. In summary:

1. Save the variables `KK`, `Rc_k`, and `Tc_k` from the ***original view calibration*** workspace into `original_params.mat`
2. Save variables `KK`, `Rc_k`, and `Tc_k` from the ***mirror view calibration*** workspace into `reflected_params.mat`
3. Rename the variables in `original_params.mat` as follows: `KK ---> KK_1`, `Rc_k ---> Rc_1`, `Tc_k ---> Tc_1`
4. Rename the variables in `reflected_params.mat` as follows: `KK ---> KK_2`, `Rc_k ---> Rc_2`, `Tc_k ---> Tc_2`
5. Merge the two .mat files into one `merged_params.mat` for later use
    - Variables in `merged_params.mat` : `KK_1`, `Rc_1`, `Tc_1`, `KK_2`, `Rc_2`, `Tc_2`  

##### Why Rename?
If the calibration set had 15 images and the 15^th^ was the chosen reference, it would be `Rc_15` in the toolbox workspace. Our reconstruction script assume the reference R and T are subscripted 1 for original view and 2 for mirror view, so we need to rename them. 

##### Next Steps
Moving on, without moving the camera, remove the checker (optional), introduce the object for reconstruction, and capture its images in various positions. Finally, during reconstruction, use the R and T from the reference image to serve as the pose for the test images as well. These steps are disucssed in more detail in the upcoming sections.

## **2. Gathering Test Images**
Place the object you want to reconstruct in the calibrated region, and make sure its features are clearly visible in both the calibrated mirrors. Capture as many images you want with the test object in various positions. Finally, make exactly **one copy** of each captured image, so that there are two images for each scene. The idea is to use the copies for working with the mirrored views later.

The **naming** of these image files is important. The basename should be the same (we use 'Image') followed by a natural number. To keep things simple, we use odd numbers for original views and even numbers for the reflected view copies, and assume that the pairs are arranged consecutively i.e., image 1 is paired with image 2, image 3 with image 4, and so on. This provides a quick way of working with any pair of images.

An example test image is given below. Note how all the dots are visible in both the reflection and the original object.

![Image2](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)
<center><i>Example test image</i></center>

## **3. Point Marking on 2D Test Images**

Now, we need to extract some **corresponding 2D points** (pixels) from the original and reflected view of the object in the test image(s). We have created the script `point_marker.mat` to manually click and store the pixels corresponding to the object's features in any given image pair. 

Simply place the script next to the image(s) from the earlier sub-section and proceed with the steps below. 

>**NOTE:** We will be reconstructing the 3D coordinates using these 2D points, so it is important to ***mark them accurately.***

### SCRIPT: `point_marker.mat`
1. Open the script and check the value of `npoints`. This is a user parameter - set its value to however many points you want to mark in the image.
2. Run the script and select the pair of images you want to work with. E.g., `[1 2]` or `[3 4]`. Remember, odd is original, even is reflected, and we arranged pairs as consecutive numbers.
**NOTE:** The script currently only supports only one pair of images, so `[1 2 3 4]` is not a valid input, and neither is `[1 2 3]`. 
3. An image will pop up. Here, mark exactly `n` points on the **original view** of the object you want to reconstruct by clicking on them.
3. After marking exactly `n` points, another image window will open. Here, you must again mark `n` corresponding points in the **mirror view**. 
**NOTE:** Mark the points in the *same physical order* as in Step 2 and make sure to click on the *reflected* point (i.e., if you marked the top-right corner as the first pixel in Step 2, you must mark the top-left corner in the reflected view).
4. Once the correspondences are marked, the script will generate a `points_x_nimo_column.mat` file containing two variables:
    - `npoints`: An integer describing the number of points marked.
    - `xj`: The pixel locations of the marked points in both the views.

![ddd Diagram](https://user-images.githubusercontent.com/65610334/212617135-aa878f26-fa2d-4e7f-841a-9f663eefbc5b.jpg)
<center><i>Point correspondences visualized on text object</i></center>

#### Output Details: `xj`

For two-view correspondence over `n` points, `xj` is a `2 x 2n` matrix. The two rows represent the `x` and `y` pixel coordinates. The columns `1 : n` are the points marked in the original view and columns `n + 1 : 2n` are the reflected corresponding points, marked in the mirror view.

The pixel location in **column 1** of `xj` (i.e., first marked point in the original view) *corresponds* to the pixel location in **column `n + 1`** (i.e., first marked point in the mirror view). Similarly, the second pixel in column 2 corresponds to the reflected pixel at `n + 2`, and so on.

In general, the pixel in column `k` such that `k <= n` corresponds to the pixel in column `n + k`. Each of these pixel correspondences represents a single physical point in the world. We can then use `xj` by appropriately slicing it to select the pair of corresponding points points we need for reconstruction.

> **NOTE 1:** `xj` is named so after the variable names in the projection equation `x = K * [R T] * X`, where `x` is the pixel projection of `X`. The `j` is to indicate that it contains the pixel locations over all the different views.

> **NOTE 2:** While we mark a total of `2n` pixels over two images in this step, we are actually only dealing with `n` real-world points. They are just projected to two views. If we had k views, we would have a total of `k * n` points.

## **4. 3D Point Estimation and Reconstruction**
By now, we have: 

- Merged Camera Matrix [via CALIBRATION -- `merged_params.mat`]
    - Extrinsic Matrix (Rotation + Translation) 
    - Intrinsic Matrix (Focal Lengths + Principal Point Offsets)
- 2D pixel correspondences between the original and mirror views [via POINT MARKING -- `points_x_nimo_column.mat`]

Note that `merged_params.mat` has the variables:
- `KK_1`, `Tc_1`, `Rc_1` : Camera matrix for original view
- `KK_2`, `Tc_2`, `Rc_2` : Camera matrix for mirror view

You can see this also follows our earlier convention of image naming where an odd number means an original view image and an even number means a mirror image. Keeping this distinction helps us greatly in the coding stage.

We are finally ready to begin reconstruction of the object's physical points in 3D world coordinates.

#### The Basic Idea for Estimation
At its core, our approach to the problem of reconstruction is to think of it as an optimization problem. We presume that a fairly accurate solution for the depth (Z-coordinate) of each 2D point (pixel) on the object exists, given any two views of the object. The two views apply the constraint that the two rays from the camera centers to the object point in 3D space will intersect at that object point, which is at some depth Z.

Now, since there is only one world reference frame, the same 3D world points must project to two different pixel locations on the two cameras. We already know these pixel locations -- we marked them just now! Therefore, all we really need to do is figure out the choice of 3D points for which the forward projection (i.e., pixel projection `x = K * [R T] * X`) of both the views is correct (i.e., the reprojection error in both images is collectively minimized). 

Like with other optimization problems, we start with a wild guess or a simple matrix of ones for the world coordinates `X`, calculate the reprojection error, and update our guess accordingly. We settled on the mean squared per-pixel reprojection error.

### SCRIPT: `reconstruction_3d.m`
As a preliminary, open the script and look at the following:

1. Set the value of `org_dist` if you have a regular repeating pattern for error histogram (otherwise it is not needed)
2. Set optimizer options. We worked with:

        options = optimoptions('lsqnonlin', 'display', 'off', 'MaxIter', 500, 'MaxFunEvals', 6.240000e+05)
        options.Algorithm('levenberg-marquardt')
3. Make sure your images names match the onesi n the script, otherwise imread will fail to load them.

Now run the script.

#### Initialization
1. Load the following .mat files created earlier:
    - `merged_params.mat` 
    - `points_x_nimo_column.mat`
2. Input which pair of images you want to work with e.g., `[1 2]`, etc.
3. Define the total number of views and number of images based on user input.
4. Assign the pose and intrinsics from `merged_params.mat` into slice friendly variables.

#### Optimization With `lsqnonlin`
The optimization is done on a per-pixel basis. Note 2D points and pixels are used interchangeably.

1. Initialize:
    - Initial guess for 3D world points as a homogenous vector of ones `X_init = ones(4, 1)` 
    - Array of zeros to store estimated homogenous 3D coordinates against each pixel `X = zeros(4, npoints)`. For each estimated 3D point in the optimize step, the corresponding column of this matrix is updated.
    - Array of zeros to store the pixel projection of the same physical point in each of the two views `xpp = zeros(3, n_views)`. We will fill this during the optimization loop over all the pixels
2. Optimize over all pixels such that for each pixel `i`:
    - Get the pixel location in both views from xj by indexing into its i^th^ and n+i^th^ columns and store it in `xpp`.
    - Estimate the 3D points with non-linear least squares (`lsqnonlin`) using the ***target vectored error function*** `reconst_coords_per_px`.
    - Normalize the estimated homogenous 3D points w.r.t. the homogenous coordinate.
    - Store the result in the corresponding i^th^ column of `X`.
3. Once the optimization loop is finished, we have an estimate for the 3D points of all the `n` points we marked.

##### Vectored Error Function for `lsqnonlin`
The vectored error function takes the following as its input:
1. Which parameter to optimize over the given inputs? (`X`)
2. Initial guess for parameter to optimize (`X_init`)
3. Number of views (`2`)
4. Pixel points over all the views (`xpp`)
5. Intrinsic Matrix (`K`)
6. Rotation Matrix (`R`)
7. Translation Vector (`T`)

Here, `xpp` is the true value since it was assigned values from `xj`, the 2D points marked earlier. Then, using a for loop, we can slice into the relevant view's pose, intrinsics, and use the current guess for `X` to get some predicted pixel projections. Subtracting the results from the actual pixel projections in the j^th^ column of `xpp`, we get the reprojection error. At the end, we have a vector error of just 2 elements (1 error against 1 pixel for each view). The function then recurses as per `lsqnonlin` implementation until a threshold of error is reached or until the gradient sizes become too small (the function plateaus).

However, for the mirrored view (`j = 2`), we need to make sure we swap the x and y axes (the first two rows) of the world frame. This is because the calibration toolbox forces right-handedness of frames which causes the mirrored corresponding point to have a Z-axis pointing down instead of up, like in the original view. This causes the x and y axes in the original view to become the y and x axes in the reflected view for the toolbox. This is clearly wrong for our correspondence, so we must swap the axes for the world frame of the mirrored view ourselves to ensure their swapped nature does not cause errors in the optimization against the correct framing of the original view. In simpler words, we are essentially aligning the axes of both the 3D world frames, so that the resulting estimation is correct.

    if j == 2
        X = [X(2); X(1); X(3); X(4)];
    end

> NOTE: `lsqnonlin` implements mean square error implicitly using the vectored error provided and calculates gradients based on their collective minimzation, so we can be sure it optimizes for both views at once.

#### Result Accuracy and Visualization
We can now plot the results for verification. We get the pixel projections using the estimated world coordinates (red stars) and plot them against the originally marked pixel points. This gauges the reprojection error. Then, we plot the 3D world points in 3D space to get a sense of whether the actual structure of the object was recovered, or if the optimizer failed to recover structure even with a small reprojection error. We also calculate a few metrics like the mean reprojection error over the entire set of `n` points and print them to the command window. Finally, if we used a regular pattern, we can also plot a histogram of errors. However, this is very situational.

Again, since we swapped the axes of the mirrored frame during the estimation of the world points, we need to swap them back to their original form (Z-axis down convention) before we find their pixel projections. This is because while our trick allowed it to deal with the problem by tricking the extrinsics into thinking it was being multiplied with X instead of Y and Y instead of X (as it should be if the toolbox did not force right-handedness), we have essentially ended up with a swapped version of the world coordinates that the right-handed system of the mirrored image understands. Thus, to plot them correctly, we must swap them back to their original form when plugging them into the forward projection equation.

- The ouput of the above code is as follows:
![R4](https://user-images.githubusercontent.com/65610334/212618909-913d524c-792e-44d0-b6eb-37a7c7d00d78.jpg)

- The illustration 3d world points  is shown below:
              ![untitl211221ed](https://user-images.githubusercontent.com/65610334/212619094-96753fd8-5b20-4c7d-8798-07dada5a0c29.jpg)

- While the error histogram between the 2d original points and 2d estimated points is as follows:

 ![R4_Hist](https://user-images.githubusercontent.com/65610334/212619373-74e057af-ee18-4eb2-b671-9f77acc565dc.jpg)

## **Note**
**We have provided the marked 2d points of different objects for 3d reconstruction in the marked points folder. You can use them to reconstruct different objects.**
## License
**MIT**



  
