# **Capturing High Speed Maneuver Using a Single Camera and Planar Mirrors**
## **3D trajectory of a house fly**
<p align="center">

https://user-images.githubusercontent.com/65610334/219969936-50a58624-09f1-4622-a556-aaebb1ca4a04.mp4

</p>

## **3D Trajectory of housefly motion**

https://user-images.githubusercontent.com/65610334/220006204-c71db125-1126-49a2-8c42-0c8fd955cb00.mp4

**
**

#  **Capturing multiple views of high rate manervers using a single high speed camera and planar mirrors**

## **Dragonfly**
https://user-images.githubusercontent.com/65610334/218671910-4910fe86-2c61-4224-9f2b-d1678b5d4f65.mp4

## **Housefly**
https://user-images.githubusercontent.com/65610334/218388649-2074825e-5431-46ce-885d-7af7965979b4.mp4

## **Butterfly**
https://user-images.githubusercontent.com/65610334/218389932-b286dba1-9ee0-41da-a107-09850fb4c078.mp4

# **Calibrating the Single Camera and Planar Mirror Setup** 
https://user-images.githubusercontent.com/65610334/218727506-319f85d8-ba39-4e11-bd70-6d51133d2fb6.mp4

# **Verifying Poses With Epipolar Geometry** 
https://user-images.githubusercontent.com/65610334/218727782-d6a6874e-0c80-4d60-8977-12ac89a087ab.mp4

# **System Requirements**

This **toolbox works on Matlab 5.x and Matlab 6.x** (up to Matlab 6.5) on **Windows, Unix and Linux systems** (platforms it has been fully tested) and does not require any specific Matlab toolbox (for example, the optimization toolbox is not required). The toolbox should also work on any other **platform supporting Matlab 5.x and 6.x**.
***
# **Getting Started**

If you are new to the **camera calibration toolbox**. Go to the following website http://robots.stanford.edu/cs223b04/JeanYvesCalib/ and try the first few examples to get to know about **camera calibration**.This  is **highly recommended** for someone who is just starting using the toolbox. 

## **Calibration Dataset Collection**

The following section **explains** how to setup the system for **capturing multiple views** using a **single camera fixed** on a tripod. In the figure below, we show the **mirror container, the tripod, and the light source** we have used to capture our **images**.

