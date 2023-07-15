# **Bouguet Calibration Toolbox: Getting Started**

If you are new to the MATLAB's Camera Calibration Toolbox (specifically, Bouguet Calibration Toolbox or BCT for short), we recommend downloading the toolbox from the [official webpage](http://robots.stanford.edu/cs223b04/JeanYvesCalib/) and following along with the first few examples on the webpage to familiarize yourself with the general process. Furthermore, add BCT to your MATLAB path as well in order to use it in any directory within your computer.

> ***Trying out the examples is highly recommended for anyone who has not used the toolbox before.***

### **Encountered Issues**
As we were developing the toolbox, we encountered some problems when working with BCT. We list them below along with their solutions:

1. (CRITICAL) Could not save calibration results when clicking on the **Save** button in the calibration GUI.

2. Projected Points Matrix `x` saved by BCT does not have the correct number of columns.

To fix (1), head to BCT's directory and open up `saving_calib.m` in MATLAB or some text editor. Move to line 176, and replace it with the following:

```matlab
cont_save = input('Do you want to continue? ([]=no,other=yes) ', 's');
```

To fix (2), head to BCT's directory and open up `go_calib_optim_iter.m` in MATLAB or some text editor. In lines 548, 551, and 554, replace `x` with `xp`. The corrected lines are shown below:

```matlab
% ...LINE 548...
[xp,dxdom,dxdT,dxdf,dxdc,dxdk,dxdalpha] = project_points2(X_kk,omckk,Tckk,fc,cc,kc,alpha_c);

if ~est_aspect_ratio,
    [xp,dxdom,dxdT,dxdf,dxdc,dxdk,dxdalpha] = project_points2(X_kk,omckk,Tckk,fc(1),cc,kc,alpha_c);
    dxdf = repmat(dxdf,[1 2]);
else
    [xp,dxdom,dxdT,dxdf,dxdc,dxdk,dxdalpha] = project_points2(X_kk,omckk,Tckk,fc,cc,kc,alpha_c);
end;
% LINE 555...
```

Problem (2) exists because, while `x` is originally computed in the script with no. of columns = no. of checker corners * no. of images, it is later (probably unintentionally) replaced by another computation of `x` (see lines 548-555 above), this time only for a particular image, so that this new `x` has no. of columns = no. of checker corners.

This problem does not affect the mirror reconstruction toolbox, but it is something we noticed in our very early tests with reprojection on the checker corners.

## **Step I - Calibration Dataset Collection**

The following section explains how to setup the system for capturing multiple views using a single camera fixed on a tripod and reflective mirrors present in the field of view. In the figure below, we show the **mirror container, the tripod, and the light source** we have used to capture our images.

![Experimental Setup](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1a441f87-5c4e-4080-8dd7-59c13374ca84)

> ***Camera stand and mirror setup MUST NOT MOVE throughout the process!***