![w11](https://user-images.githubusercontent.com/65610334/213187130-b907fcc0-bced-43c0-99a9-ee44dae10d69.PNG)

- **Print a checker pattern and measure the dimensions (x and y) of any one square on the chessboard.**

![ch Diagram](https://user-images.githubusercontent.com/65610334/213092640-4103b6af-ab70-4ce6-b13a-1a96a0c0a437.jpg)

- **Place the camera on the tripod and place it at a suitable distance from the mirror setup/container.**

![w43](https://user-images.githubusercontent.com/65610334/213187833-99e95ccb-4358-4e17-a54e-be245f93dc82.PNG)

- **Place the chessboard in the mirror container and make sure it can be seen in all three views.i.e original and both the mirror view.** 
***Note: Camera stand and mirror setup should not move throughout the process.***

![m1](https://user-images.githubusercontent.com/65610334/213096148-a47db345-14b7-4b3e-9a0d-8ad0de3f9e05.PNG)

- **Change the position of the chessboard in a limited region to ensure that the pattern can be seen in all views, i.e., the original and both the mirror views, and capture an image.**
- **Repeat the above steps to capture at least 15-20 images of the checker pattern at different positions.**
 
![Images](https://user-images.githubusercontent.com/65610334/212243538-0619adad-a8d8-41ab-a801-c1aee23537e4.png)

## **Calibrating the Original View**

This section explains how to use the **Camera Calibration Toolbox for Matlab** to calibrate the original set of images. We go through all the relevant features of the toolbox step-by-step for our purposes below.

### **1. Gathering Calibration Images**

1. Download the calibration images all at once from the following link https://github.com/Asad127/3D-RECONSTRUCTION/tree/main/Dataset or one by one, and store all the images into a seperate folder named **calib_data**.
2. From within MATALB, go to the folder **calib_data** containing the images. 
3. Click on the **Image Names** button in the camera calibration tool window (GUI) and go through the prompts for the image basename and format.

![W1](https://user-images.githubusercontent.com/65610334/213086588-19a14b08-0927-40a4-9096-24c3c581bcc0.png)

4. After clicking on the Image names button, the following output will be displayed in the command window in which you have to enter the basename of the image and the type of format.

![c1](https://user-images.githubusercontent.com/65610334/213191810-6f565d40-7329-431f-b4e6-2a7110305909.jpg)

5. After completing the above steps, the following **output** (a mosaic of the images) will pop up.

![Calibration Images](https://user-images.githubusercontent.com/65610334/212247154-20bdaa4c-e473-4a52-afed-8535061711e3.png)

### **2. Extract the Grid Corners**

1. Click on the  highlited button of **Extract Grid Corners** in the calibration GUI.

![W1](https://user-images.githubusercontent.com/65610334/212662591-9ce4ac12-9114-4fb6-8b8c-e9792c70e7bb.png)

2. After clicking on the highlighted button of **Extract grid corners**, it will ask about the window size and automatic square counting mechanism.

![c2](https://user-images.githubusercontent.com/65610334/213191980-d15f847a-52db-4f7a-9357-22a4f2dfc577.jpg)

3. The accompanying **output** will appear after step 2 is completed. 

![Calib1](https://user-images.githubusercontent.com/65610334/212251855-ccf59d9a-ce84-41ec-8a53-35a0da8d8b96.jpg)

#### **Clicking Order for Extreme Internal Corners** 

The first clicked point is **selected** to be associated to the origin point of the world reference frame attached to the grid. The **second** click defines the direction of the **Y-axis** of the reference frame from **(1st click ---> 2nd click)**. The **third** click defines the direction of the **X-axis** of the reference frame **(2nd click ---> 3rd click)**. The fourth click will complete the **plane's definition**, and the toolbox will proceed to **compute** the corners.

> NOTE: As you mark the points in each image, note the clicking order. We will need it to associate the reflected points properly when calibrating the mirror images.

We **illustrate** the clicking order that we followed for our calibration below.

![asddddd](https://user-images.githubusercontent.com/65610334/213100379-beb1dad9-47d7-47b4-bd3b-30200bd67aef.png)

The **planar boundary** of the calibration grid is then shown below.

![bd](https://user-images.githubusercontent.com/65610334/212264520-26a30d6e-2eff-41bc-867e-8f561fecaf16.jpg)

After marking the **four extreme corners**, the toolbox prompts for the dimensions of the **squares on the chessboard pattern**. Here, you enter the values measured earlier.

![c3](https://user-images.githubusercontent.com/65610334/213192408-17ee514f-5aba-438a-b2fb-a141242d8d5b.jpg)

The **tooblox** first guesses the **corner locations**, and then refines them to subpixel accuracy.

![corners11](https://user-images.githubusercontent.com/65610334/212265637-e70c9ba5-b7da-4542-bac6-321273b4a3c2.jpg)

![extraxted corners](https://user-images.githubusercontent.com/65610334/212265827-fec020ae-8599-48cf-b542-401dc5c90dc8.jpg)

**Follow the same procedure for the rest of images in the dataset. For the rest of the images, you will only be prompted for an initial guess for distortion.**

After **corner extraction**, the matlab data file `calib_data.mat` is automatically generated. This file contains all the information gathered throughout the corner extraction stage (image coordinates, corresponding 3D grid coordinates, grid sizes, etc.).

![h55](https://user-images.githubusercontent.com/65610334/213192784-ebcafe65-982a-46ba-b996-1acfb174a7dc.PNG)

### **3. Main Calibration Step**

After **corner extraction**, click on the button **Calibration** on the calibration GUI to run the main camera calibration procedure.

![WRR](https://user-images.githubusercontent.com/65610334/212663304-28278a91-0cbf-4638-91e2-a679576e44ff.png)

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

The calibration parameters are stored in a number of variables in the workspace.

### **4. Reprojection Using Estimated Camera Parameters** 

Click on **Reproject on images** in the calibration GUI to show the reprojections of the grids onto the original images. These projections are computed based on the estimated intrinsic and extrinsic parameters from the calibration step.

![W3](https://user-images.githubusercontent.com/65610334/212663501-41912859-477e-4ced-8a0d-e7fd0082a60d.png)
  
    Number(s) of image(s) to show ([] = all images) to indicate that you want to show all the images:
    Number(s) of image(s) to show ([] = all images) = []

The **following figures** shows the  **four images** with the detected corners (red crosses) and the reprojected grid corners (circles). 

![Asad](https://user-images.githubusercontent.com/65610334/212270143-6e7e929a-3dee-4e6a-903a-d3b5ce15f6cf.jpg)

    Number(s) of image(s) to show ([] = all images) = []
    Pixel error:      err = [0.23942   0.24756] (all active images)

The reprojection error is also shown in the form of **color-coded crosses**, as shown in the figure below. 

![error11](https://user-images.githubusercontent.com/65610334/212270799-077fa4b1-0888-40b4-b471-e7cf41e0760e.jpg)

### **5. Plot the Camera and Chessboards in 3D Space**

Click on Show Extrinsic in the Camera calibration tool. 

![W2](https://user-images.githubusercontent.com/65610334/212663777-fa2082bb-9bd2-4e5c-8ff5-215286a4739c.png)

This will plot the **camera and chessboards** using the estimated extrinsics from the calibration step, as shown in the figure below. On this figure, the frame (Oc, Xc, Yc, Zc) is the camera reference frame. The red pyramid corresponds to the effective field of view of the camera defined by the image plane.

![extrrr](https://user-images.githubusercontent.com/65610334/212271252-c6ea1ed7-6e7b-4539-b9c6-5a6faf816d34.jpg)

 To switch from a **"camera-centered" view to a "world-centered"** view, just click on the **Switch to world-centered view** button located at the bottom-left corner of the figure.
 
![ww](https://user-images.githubusercontent.com/65610334/212271620-ba55ff88-e193-4bd2-9fcd-66547ce13fa1.jpg)

### **6. Saving the Calibration Results**
Click on the highlighted button of **Save** on the calibration GUI.

![W2](https://user-images.githubusercontent.com/65610334/213089098-8d0d4f67-8d9c-44df-b708-bc5984c4499f.png)

The **toolbox generates** two files:
- `Calib_Result.mat` : The workspace containing all the calibration variables involved in the process. 
- `Calib_Result.m` : A script containing just the estimated intrinsics of the camera and extrinsics of each image in the calibration set.

### **7. Extracting the Parameters Required for 3D Reconstruction**

We need only a few variables from the full workspace for 3D reconstruction. Assuming we kept the reference image as the kth image of the calibration set (`k = 1,2,3,...`), then we need only the following variables from `Calib_Result.mat`:

- Camera Intrinsics (`KK` -- `3x3` intrinsics of the camera)
- Rotation (`Rc_k` in toolbox -- `3x3` orientation of the camera relative to world frame in reference image)
- Translation (`Tc_k` in toolbox -- `3x1` translation of camera center relative to world frame in reference image)

Save these variables into a new file `original_params.mat`. This file has only three variables. Open it, and rename them as follows.

- `KK ---> KK_1` 
- `Rc_k ---> Rc_1` 
- `Tc_k ---> Tc_1`

If the calibration set had 15 images and the 15th was the chosen reference, it would be `Rc_15` in the toolbox workspace. Our reconstruction script assume the reference R and T are subscripted 1 for original view and 2 for mirror view, so we need to rename them. 

##### **Reference Image Assumptions**

For reconstruction on test images later on, we need a reference for the world frame and a pose for the camera relative to that frame. We assure that the **camera does not move between image captures**, so that the camera pose relative to the reference world frame remains the same for both the calibration images and the images we take at test time.

The **calibration process estimates** the camera pose (rotation R and translation T) for each image in the **calibration set**. These poses can be viewed in the `Calib_Result.mat` file. In light of this, we capture an image of the chessboard in a **flat position** to serve as our world reference for the **camera's pose** during reconstruction of other test objects. During **calibration**, this image is also included in the **calibration set**, so we already have access to its pose (R and T).

In our work, we add the **reference image** as the last image of the **calibration** set for our own ease, but you can just as easily keep the first image as a reference. We prefer a **flat position** because it makes the most geometrical sense for our setup. 

>**NOTE:** In the event the assumption of a fixed camera is violated, the camera's pose must first be estimated using some algorithm like Perspective-n-Point (PnP). If the new position still has a view of the chessboard, the toolbox's `Comp. Extrinsic` function can be used as well.

## **Calibrating Mirror View**

This section explains how to **calibrate the mirror** view using the reflection of the **chessboard in the mirrors**. The procedure is exactly the same as described for the calibraiton of the original view. The only thing that is different is the **clicking order** because, in the mirror, the points are **reflected**. 

### **1. Gathering Calibration Images**

Just copy the same set of *8calibration images** from the calibration of the original view into a separate folder **calib_data_reflected**. It is important to keep this set in a separate folder. The rest of the procedure for this step remains the same.

![Calib1](https://user-images.githubusercontent.com/65610334/212251855-ccf59d9a-ce84-41ec-8a53-35a0da8d8b96.jpg)

### **2. Extracting the Grid Corners**

The only change in this step is the **clicking order**, and that the points must be marked in the mirror reflections of the chessboard. Everything else remains the same.

#### **Clicking Order for Extreme Internal Corners** 

We visually explain the **reflected clicking order** in the mirror images below. Note that the clicking order here depends on the clicking order from when the original set was calibrated.

- **The 1^st^ point which is the origin in the mirror view is the reflected version of the 1^st^ point clicked in the original view.**

 ![q1](https://user-images.githubusercontent.com/65610334/213103299-0d84a03f-df85-4905-ae81-a4593c1b468b.png)

- **The 2^nd^ point in the mirror view is the reflected version of the 2^nd^ point clicked in the original view.**

![q2](https://user-images.githubusercontent.com/65610334/213103667-cbc71cc0-1f07-4626-9380-795f8a7eef3b.png)

- **The 3^rd^ point in the mirror view is the reflected version of the 3^rd^ point clicked in the original view.**

 ![q3](https://user-images.githubusercontent.com/65610334/213103941-cbd1bdbd-d32e-4bcb-8b93-3dfaaf59e7f0.png)

- **The 4^th^ point in the mirror view is the reflected version of the 4^th^ point clicked in the original view.**

 ![q4](https://user-images.githubusercontent.com/65610334/213104939-e41129f9-e726-4329-b810-3d7503ce9821.png)

- After the fourth click, the planar boundary of the **calibration grid** is then shown in a separate figure.

![BBIMAGES](https://user-images.githubusercontent.com/65610334/212285450-3e0ecadc-eb91-4ae3-a029-32efa048535f.jpg)

- After marking the four extreme corners, the toolbox prompts for the dimensions of the squares on the chessboard pattern. Here, you enter the values measured earlier. This is only done for the first image in the calibration set.

![c3](https://user-images.githubusercontent.com/65610334/213192408-17ee514f-5aba-438a-b2fb-a141242d8d5b.jpg)

- The tooblox first guesses the corner locations, and then refines them to subpixel accuracy.

![casaasaa](https://user-images.githubusercontent.com/65610334/212286733-16bbf630-b0c9-4b64-ad22-22fe9e80503e.jpg)

![extracted acdcc](https://user-images.githubusercontent.com/65610334/212286285-18da988a-4855-4b63-885e-e1035fa1f071.jpg)

**Follow the same procedure for the rest of images in the dataset.**

### **3. Main Calibration Step**

The main calibration step for the mirror view is the **same** as described for the **original view**.

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

### **4. Reprojection Using Estimated Camera Parameters**

This procedure is also the **same** as in the **original view**.
![Unadsm](https://user-images.githubusercontent.com/65610334/212606564-7dcd28b3-393d-4c4e-9730-6ce153e7e08f.jpg)

    Number(s) of image(s) to show ([] = all images) = []
    Pixel error:      err = [0.23616   0.25538] (all active images)

![r5](https://user-images.githubusercontent.com/65610334/212606286-b63e08bc-d689-41c8-81f0-7d249d653b8b.jpg)

### **5. Plot the Camera and chessboards in 3D Space**

Again, the process remains the same as discussed in the original view.
![3d](https://user-images.githubusercontent.com/65610334/212606407-4e0ecebd-f88a-4601-be5e-90e711b6797d.jpg)

![3d2](https://user-images.githubusercontent.com/65610334/212606469-06ea4d63-1fd7-4d36-91d9-511b0091f3a8.jpg)

### **6. Saving the Calibration Results**

Repeat the same procedure as in the original view calibration to save the calibration results.

### **7. Extracting the Parameters Required for 3D Reconstructions**

Again, we only need the intrinsics (`KK`) and the extrinsics (`Rc_k` and `Tc_k`) from the `Calib_Result.mat` file generated from the calibration. We **MUST** use the same image we selected as reference for the original view as the reference image for the mirror view. So, if we selected the 12^th^ image as the world reference for test images from the original view, we will also select the 12^th^ image from here as our world reference for test images in the mirror view. 

Save these variables into a new file `reflected_params.mat`. This workspace has only three variables. Open it, and rename them as follows.

- `KK ---> KK_2` 
- `Rc_k ---> Rc_2` 
- `Tc_k ---> Tc_2`

## **Merging the Original and Mirror Camera Parameters**

For reconstruction, we have separated the pose for the reference image and the intrinsics for each view:

- `original_params.mat` 
- `reflected_params.mat`

Now, we need to merge them into one file for the reconstruction script:

1. Open both the original and reflected .mat files to load them both into the MATLAB workspace
2. Save the workspace as `merged_params.mat`

The merged workspace has six variables:
- `KK_1`, `Rc_1`, `Tc_1` corresponding to the original view intrinsics and world reference pose
- `KK_2`, `Rc_2`, `Tc_2` corresponding to the mirror view intrinsics and world reference pose

![merout](https://user-images.githubusercontent.com/65610334/212697559-11b17a6a-50d7-4ae4-ba68-1dae61a465c6.PNG)

***
# **3D Reconstruction of Different Objects**

You can remove the calibration checker pattern at this stage if you want to. It is no longer needed.

## **1. Gathering Test Images**
Place the object you want to reconstruct in the calibrated region, and make sure its features are clearly visible in both the calibrated mirrors. Capture as many images as you want with the test object in various positions, making sure the camera remains in the same position as during calibration. Finally, make exactly **one copy** of each captured image, so that there are two images for each scene. The idea is to use the copies for working with the mirrored views later.

The **naming** of these image files is important. The basename should be the same (we use 'Image') followed by a natural number. To keep things simple, we use odd numbers for original views and even numbers for the reflected view copies, and assume that the pairs are arranged consecutively i.e., image 1 is paired with image 2, image 3 with image 4, and so on. This provides a quick way of working with any pair of images.

An example test image is given below. Note how all the dots are visible in both the reflection and the original object.

![Image2](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)

## **2. Corresponding Points for Desired Objects**

Now, we need to extract some **corresponding 2D points** (pixels) from the original and reflected view of the object in the test image(s). We have created the script `point_marker.mat` to manually click and store the pixels corresponding to the object's features in any given image pair. 

Simply place the script next to the image(s) from the earlier sub-section and proceed with the steps below. 

>**NOTE:** We will be reconstructing the 3D coordinates using these 2D points, so it is important to ***mark them accurately.***

### **SCRIPT: `point_marker.mat`**
1. Open the script and check the value of `npoints`. This is a user parameter - set its value to however many points you want to mark in the image.
2. Run the script and select the pair of images you want to work with. E.g., `[1 2]` or `[3 4]`. Remember, odd is original, even is reflected, and we arranged pairs as consecutive numbers.
**NOTE:** The script currently only supports only one pair of images, so `[1 2 3 4]` is not a valid input, and neither is `[1 2 3]`. 
3. An image will pop up. Here, mark exactly `n` points on the **original view** of the object you want to reconstruct by clicking on them.

![py1](https://user-images.githubusercontent.com/65610334/213213561-f5757cc8-46fa-4016-9d2e-0c69e5ac1575.jpg)

3. After marking exactly `n` points, another image window will open. Here, you must again mark `n` corresponding points in the **mirror view**. 

![py2](https://user-images.githubusercontent.com/65610334/213213952-476fc2f0-96d1-4b48-a57b-4a82aea61f0a.jpg)

**NOTE:** Mark the points in the *same physical order* as in Step 2 and make sure to click on the *reflected* point (i.e., if you marked the top-right corner as the first pixel in Step 2, you must mark the top-left corner in the reflected view).
4. Once the correspondences are marked, the script will generate a `marked_points.mat` file containing two variables:
    - `npoints`: An integer describing the number of points marked.
    - `xj`: The pixel locations of the marked points in both the views.

The corresondence between the two views is visualized in the figure below.
![ddd Diagram](https://user-images.githubusercontent.com/65610334/212617135-aa878f26-fa2d-4e7f-841a-9f663eefbc5b.jpg)

#### **Output Details**

For two-view correspondence over `n` points, 'npoints' is the number of marked points and `xj` is a `2 x 2n` matrix. The two rows represent the `x` and `y` pixel coordinates. The columns `1 : n` are the points marked in the original view and columns `n + 1 : 2n` are the reflected corresponding points, marked in the mirror view.

The pixel location in **column 1** of `xj` (i.e., first marked point in the original view) *corresponds* to the pixel location in **column `n + 1`** (i.e., first marked point in the mirror view). Similarly, the second pixel in column 2 corresponds to the reflected pixel at `n + 2`, and so on. In general, the pixel in column `k` such that `k <= n` corresponds to the pixel in column `n + k`. Each of these pixel correspondences represents a single physical point in the world. We can then use `xj` by appropriately slicing it to select the pair of corresponding points points we need for reconstruction.

For the images attached below, we have attached a picture of the generated `marked_points.mat` file (you can view them in `Marked 2D points/P4.mat`):
- `npoints = 140`
- `xj = 3 x 280`
 
![c6](https://user-images.githubusercontent.com/65610334/213194210-e5b9e24d-f35f-4e42-bc95-9b08ea01684c.jpg)

> **NOTE 1:** `xj` is named so after the variable names in the projection equation `x = K * [R T] * X`, where `x` is the pixel projection of `X`. The `j` is to indicate that it contains the pixel locations over all the different views.

> **NOTE 2:** While we mark a total of `2n` pixels over two images in this step, we are actually only dealing with `n` real-world points. They are just projected to two views. If we had k views, we would have a total of `k * n` points.

## **3. 3D Point Estimation and Reconstruction**
By now, we have the poses, the intrinsics, and the 2D corresponding points for both views. We are finally ready to begin reconstruction of the object's physical points in 3D world coordinates. The script `reconstruction_3d.m` performs the reconstruction process.

1. Open the script `reconstruction_3d.m` in the matlab editor.
 
![ad11](https://user-images.githubusercontent.com/65610334/213199025-5e8f5595-66dd-43ba-9335-c39fd6a8baf6.png)

2. Make sure you are in the folder where you have your test images, 2d corresponding points, and merged parameters(Camera matrix for both views).
3. In our case, the **2d corresponding points** are saved in the `P4.mat` file and the camera matrix for both the original and mirror view is saved in `merged_params.mat` file.
4. The base name for the test image is Image and the format type is .jpg.

![zxz](https://user-images.githubusercontent.com/65610334/213201137-bab0767b-1e16-4fcd-84e5-54f610a3f22d.PNG)

5. Now run the script and enter the which images to use.

![cv](https://user-images.githubusercontent.com/65610334/213202476-aafacd94-288b-4258-b422-6c6d12ef0e85.png)

6. After entering which images to use, press enter and the following outputs (2D reprojections, 3D reconstruction, and optionally an error histogram) will pop up.

 ![R4](https://user-images.githubusercontent.com/65610334/212618909-913d524c-792e-44d0-b6eb-37a7c7d00d78.jpg)
***
 ![untitl211221ed](https://user-images.githubusercontent.com/65610334/212619094-96753fd8-5b20-4c7d-8798-07dada5a0c29.jpg)
***
![R4_Hist](https://user-images.githubusercontent.com/65610334/212619373-74e057af-ee18-4eb2-b671-9f77acc565dc.jpg)

Now you are **done** with your **3d reconstruction**. You can try different objects for yourself for **3d reconstrcution using single camera and mirror setup**.

> **NOTE:** We have provided the marked 2d points of different objects for 3d reconstruction in the marked points folder. You can use them to test out the reconstruction.
***

# **Epipolar Verification of Poses**

The script requires a proper folder structure. 

```
Epipolar_Verification
│   epipolar_geometry.m
│
├───results
│   └───set_1
│           epilines_in_original_view.png
│           epilines_in_reflected_view.png
│           fun_and_plds.mat
│
└───test_sets
    └───set_1
        │   merged_params.mat
        │
        └───images
                1.jpg
                2.jpg
```

In the `test_sets` folder, you can place your two test images and their poses (`merged_params.mat`) within subfolders (to facilitate multiple test sets). The test images for each set should be in a folder named “images” and should be named `1.jpg` (**original view**) and `2.jpg` (**reflected view**).

If you only want to test one set, you can directly put the images folder and pose file into the `test_sets` without subfolders and enter a blank (hit enter without typing anything) when prompted by the script. 

```
...\test_sets
│   merged_params.mat
│
└───images
        1.jpg
        2.jpg
```

### **SCRIPT: `epipolar_geometry.m`**

After setting up the test set, run the script:
1. In the first prompt, enter the name of the subfolder containing the images folder and the pose file. Leave blank and hit enter if directly placed into the test_sets folder.
```
****************************************
          RELATIVE DIRECTORIES          
****************************************
TEST IMAGES AND POSES	test_sets
ALL THE RESULTS		results

[PROMPT] Enter the directory containing the images folder merged_params.mat file (from calibration): set_1
```

2. In the second prompt, enter the number of corresponding points you would like to mark. For n points, you will have to mark 2n corresponding point pairs (set of n points in each view).
```
[PROMPT] Enter the directory containing the images folder merged_params.mat file (from calibration): set_1
Calculating fundamental matrix... DONE.

Entering point-marking mode...
	[PROMPT] Enter the no. of points to mark: 4
```
3. A figure window will pop up named “Original View.” Mark n points in the original (non-reflected) view here.
```
>> Mark points in original view...1...2...3...4... DONE.
```

![marked_points_original](https://user-images.githubusercontent.com/94681976/218799351-e5e66615-c10d-4d4b-836f-84cf157b94bb.png)

4. After marking n points, another figure window will pop up named “Reflected View.” Mark the n corresponding points in the reflected view here.
```
>> Mark corresponding points in reflected view...1...2...3...4... DONE.
```

![marked_points_reflected](https://user-images.githubusercontent.com/94681976/218799326-cebf85aa-49d0-439a-b45b-2e6e0d4bc17a.png)

5. The script will now plot the resulting epipolar lines and calculate their accuracy in terms of corresponding point to epipolar line distances (in pixels). After saving these outputs inside `results` to a subfolder with the same name as the test set folder, the script terminates after printing the following.
```
Exiting point-marking mode.

Calculating the epilines for the marked points... DONE.
Plotting the results and calculating the point-epiline distances...
	>> Saving results to "results/set_1"... DONE.
	>> Average Point-Line Distance Over Both Views: 1.60841911
[NOTE] You may view the results in the respective folders. Terminating.
```

You can view the results for the sets at any time within the designated results folder: 
- Image with epipolar lines in the reflected view corresponding to original points (using the fundamental matrix as is)

![epilines_in_reflected_view](https://user-images.githubusercontent.com/94681976/218801942-22c9af75-1bf4-47e1-be4d-86b7df8375d6.png)

- Image with epipolar lines in the original view corresponding to reflected points (transpose of fundamental matrix)

![epilines_in_original_view](https://user-images.githubusercontent.com/94681976/218802025-9e487d3d-4965-4b60-8451-62d7efaaddbc.png)

- A .mat file with the fundamental matrix and point-line distances

<p align="center">
  <img src="https://user-images.githubusercontent.com/94681976/218797107-ceef1def-4c9d-417f-be16-9cfb4886313b.PNG">
</p>

The script works will replace old results for a test set with the same, so either name the test sets differently or save separately before running the script again.

> **NOTE:** Since the corresponding points are marked manually, there is always some **human error** involved. Particularly, if the image resolution is high, even a slight offset can produce a seemingly large point-line distance (2-3 pixel distances even when the reprojection error is extremely low). However, in our experience, descriptor feature extractors like SIFT are not very good for this task of matching corresponding points, so the manual approach remains the most convenient method.

***
# **Detailed Explanation of 3D Reconstruction**

At its core, our approach to the problem of reconstruction is to think of it as an optimization problem. We presume that a fairly accurate solution for the depth (Z-coordinate) of each 2D point (pixel) on the object exists, given any two views of the object. The two views apply the constraint that the two rays from the camera centers to the object point in 3D space will intersect at that object point, which is at some depth Z.

Now, since there is only one world reference frame, the same 3D world points must project to two different pixel locations on the two cameras. We already know these pixel locations -- we marked them just now! Therefore, all we really need to do is figure out the choice of 3D points for which the forward projection (i.e., pixel projection `x = K * [R T] * X`) of both the views is correct (i.e., the reprojection error in both images is collectively minimized). 

Like with other optimization problems, we start with a wild guess for the world coordinates `X`, calculate the reprojection error, and update our guess accordingly. We settled on the mean squared per-pixel reprojection error.

### **SCRIPT: `reconstruction_3d.m`**

Before you run the script `reconstruction_3d.m`, open it and set the following according to your preferences.

1. Set the value of `org_dist` if you have a regular repeating pattern for error histogram (otherwise it is not needed).
2. Set **optimizer options**.
3. Make sure your images names match the ones in the script, otherwise `imread` will fail to load them.

Our **optimizer options** were as follows:

    options = optimoptions('lsqnonlin', 'display', 'off', 'MaxIter', 500, 'MaxFunEvals', 6.240000e+05)
    options.Algorithm('levenberg-marquardt')

Now, run the script. The script's execution can be divided into three main parts, each one discussed at length below.

#### **1. Initialization**

1. Load the following .mat files created earlier:
    - `merged_params.mat` 
    - `points_x_nimo_column.mat`
2. Input which pair of images you want to work with e.g., `[1 2]`, etc.
3. Define the total number of views and number of images based on user input.
4. Assign the pose and intrinsics from `merged_params.mat` into slice friendly variables.

#### **2. Optimization With `lsqnonlin`**
The optimization is done on a per-pixel basis. Note 2D points and pixels are used interchangeably.

1. Initialize:
    - Initial guess for 3D world points as a homogenous vector of ones `X_init = ones(4, 1)` 
    - Array of zeros to store estimated homogenous 3D coordinates against each pixel `X = zeros(4, npoints)`. For each estimated 3D point in the optimize step, the corresponding column of this matrix is updated.
    - Array of zeros to store the pixel projection of the same physical point in each of the two views `xpp = zeros(3, n_views)`. We will fill this during the optimization loop over all the pixels
2. Optimize over all pixels such that for each pixel `i`:
    - Get the pixel location in both views from xj by indexing into its i^th^ and (n+i)^th^ columns and store it in `xpp`.
    - Estimate the 3D points with non-linear least squares (`lsqnonlin`) using the ***target vectored error function*** `reconst_coords_per_px`.
    - Normalize the estimated homogenous 3D points w.r.t. the homogenous coordinate.
    - Store the result in the corresponding i^th^ column of `X`.
3. Once the optimization loop is finished, we have an estimate for the 3D points of all the `n` points we marked.

##### **Vectored Error Function `reconst_coords_per_px`**
The vectored error function takes the following as its input:
1. Which parameter to optimize over the given inputs? (`X`)
2. Initial guess for parameter to optimize (`X_init`)
3. Number of views (`2`)
4. Pixel points over all the views (`xpp`)
5. Intrinsic Matrix (`K`)
6. Rotation Matrix (`R`)
7. Translation Vector (`T`)

Here, `xpp` shows the **true pixel projections** for each view since it was assigned values from `xj`, the 2D points marked earlier. Then, using a for loop, we can slice into the relevant view's pose, intrinsics, and use the current guess for `X` to get some **predicted pixel projection** for that view. Subtracting the results from the actual pixel projection in the j^th^ column of `xpp` (the marked point in the j^th^ view), we get the reprojection error. The loop does the same thing for the other view. 

At the end, we have a vector error of just 2 elements (1 error against 1 pixel for the 2 views). The function then recurses as per the implementation of `lsqnonlin` until a threshold of error is reached or until the gradient sizes become too small (the error function plateaus).

##### **Correcting the Toolbox's Forced Right-Handedness in the Mirror Image**
Within the vectored error function, for the mirrored view (`j = 2`), we need to make sure we swap the x and y axes (the first two rows) of the world frame. This is because, as explained earlier, the calibration toolbox forces right-handedness of frames which causes the mirrored corresponding point to have a Z-axis pointing **down** instead of **up** like in the original view. This causes the x and y axes in the original view to become the y and x axes in the reflected view for the toolbox. This is clearly wrong for our correspondence, so we **must swap the axes** for the world frame of the mirrored view ourselves to ensure their swapped nature does not cause errors in the optimization against the correct framing of the original view. 

In simpler words, we are essentially aligning the axes of both the 3D world frames, so that the resulting estimation is correct. The following code snippet performs the swap for the mirrow view, given a loop over `j`.

    if j == 2
        X = [X(2); X(1); X(3); X(4)];
    end

> NOTE: `lsqnonlin` implements mean square error implicitly using the vectored error provided and calculates gradients based on their collective minimzation, so we can be sure it optimizes for both views at once.

#### **3. Result Visualization and Accuracy**

First, we **plot the pixel projections** using the estimated world coordinates (red stars) and plot them against the originally marked pixel points (blue circles). This gauges the **reprojection error**. 

Since we swapped the axes of the mirrored frame during the estimation of the world points, we need to swap them back to their original form (Z-axis down convention) before we find their pixel projections. This is because while our trick allowed it to deal with the problem by tricking the extrinsics into thinking it was being multiplied with X instead of Y and Y instead of X (as it should be if the toolbox did not force right-handedness), we have essentially ended up with a swapped version of the world coordinates that the right-handed system of the mirrored image understands. Thus, to plot them correctly, we must swap them back to their original form when plugging them into the forward projection equation.

![R4](https://user-images.githubusercontent.com/65610334/212618909-913d524c-792e-44d0-b6eb-37a7c7d00d78.jpg)

Then, we **plot the 3D world points** in 3D space to get a sense of whether the **actual structure** of the object was recovered, or if the optimizer failed to recover structure even with a small reprojection error. 

![untitl211221ed](https://user-images.githubusercontent.com/65610334/212619094-96753fd8-5b20-4c7d-8798-07dada5a0c29.jpg)

Finally, we also calculate and display a few metrics like the **mean reprojection error** over the entire set of `n` points. If we used a regular pattern, we can also plot a histogram of errors. However, this is very situational.

![R4_Hist](https://user-images.githubusercontent.com/65610334/212619373-74e057af-ee18-4eb2-b671-9f77acc565dc.jpg)
***

## **License**

**MIT**