1. Print a checker pattern and measure the dimensions (x and y) of any one square on the checker.

    ![Checker Pattern](https://user-images.githubusercontent.com/65610334/213092640-4103b6af-ab70-4ce6-b13a-1a96a0c0a437.jpg)

2. Place the camera on the tripod and place it at a suitable distance from the mirror setup/container.

    ![Camera To Checker Distance](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/815ef573-3669-4f71-8c0a-2b5b1987179b)

3. Place the checker in the mirror container and make sure it can be seen in all three views, i.e., original and both the mirror views.

    ![Image With Checker Visisble In All Views](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d794dc09-3ea2-4412-9865-e4e9c24b01ef)

4. Take a picture of the checker from the camera.

5. Change the position of the checker in a limited region to ensure that the pattern can be seen in all relevant views, i.e., the original and both the mirror views, and capture an image.

6. Repeat Steps 4&ndash;5 to capture at least 15&ndash;20 images of the checker pattern at different positions. Make sure the checker's pose varies considerably between images in order to get a good calibration.

    ![Calibration Images Mosaic](https://user-images.githubusercontent.com/65610334/212243538-0619adad-a8d8-41ab-a801-c1aee23537e4.png)

#### **All-View Visibility Assumption**

Note that, in Step 5, if the assumption of the checker being visible in all views is violated, the calibration for each view can still work as long as there is at least one image where the checker is visible in all views. However, image selection becomes a little complicated.

Essentially, you only need one common reference image of the checker which is visible in all views (camera + both mirrors) when calibrating the setup. This image serves as the common world frame reference (on the checker) for all views and is used to compute the extrinsics. Since for this image, the checker is visible in all views and corresponds to the same time instant, the inter-view poses and hence the scene's geometry is correct.

In light of this, as each view's calibration is independent, you can select different image subsets for calibrating each view, as long as:

1. You ensure that neither the camera, nor the mirrors, move.
2. You ensure that at least one image is commonly visible in all views (for common world reference and corresponding pose for all views).

A good choice for point 2 is to leave the checker flat in front of both the mirrors. Usually, we keep this as the first or last image, though it may be any image in the set. After that, you can free yourself of the worry that the checker is visisble in all views and focus only on one particular view at a time.

> We only recommend breaking the assumption if following it makes checker movement very restrictive (necessary for a good calibration) or results in a bad calibration.

#### **Calibration and Reconstruction Accuracy**
Reconstruction accuracy is heavily dependent upon good calibration, so make sure you cover a variety of poses when taking the calibration images or recording the calibration video. If BCT shows good reprojections but the undistorted function results in bogus undistortions, or the reconstruction is inaccurate, or reprojections are fine for some points on the image and bad for others, it is VERY likely the calibration is faulty.

In such cases, try to remove redundant and bad images from the existing set of calibration images, and take more calibration images with a greater variety of poses and repeat the calibration.

## **Step II - Original View Calibration**

This section explains how to use the **Camera Calibration Toolbox for Matlab**, also called the **Bouguet Calibration Toolbox (BCT)** after the author, to calibrate the original set of images. We go through all the relevant features of the toolbox step-by-step for our purposes below.

> For inputs that have `[]` as an option, you can just leave them blank and press enter to provide an 'empty' input, which uses the default value as suggested by the toolbox.

### **1. Loading Calibration Images**

1. Download the calibration images all at once from [here](https://github.com/Asad127/3D-RECONSTRUCTION/tree/main/Dataset) or one by one, and store all the images into a seperate folder named `calib_data` or anything else.

2. From within MATLAB, go to the folder you just put the images into in Step 1 and type `calib_gui` into the command window (assuming BCT was added to the MATLAB path, this should work in any directory within the computer).

3. Click on the **Image Names** button in the camera calibration tool window (GUI) and go through the prompts for the image basename and format.

<p align="center" width="100%">
    <img alt="Image Names Button" src="https://user-images.githubusercontent.com/65610334/213086588-19a14b08-0927-40a4-9096-24c3c581bcc0.png">
</p>

4. BCT will display a directory listing (all files and folders in the current MATLAB directory). You will be prompted to enter the image basenames and their extension identifier (e.g., **j** for .jpg, **p** for .png, etc.). Following a typical naming convention, e.g., {Image1.jpg, Image2.jpg, ..., Image12.jpg}, the basename would be **Image** (i.e., the string part without the integer identifier), and the extension in this case would be **j**.

The following snippet of the command window shows the inputs and the output.

```
>> calib_gui

.            Image1.jpg   Image11.jpg  Image2.jpg   Image4.jpg   Image6.jpg   Image8.jpg
..           Image10.jpg  Image12.jpg  Image3.jpg   Image5.jpg   Image7.jpg   Image9.jpg


Basename camera calibration images (without number nor suffix): Image
Image format: ([]='r'='ras', 'b'='bmp', 't'='tif', 'p'='pgm', 'j'='jpg', 'm'='ppm') j
Loading image 1...2...3...4...5...6...7...8...9...10...11...12...
done
```

At this point, you should be presented with the following figure (a mosaic of the calibration images):

![Image Mosaic](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/80b19d0c-faa0-45cf-9116-93391a5ecdfd)

This marks the end of the image loading process.

#### **Image Selection When All-View Visibility Assumption Is Violated**

Consider an extreme scenario. Assume you have two mirrors and the checker was not visible to either of them in all calibration images except for one. Additionally, suppose that the checker was visisble to the camera view in all images. As discussed earlier, calibration is still possible in this case. However, the image selection must be handled with care.

For example, let Image 1 has the checker present in all views, 2&ndash;15 has the checker visible in only the first mirror, and 16&ndash;30 has checker visible in just the second mirror. In such a scenario, when calibrating the first mirror, use images 1&ndash;15, and when calibrating the second mirror, use images 1 and 16&ndash;30.

Thus, the basic idea is that when selecting images for each view, ensure that the checker is visible within that view in the calibration image before loading it in. A similar approach can be used if the checker is not visible in the original camera's view, and only in the reflected view(s).

### **2. Extract the Grid Corners**

1. Click on the highlited button of **Extract Grid Corners** in the calibration GUI.

    > You can click directly on Extract Grid Corners upon launching `calib_gui`, and it will automatically begin the image loading process described in Step 1.

<p align="center" width="100%">
    <img alt="Extract Grid Corners Button" src="https://user-images.githubusercontent.com/65610334/212662591-9ce4ac12-9114-4fb6-8b8c-e9792c70e7bb.png">
</p>

2. Enter the global settings in the corresponding prompts: window size for corner finding and whether to auto-count squares along the x and y directions or manually enter them for each image.

    > These global settings are used for extracting corners from all images. Most of the time, auto-counting works fine. In the event it fails for any reason (usually a misclick on the user's end), the toolbox will revert to manual input.

    ![Command Window With Highlighted Input Fields](https://user-images.githubusercontent.com/65610334/213191980-d15f847a-52db-4f7a-9357-22a4f2dfc577.jpg)

3. Mark the four extreme internal checker corners on the figure that pops up after Step 2.

    ![Clicker Figure](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/667b1f32-1492-461b-9d26-90264ea50986)

#### **Clicking Order for Extreme Internal Corners**

The **first** clicked point is selected as the **origin** of the world reference frame attached to the checker grid. The **second** click defines the direction of the **Y-axis** of the reference frame from **(1st click &rarr; 2nd click)**. The **third** click defines the direction of the **X-axis** of the reference frame **(2nd click &rarr; 3rd click)**. The fourth click will complete the **plane's definition** as **1st click &rarr; 2nd click &rarr; 3rd click &rarr; 4th click &rarr; 1st click**.

> As you mark these four extreme corners in the first image, note the clicking order and follow it for the rest of the images. We will need it to associate the reflected points properly when calibrating the mirror images.

We illustrate the clicking order that we followed for our calibration below.

![Clicking Order](https://user-images.githubusercontent.com/65610334/213100379-beb1dad9-47d7-47b4-bd3b-30200bd67aef.png)

The planar boundary of the calibration grid is then shown below.

![Planar Boundary Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/4fc44c25-7394-4e52-a3ff-e4dbf8031f18)

4. After marking the four extreme corners, the toolbox prompts for the **dimensions** of the squares on the checker pattern (in millimeters). Here, you enter the values measured earlier.

    ![Command Window With Highlighted Input Fields](https://user-images.githubusercontent.com/65610334/213192408-17ee514f-5aba-438a-b2fb-a141242d8d5b.jpg)

5. (OPTIONAL) Enter a guess for the distortion parameters, which can help with corner detection if your camera suffers from extreme distortion. However, this is empirical and you would have to fiddle around a little bit to get the right results. Otherwise, you can completely skip this step with an empty input.

    BCT will proceed to first guess all the checker corner locations within the plane defined in Step 3, and then refine them to subpixel accuracy.

    ![Guessed Corners Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d32ca298-f2be-4e5c-8aa5-3e7ff3c73b80)

    ![Refined Corners Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f470b44c-98a7-4b66-a5b2-1165d2021a9d)

6. Repeat steps 1&ndash;5 for the rest of the calibration images. For each new image, you will only be prompted for the initial guess for distortion as the toolbox assumes the same checker pattern has been used in each image.

Once corner extraction is complete, the matlab data file `calib_data.mat` is automatically generated. This file contains all the information gathered throughout the corner extraction stage (image coordinates, corresponding 3D grid coordinates, grid sizes, etc.). Assuming a clear MATLAB worksapce, you can recover all this information by launching `calib_gui` from the command window, and then loading `calib_data.mat` into the workspace. Then, you can proceed directly to the main calibration step.

![Clicked Corners MATLAB Workspace (`calib_data.mat`)](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/351c6791-d1c4-42a7-8ec5-c2dceefa3944)

### **3. Main Calibration Step**

At this point, we have all the information required to begin calibration. Click the **Calibration** button on the calibration GUI to run the main camera calibration procedure.

<p align="center" width="100%">
    <img alt="GUI button" src="https://user-images.githubusercontent.com/65610334/212663304-28278a91-0cbf-4638-91e2-a679576e44ff.png">
</p>

```
Initialization of the intrinsic parameters - Number of images: 12

Calibration parameters after initialization:

Focal Length:          fc = [ 1529.18846   1529.18846 ]
Principal point:       cc = [ 1631.50000   734.50000 ]
Skew:             alpha_c = [ 0.00000 ]   => angle of pixel = 90.00000 degrees
Distortion:            kc = [ 0.00000   0.00000   0.00000   0.00000   0.00000 ]

Main calibration optimization procedure - Number of images: 12
Gradient descent iterations: 1...2...3...4...5...6...7...8...9...10...done
Estimation of uncertainties...done

Calibration results after optimization (with uncertainties):

Focal Length:          fc = [ 1507.97898   1496.24779 ] ± [ 26.82888   26.88096 ]
Principal point:       cc = [ 1536.92900   695.75342 ] ± [ 38.21710   42.19543 ]
Skew:             alpha_c = [ 0.00000 ] ± [ 0.00000  ]   => angle of pixel axes = 90.00000 ± 0.00000 degrees
Distortion:            kc = [ -0.12315   0.13155   0.00248   -0.01555  0.00000 ] ± [ 0.05752   0.11221   0.00904   0.00697  0.00000 ]
Pixel error:          err = [ 0.23942   0.24756 ]

Note: The numerical errors are approximately three times the standard deviations (for reference).
```

The calibration parameters are stored in a number of variables in the workspace.

### **4. (OPTIONAL) Reprojection Using Estimated Camera Parameters**

Click the **Reproject On Images** button in the calibration GUI to show the reprojections of the grids onto the original images. These projections are computed based on the estimated intrinsic and extrinsic parameters from the calibration step.

<p align="center" width="100%">
    <img alt="Reproject On Images Button" src="https://user-images.githubusercontent.com/65610334/212663501-41912859-477e-4ced-8a0d-e7fd0082a60d.png">
</p>

```
Number(s) of image(s) to show ([] = all images) to indicate that you want to show all the images:
Number(s) of image(s) to show ([] = all images) = []
```

The following figure shows four of the images with the detected corners (red crosses) and the reprojected grid corners (circles).

![Reprojections Mosaic Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/2aa8b843-09df-4785-949d-3b7790d97ec8)

```
Number(s) of image(s) to show ([] = all images) = []
Pixel error:      err = [0.23942   0.24756] (all active images)
```

The reprojection error is also shown in the form of color-coded crosses, as shown in the figure below.

<p align="center">
    <img alt="Reprojection Errors Camera View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d4e2b763-fffd-4627-a71b-cb98cc01b71f">
</p>

### **5. (OPTIONAL) Plot the Camera and Checkers in 3D Space**

Click the **Show Extrinsic** button in BCT's GUI.

<p align="center" width="100%">
    <img alt="Show Extrinsic Button" src="https://user-images.githubusercontent.com/65610334/212663777-fa2082bb-9bd2-4e5c-8ff5-215286a4739c.png">
</p>

This will plot the camera and checkers using the estimated extrinsics from the calibration step, as shown in the figure below. On this figure, the frame (Oc, Xc, Yc, Zc) is the camera reference frame. The red pyramid corresponds to the effective field of view of the camera defined by the image plane.

![Camera Centered Extrinsics Visual](https://user-images.githubusercontent.com/65610334/212271252-c6ea1ed7-6e7b-4539-b9c6-5a6faf816d34.jpg)

To switch from a "camera-centered" view to a "world-centered" view, click on the **Switch to world-centered view** button located at the bottom-right corner of the figure.

![World Centered Extrinsics Visual](https://user-images.githubusercontent.com/65610334/212271620-ba55ff88-e193-4bd2-9fcd-66547ce13fa1.jpg)

### **6. Saving the Calibration Results**
Click on the highlighted button of **Save** on the calibration GUI.

<p align="center" width="100%">
    <img alt="Save Button" src="https://user-images.githubusercontent.com/65610334/213089098-8d0d4f67-8d9c-44df-b708-bc5984c4499f.png">
</p>

BCT generates two files in the current directory in MATLAB:

- `Calib_Results.mat` : The workspace containing all the calibration variables involved in the process.
- `Calib_Results.m` : A script containing just the estimated intrinsics of the camera and extrinsics of each image in the calibration set.

We only require the matfile, so rename `Calib_Results.mat` to `Calib_Results_cam.mat` to indicate that this is the actual camera's calibration. Renaming now also prevents future calibration results from replacing this one.

We are now done calibrating the first view (the actual camera).

#### **Notes on Reference Image and Extrinsics**

Before we move on to the mirror view calibration, we must make an important note on the world reference image. For reconstruction on test images later on, we need a common image reference for the world frame and a pose for each view relative to the checker in that image. We assure that, during calibration, the **camera does not move between image captures**, so the camera pose relative to the reference world frame remains the same for both the calibration images and the images we take at test time.

The calibration process estimates the camera pose (rotation R and translation T) for each image in the calibration set. These poses can be viewed in the `Calib_Results.mat` file, as `Rc_{image suffix}` and `Tc_{image suffix}`. So, if we had the images {Image1.jpg, ..., Image30.jpg}, then `Tc_15` and `Rc_15` correspond to the extrinsics for Image15.jpg. Suppose that our reference was Image1.jpg, then during calibration, this image is also included in the calibration set, so BCT computes its pose (R and T) and we can use that at test time.

In the event that the image reference is not included in the calibration image set, BCT's **Comp. Extrinsic** function can be used to compute the extrinsics, and this case, the suffix is `ext` (e.g., `Rc_ext`) instead of a number. However, this is a special case discussed in detail at the end under the section ***Special Scenarios***.

As mentioned earlier, for convenience, we choose a flat checker position for the reference image, and include it as either the first or last image of the calibration set. We prefer a **flat position** because it is both intuitive and geometrically easy to verify.

## **Step III: Mirror View Calibration**

This section explains how to calibrate the mirror view using the reflection of the checker in the mirrors. The procedure is exactly the same as described for the calibraiton of the original view. The only thing that is different is the **clicking order** because, in the mirror, the points are **reflected**.

This process must be repeated separately for each mirror.

> If continuing directly from a previous view's calibration, CLEAR THE WORKSPACE, CLOSE ALL FIGURES, and RESTART `calib_gui` before proceeding to avoid issues with existing workspace variables.

### **1. Loading Calibration Images**

The procedure remains exactly the same as in the camera's calibration, and we can use the same images (assuming the checker was visisble in the mirrors).

![Clicker Figure](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/3a415ef3-39dd-4255-a841-661dc20a5a11)


### **2. Extracting the Grid Corners**

The only change in this step is the **clicking order**, and that the points must be marked in the mirror reflections of the checker. Everything else remains the same.

#### **Clicking Order for Extreme Internal Corners**

We visually explain the **reflected clicking order** in the mirror images below. Note that the clicking order here depends on the clicking order from when the original set was calibrated.

- The 1st point which is the origin in the mirror view is the reflected version of the 1st point clicked in the original view.

![First Reflected Click](https://user-images.githubusercontent.com/65610334/213103299-0d84a03f-df85-4905-ae81-a4593c1b468b.png)

- The 2nd point in the mirror view is the reflected version of the 2nd point clicked in the original view.

![Second Reflected Click](https://user-images.githubusercontent.com/65610334/213103667-cbc71cc0-1f07-4626-9380-795f8a7eef3b.png)

- The 3rd point in the mirror view is the reflected version of the 3rd point clicked in the original view.

![Third Reflected Click](https://user-images.githubusercontent.com/65610334/213103941-cbd1bdbd-d32e-4bcb-8b93-3dfaaf59e7f0.png)

- The 4th point in the mirror view is the reflected version of the 4th point clicked in the original view.

![Fourth Reflected Click](https://user-images.githubusercontent.com/65610334/213104939-e41129f9-e726-4329-b810-3d7503ce9821.png)

After the fourth click, the planar boundary of the **calibration grid** is then shown in a separate figure.

![Planar Boundary Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/30a5b99a-afba-4f91-b42b-bd7470a83596)

When prompted for the square dimensions on the checker pattern, enter the same ones used during the camera's calibration.

![Command Window With Higlighted Input Fields](https://user-images.githubusercontent.com/65610334/213192408-17ee514f-5aba-438a-b2fb-a141242d8d5b.jpg)

The tooblox first guesses the corner locations, prompts for the distortion guess (optional), and finally refines the guesses to subpixel accuracy; just like before.

![Guessed Corners Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/7a678694-dc5d-4242-a6da-efd8156ffbc0)

![Refined Corners Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/176ba5ac-a23d-47d5-95eb-9c6a463eec67)

> Repeat the same process for the rest of images in the calibration set. Again, BCT only prompts for the distortion guess for all images after the first.

### **3. Main Calibration Step**

The main calibration step for the mirror view is the same as described for the **original view**.

```
Initialization of the intrinsic parameters - Number of images: 12

Calibration parameters after initialization:

Focal Length:          fc = [ 1439.23693   1439.23693 ]
Principal point:       cc = [ 1631.50000   734.50000 ]
Skew:             alpha_c = [ 0.00000 ]   => angle of pixel = 90.00000 degrees
Distortion:            kc = [ 0.00000   0.00000   0.00000   0.00000   0.00000 ]

Main calibration optimization procedure - Number of images: 12
Gradient descent iterations: 1...2...3...4...5...6...7...8...9...10...11...12...13...done
Estimation of uncertainties...done

Calibration results after optimization (with uncertainties):

Focal Length:          fc = [ 1450.42395   1449.67211 ] ± [ 44.81565   36.31254 ]
Principal point:       cc = [ 1570.68503   759.76341 ] ± [ 52.54308   54.49669 ]
Skew:             alpha_c = [ 0.00000 ] ± [ 0.00000  ]   => angle of pixel axes = 90.00000 ± 0.00000 degrees
Distortion:            kc = [ -0.24718   0.51654   0.01726   -0.01352  0.00000 ] ± [ 0.12459   0.34828   0.00662   0.01536  0.00000 ]
Pixel error:          err = [ 0.29234   0.26648 ]

Note: The numerical errors are approximately three times the standard deviations (for reference).
```

### **4. (OPTIONAL) Reprojection Using Estimated Camera Parameters**

This procedure is also the **same** as in the **original view**.

![Reprojections Mosaic Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/7a4b4cab-16c6-4c92-bacf-cb718c014452)

```
Number(s) of image(s) to show ([] = all images) = []
Pixel error:      err = [0.23616   0.25538] (all active images)
```

<p align="center">
    <img alt="Reprojection Errors Mirror View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/5b96398b-6abd-4b6d-8e2b-93321b6cebe4">
</p>

### **5. (OPTIONAL) Plot the Camera and checkers in 3D Space**

Again, the process remains the same as discussed in the original view.

![Camera Centered Extrinsics (Mirror View)](https://user-images.githubusercontent.com/65610334/212606407-4e0ecebd-f88a-4601-be5e-90e711b6797d.jpg)

![World Centered Extrinsics (Mirror View)](https://user-images.githubusercontent.com/65610334/212606469-06ea4d63-1fd7-4d36-91d9-511b0091f3a8.jpg)

### **6. Saving the Calibration Results**

Repeat the same procedure as in the original view calibration to save the calibration results.

Rename the resulting `Calib_Results.mat` to `Calib_Results_mir1.mat` if this is for the first mirror, and to `Calib_Results_mir2.mat` if this is for the second mirror. The mirror numbering convention is subjective and up to you, e.g., left mirror is mirror 1, and right mirror is mirror 2, etc.

# **Wrapping Up**

Once you have done this process for the camera and up to two mirrors (as supported by our toolbox), you can proceed to Step II and onwards as documented in the main repo's `README.md`.

At this point, you should have the following files (assuming two views, 1 camera + 1 mirror):

<p align="center" width="100%">
    <img alt="Calibration Results" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/51fb8c43-3cbb-4404-b489-131f0e2dda93">
</p>

To reiterate, `calib_data_{view-name}.mat` saves the clicked corners information if you want to recompute the calibration parameters. `Calib_Results_{view-name}.mat` are the saved calibration results, including the intrinsics and extrinsics that we require for reconstruction. You will additionally have `Calib_Results_{view-name}.m` as well, which we personally recommend deleting as it is not used, but feel free to keep it. 

Step II in the main repo `README.md` deals with how to process these results and export them into a format that's suitable for the reconstruction scripts. Please go there for next steps.

# **Special Scenarios**

Following are a few special cases that are manly based around the violation of still camera/mirror setup assumption. However, proceed with caution as these are mostly untested on our end, and might produce unexpected results.

## **1. Using a Non-Calibration Image as the Extrinsic Reference**

Possible, but this requires (a) modifying the BCT's save script, and (b) an existing calibration.

(b) is not an issue, since we do have a set of calibration images, we just want to compute extrinsics reference on a separate image. If this separate image contains a checker, BCT's **Comp. Extrinsic** function may be used to compute the extrinsics corresponding to this image:

1. With the calibration loaded in, click the **Comp. Extrinsic** button in BCT's GUI.

2. Enter the name and extension of the non-calibration image. This will bring up a figure window.

3. Mark the four extreme internal corners of the checker in the image.

4. Enter the square dimensions of the checker into the command window. This will compute the extrinsics as `Rc_ext` and `Tc_ext` in the workspace.

As can be seen, the extrinsics are no longer indexed by the image number; they appear as `Rc_ext` and `Tc_ext` instead, ***AND ARE NOT SAVED UPON PRESSING THE SAVE BUTTON IN BCT's GUI!*** In order to save the non-calibration image's extrinsics, you must modify BCT's saving script `saving_calib.m`:

1. Locate the file in the BCT directory on your computer and open it up in a text editor / MATLAB.

2. Search for variable `string_save`. You will notice there are four occurrences; we are interested in the first and third:

    ```matlab
    % First occurrence - if route
    string_save = ['save ' save_name ' center_optim param_list active_images ... MaxIter'];
    ```

    ```matlab
    % Third occurrence - else route
    string_save = ['save ' save_name ' center_optim param_list active_images ... MaxIter'];
    ```

    Note that `...` above represent a bunch of other variables in between.

3. Replace the two occurrences with the following:

    ```matlab
    % MODIFIED First occurrence - if route
    if exist('Rc_ext', 'var') && exist('Tc_ext', 'var')
        string_save = ['save ' save_name ' Rc_ext Tc_ext center_optim param_list active_images ind_active est_alpha est_dist est_aspect_ratio est_fc fc kc cc alpha_c fc_error kc_error cc_error alpha_c_error  err_std ex x y solution solution_init wintx winty n_ima type_numbering N_slots small_calib_image first_num image_numbers format_image calib_name Hcal Wcal nx ny map dX_default dY_default KK inv_KK dX dY wintx_default winty_default no_image check_cond MaxIter'];
    else
        string_save = ['save ' save_name ' center_optim param_list active_images ind_active est_alpha est_dist est_aspect_ratio est_fc fc kc cc alpha_c fc_error kc_error cc_error alpha_c_error  err_std ex x y solution solution_init wintx winty n_ima type_numbering N_slots small_calib_image first_num image_numbers format_image calib_name Hcal Wcal nx ny map dX_default dY_default KK inv_KK dX dY wintx_default winty_default no_image check_cond MaxIter'];
    end
    ```

    ```matlab
    % MODIFIED Third occurrence - else route
    if exist('Rc_ext', 'var') && exist('Tc_ext', 'var')
        string_save = ['save ' save_name ' Rc_ext Tc_ext center_optim param_list active_images ind_active est_alpha est_dist est_aspect_ratio est_fc fc kc cc alpha_c fc_error kc_error cc_error alpha_c_error err_std ex x y solution solution_init wintx winty n_ima nx ny dX_default dY_default KK inv_KK dX dY wintx_default winty_default no_image check_cond MaxIter'];
    else
        string_save = ['save ' save_name ' center_optim param_list active_images ind_active est_alpha est_dist est_aspect_ratio est_fc fc kc cc alpha_c fc_error kc_error cc_error alpha_c_error err_std ex x y solution solution_init wintx winty n_ima nx ny dX_default dY_default KK inv_KK dX dY wintx_default winty_default no_image check_cond MaxIter'];
    end
    ```

4. Save the changes.

Now, upon pressing the **Save** button in BCT's GUI, the extrinsics for the non-calibration image will also be saved in the `Calib_Results.mat` file (if they exist). The rest of the procedure continues as normal.

### **Why even do this?**

The **Comp. Extrinsic** function of BCT is useful if the stationary camera and mirrors assumption is violated, e.g., you move the setup around after calibration, or perhaps you calibrated the cameras in a larger space and are now moving to a more restricted/expansive space where the original checker is either too big or too small and you need to change the checker grid or square size.

However, be cautioned that this remains largely untested on our end and the results might not be accurate or even unpredicatable in some cases.

## **2. Calibrating Just the Camera View and Skipping the Rest**

Hypothetically speaking, if this is possible, calibration need only be performed once on the actual camera, and then we can replicate the intrinsics and distortion coefficients for the mirror views. The only thing left is to compute the reference extrinsics, for which we can:

1. Save camera calibration results as `Calib_Results.mat`, clear workspace, reload them in, and run `calib_gui` to bring up BCT's GUI.

2. Choose any image from the camera's calibration set or any non-calibration image with a checker visible in all views to serve as the reference

3. Click **Comp. Extrinsic** and enter the selected image's name. This will bring up a figure window.

4. Mark the four extreme internal corners of the checker in the reflected view.

5. Enter the square dimensions on the checker. This will compute the extrinsics as `Rc_ext` and `Tc_ext` in the workspace.

6. Type the following into the command window:

    ```matlab
    save('Calib_Results_mir1.mat', 'KK', 'kc', 'Rc_ext', 'Tc_ext')
    ```

7. Repeat Steps 3&ndash;5 for the second mirror, and then run the following command:

    ```matlab
    save('Calib_Results_mir2.mat', 'KK', 'kc', 'Rc_ext', 'Tc_ext')
    ```

8. ***If*** the chosen image is a non-calibration image, repeat Steps 3&ndash;5 for the camera view as well. ***Else***, the extrinsics are already computed in the form: `Rc_{image-number}` and `Tc_{image-number}`, so just rename them to `Rc_ext` and `Tc_ext`.

    ```matlab
    save('Calib_Results_cam.mat', 'KK', 'kc', ;Rc_ext', 'Tc_ext')
    ```

9. Proceed as usual with merging the three (or two, if you have one camera + one mirror) together as documented in Step II of the main repo `README.md`.

This is something we have slightly tested as it greatly reduces user input, but in certain cases, the results were unpredictable and BCT would sometimes fail to compute extrinsics correctly in the mirror view (the reprojections would be erroneous in some cases). This might have to do with the fact that mirrors introduce some level of distortion themselves, and that the nature of this distortion changes between mirrors. However, more testing is needed before we can reach a definitive conclusion.
