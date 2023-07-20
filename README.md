# **Capturing High Speed Maneuvers Using a Single Camera and Planar Mirrors**

### **Reconstructing Manually Tracked 3D Motion of Housefly**

https://user-images.githubusercontent.com/65610334/221478255-8cf1ea76-92bf-4a1c-9693-54b65a3b086c.mp4

### **Dragonfly**

https://user-images.githubusercontent.com/65610334/218671910-4910fe86-2c61-4224-9f2b-d1678b5d4f65.mp4

### **Housefly**

https://user-images.githubusercontent.com/65610334/218388649-2074825e-5431-46ce-885d-7af7965979b4.mp4

### **Butterfly**

https://user-images.githubusercontent.com/65610334/218389932-b286dba1-9ee0-41da-a107-09850fb4c078.mp4

## **Requirements**

The mirror reconstruction toolbox has been tested on MATLAB R2023a on Windows, Unix and Linux systems. It does not require any other MATLAB toolbox, except for the Computer Vision Toolbox for plotting the camera view in the reconstructed scene. The toolbox should also work on any other platform that supports MATLAB R2023a.

> The dependency on the Computer Vision Toolbox will likely be removed in the future.

# **Instructions and Tutorials**

Given below is a list of video tutorials that cover the entire process of working with and reconstructing single images from scratch:

1. [Toolbox Initialization + Project Setup + Calibrating Setup With BCT](https://youtu.be/jj8qtrYcpmg)
2. [Merging BCT Result + Image Undistortion](https://youtu.be/m7j7KHaHQjQ)
3. [Manually Marking Corresponding Points In Views](https://youtu.be/KPzqxeG_P4Q)
4. [Estimating 3D World Points + Reconstructing + Exporting Marked Points](https://youtu.be/MqHf93R815U)
5. [Verifying Extrinsics With Epipolar Geometry](https://youtu.be/clQF8QTfbyg)

> All the scripts can be called directly from the command window from anywhere after initializing the toolbox which adds it to the MATLAB path.

## **Step I: Initializing the Toolbox and Setting Up a Project**

1. Clone this repository on your computer. The cloned location is called `{cloned-repo}` in the rest of the tutorial.

2. Open MATLAB and navigate to the cloned repo.

3. Open up the `Mirror Assisted Reconstruction Toolbox` folder.

4. Run `setup_mirror_reconstruction_toolbox.m` either from the editor menu or the command window.

    ```
    >> setup_mirror_reconstruction_toolbox
    ```

    > ADD SCREENSHOT OF `Toolbox Initialization.png`.

5. Create a project in any directory by navigating to it inside MATLAB and running the following in the command window:

	```
	>> project_setup
	```

    > ADD SCREENSHOT OF `Project Setup.png`.

This should create a project in the current folder and automatically move to its root directory. In our case, this is `D:/Dev/checker/`, and we call it `{project-root}` for the rest of the tutorial. It has the following structure of files and folders:

![Project Skeleton Checker](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/702a7ec3-dd4a-4f43-a1a1-f5d8bd3b2f18)

For the coming sections, unless explicitly stated, always run commands from the project root as it contains the `defaults.mat` file necessary for our toolbox to function.

Note that in this tutorial, there are two projects: `checker` (that we just created) and `moving_checker`. The former deals with image-based inputs only, whereas the latter deals with video-based inputs. Assume that whenever the tutorial talks about a video, we are considering `moving_checker`.

## **Step II: Gathering and Importing a Calibration Dataset Into the Project**

### **1. Collecting Calibration Dataset**

The following section explains how to setup the system for capturing multiple views using a single camera fixed on a tripod and reflective mirrors present in the field of view. In the figure below, we show the **mirror container, the tripod, and the light source** we have used to capture our images.

![Experimental Setup](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1a441f87-5c4e-4080-8dd7-59c13374ca84)

1. Print a checker pattern and measure the dimensions (x and y) of any one square on the checker.

    ![Checker Pattern](https://user-images.githubusercontent.com/65610334/213092640-4103b6af-ab70-4ce6-b13a-1a96a0c0a437.jpg)

2. Place the camera on the tripod and place it at a suitable distance from the mirror setup/container.

    ![Camera To Checker Distance](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/815ef573-3669-4f71-8c0a-2b5b1987179b)

3. Place the checker in the mirror container and make sure it can be seen in all three views, i.e., original and both the mirror views.

    ![Image With Checker Visisble In All Views](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d794dc09-3ea2-4412-9865-e4e9c24b01ef)

4. Take a picture of the checker from the camera. From this point on, the camera and mirrors must remain stationary.

5. Change the position of the checker in a limited region to ensure that the pattern can be seen in all relevant views, i.e., the original and both the mirror views, and capture an image.

6. Repeat 4&ndash;5 to capture at least 15&ndash;20 images of the checker pattern at different positions. Make sure the checker's pose varies considerably between images in order to get a good calibration.

The following set is taken for 2 views (camera and left mirror).

![Calibration Images Mosaic](https://user-images.githubusercontent.com/65610334/212243538-0619adad-a8d8-41ab-a801-c1aee23537e4.png)

Note that you may also record a video in which the checker is moved around in the mirror container instead of capturing separate images. In this case, you will have to extract the frames from the video and use a suitable subset of those as calibration images. Our toolbox provides some functions for that as explained in the next step.

You can download the calibration images shown in the figure above from this repository's [`Calibration`](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/tree/main/Calibration) folder. A calibration video `calibvid.mp4` is also located in this folder.

You can place the gathered dataset anywhere on your computer.

### **2. Importing the Captured Images or Video**

1. Move to the root directory of the project created in Step I (in our example, `D:/Dev/checker/`) :

    ```
    >> calib_import_media
    ```

2. Enter whether you have calibration images (`i`) or video (`v`).

    ```
    [PROMPT] Do you have calibration images or video? ("i" = imgs, "v" = vid): i
    ```

Depending on your choice, view the relevant subsection below.

### **A. Images Route**

- (UI Browser) Locate the calibration images on your computer. Here, we import the images in the directory `{cloned-repo}/Calibration`.

	![11 Calibration Images In Repo Calibration Folder](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/374b6226-9ff0-4dc3-9b01-f1597e776a69)

- (UI Browser) Choose the folder to put the images in relative to the project's root directory, or click **Cancel** to place them in the default location `{project-root}/calibration/images/`. The script will automatically rename them in a format suitable for Bouguet Calibration Toolbox, e.g., from {img1.jpg, img5.jpg, ..., imgK.jpg} &rarr; {Image1.jpg, Image2.jpg, ..., ImageN.jpg}.

	![11 Calibration Images Imported to Project Directory](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/8deecb57-6486-4891-b6f5-92848745faec)

### **B. Video Route**

- (UI Browser) Locate the calibration video on your computer. The script will copy and auto-convert it to MP4 if it is in any other format. Here, we import the video in the directory `{cloned-repo}/Calibration/calibvid.mp4`.

	![Calibration Video in Repository](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e8e4590a-8cc0-4fae-9367-97c8849e0f98)

- (UI Browser) Select the path to save the video to within the project directory, or click **Cancel** to import it into the default location as `{project-root}/calibration/calib.mp4`. The script will then auto-run another script `calib_extract_vid_frames.m` to extract the video frames.

	![Calibration Video Imported](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f7f1c0ca-d7fb-4706-81f8-60e519c94feb)

- (UI Browser) Select the directory to extract the video frames into. Alternatively, click **Cancel** to use the default directory `{project-root}/calibration/frames/`.

- Enter the starting and stopping times for the video in HMS format when prompted. E.g., for 15&ndash;30 seconds, enter `00:00:15` for start and `00:00:30` for stop time. By default (i.e., blank inputs) the whole video is used.

    ```
    [PROMPT] Enter start timestamp in H:M:S format (blank = from video start):
    [PROMPT] Enter stop timestamp in H:M:S format (blank = until video end):
    ```

- Enter the format in which to extract the frames (by default, JPG). You may enter the abbreviation or the full extension name (e.g., "j" or ".jpg" without the quotes).

    ```
    Supported Image Formats = .jpg, .png, .tif, .bmp
    Input Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"
    [PROMPT] Enter image extension for extracted calibration frames (blank = default image extension): j
    ```

    The script will now extract the frames as {Frame1.jpg, Frame2.jpg, ..., FrameF.jpg} and auto-run `calib_select_img_subset.m`.

	![Calibration Video Extracted Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/91886e3c-8d0e-4f64-848f-019df148196f)

- Select a subset of the extracted frames to use as calibration images. These frames will be renamed in consecutive order sequetntially, so if you selected {Frame40, Frame80, Frame100, Frame180}, these would be renamed to {Image1, Image2, Image3, Image4} respectively.

	![Calbration Images From Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/29bc0ee0-464e-48c3-883f-18602e09a793)

Now we have the calibration media ready, we can begin the calibration process. The toolbox will automatically move you to the calibration directory within MATLAB so you can get started right away.

## **Step III - Calibrating Camera and Mirrors With Bouguet Calibration Toolbox (BCT)**

Download BCT from the [official webpage](http://robots.stanford.edu/cs223b04/JeanYvesCalib/) and add it to your MATLAB path to be able to use it in any directory within your computer. If you are new to the toolbox, we recommend trying out the first few examples on the webpage to familiarize yourself with the general process.

***Trying out the examples on the official webpage is highly recommended for anyone who has not used the toolbox before.***

## A. **Calibrating the Camera View**

This section explains how to use the **Bouguet Calibration Toolbox (BCT)** to calibrate the actual camera's view using a set of calibration images.

> For BCT's input prompts that have `[]` as an option, you can just leave them blank and press enter to provide an 'empty' input, which uses the default value as suggested by the toolbox.

### **1. Loading Calibration Images**

1. Assuming that BCT has been added to the MATLAB path, run `calib_gui` from the command window to launch the calibration GUI.

    ```
    >> calib_gui
    ```

2. From within MATLAB, navigate to the directory containing the calibration images created and imported in Step II. In our example, the calibration images are in `D:/Dev/checker/calibration/images/`.

3. Click on the **Image Names** button on BCT's GUI. This will display a directory listing (all files and folders in the current MATLAB directory).

<p align="center" width="100%">
    <img alt="Image Names Button" src="https://user-images.githubusercontent.com/65610334/213086588-19a14b08-0927-40a4-9096-24c3c581bcc0.png">
</p>

4. Enter the image basenames and their extension identifier (e.g., **j** for .jpg, etc.). Supposing images were named as `{Image1.jpg, Image2.jpg, ..., Image11.jpg}`, the basename would be **`Image`** (i.e., the string part without the integer identifier), and the extension in this case would be **`j`**.

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

At this point, you should be presented with the following figure (a mosaic of the calibration images). This marks the end of the image loading process.v

![Image Mosaic](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/80b19d0c-faa0-45cf-9116-93391a5ecdfd)

### **2. Extract the Grid Corners**

1. Click on the highlited button of **Extract Grid Corners** in the calibration GUI.

<p align="center" width="100%">
    <img alt="Extract Grid Corners Button" src="https://user-images.githubusercontent.com/65610334/212662591-9ce4ac12-9114-4fb6-8b8c-e9792c70e7bb.png">
</p>

2. Enter the global settings in the corresponding prompts: window size for corner finding and whether to auto-count squares along the x and y directions or manually enter them for each image. Auto-counting works reliably well - if it fails for any image, BCT will ask for manual input.

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

5. (OPTIONAL) Enter a guess for the distortion parameters, which can help with corner detection if your camera suffers from extreme distortion. However, this is empirical and you would have to fiddle around a little bit to get the right results. You may completely skip this step with an empty input.

BCT will proceed to first guess all the checker corner locations within the plane defined in Step 3, and then refine them to subpixel accuracy.

![Guessed Corners Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d32ca298-f2be-4e5c-8aa5-3e7ff3c73b80)

![Refined Corners Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f470b44c-98a7-4b66-a5b2-1165d2021a9d)

Repeat 1&ndash;5 for the rest of the calibration images. For each new image, you will only be prompted for the initial guess for distortion as the toolbox assumes a single checker pattern has been used in each image.

Once corner extraction is complete, BCT generates a file `calib_data.mat` containing the information gathered throughout the stage (image coordinates, corresponding 3D grid coordinates, grid sizes, etc.).

![Clicked Corners MATLAB Workspace (`calib_data.mat`)](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/351c6791-d1c4-42a7-8ec5-c2dceefa3944)

This is helpful to keep as it allows you to skip the corner extraction and proceed directly to Step 3 (Main Calibration Step) for any future re-calibrations.

> **Extract Grid Corners** will automatically call the image loading routine if no images are detected in the workspace. Thus, after launching `calib_gui`, you can directly click on **Extract Grid Corners** and BCT will begin the image loading process described in Step 1, immediately followed by the corner extraction prompts of Step 2.

### **3. Main Calibration Step**

Click the **Calibration** button on the calibration GUI to run the main camera calibration procedure.

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

Click the **Reproject On Images** button in the calibration GUI to show the reprojections of the grids onto all or a subset of the original images. These projections are computed based on the estimated intrinsic and extrinsic parameters from the calibration step.

<p align="center" width="100%">
    <img alt="Reproject On Images Button" src="https://user-images.githubusercontent.com/65610334/212663501-41912859-477e-4ced-8a0d-e7fd0082a60d.png">
</p>

```
Number(s) of image(s) to show ([] = all images) = []
```

The following figure shows four of the images with the detected corners (red crosses) and the reprojected grid corners (circles).

![Reprojections Mosaic Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/2aa8b843-09df-4785-949d-3b7790d97ec8)

```
Number(s) of image(s) to show ([] = all images) = []
Pixel error: err = [0.23942 0.24756] (all active images)
```

The reprojection error is also shown in the form of color-coded crosses. Each color represents a particular image, so if we decided to reproject on 4 images, we would have 4 random colors as shown in the figure below.

<p align="center">
    <img alt="Reprojection Errors Camera View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d4e2b763-fffd-4627-a71b-cb98cc01b71f">
</p>

### **5. (OPTIONAL) Plot the Camera and Checkers In 3D Space**

Click the **Show Extrinsic** button in BCT's GUI.

<p align="center" width="100%">
    <img alt="Show Extrinsic Button" src="https://user-images.githubusercontent.com/65610334/212663777-fa2082bb-9bd2-4e5c-8ff5-215286a4739c.png">
</p>

This will plot the camera and checkers using the estimated extrinsics from the calibration step, as shown in the figure below. On this figure, the frame (Oc, Xc, Yc, Zc) is the camera reference frame. The red pyramid represents the camera.

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

We only require the matfile, so rename `Calib_Results.mat` to `Calib_Results_cam.mat` to indicate that this is the actual camera's calibration. Renaming now also prevents future calibration results from replacing this one. Also rename `calib_data.mat` to `calib_data_cam.mat` for the same reason.

We are now done calibrating the first view (the actual camera).

## **B. Calibrating the Mirror View(s)**

This section explains how to calibrate the mirror view using the reflection of the checker in the mirrors (either one or two mirrors). The procedure is exactly the same as described for the calibration of the camera view (Step III-A). The only difference is the **clicking order** because, in the mirror, the points are **reflected**.

This process must be repeated carefully for each mirror view you involve. Our toolbox currently supports a maximum of two mirrors. If continuing directly from a previous view's calibration (whether a camera or mirror), remember to clear the workspace, close all figures, and restart `calib_gui` before proceeding to avoid issues with existing workspace variables.

### **1. Loading Calibration Images**

The procedure remains exactly the same as in the camera's calibration, and we can use the same images (assuming the checker is visible in the relvant mirror view).

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

After the fourth click, the planar boundary of the **calibration grid** is shown in a separate figure.

![Planar Boundary Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/30a5b99a-afba-4f91-b42b-bd7470a83596)

When prompted for the square dimensions on the checker pattern, enter the same ones used during the camera's calibration.

![Command Window With Higlighted Input Fields](https://user-images.githubusercontent.com/65610334/213192408-17ee514f-5aba-438a-b2fb-a141242d8d5b.jpg)

Just like before, the tooblox first guesses the corner locations, prompts for the distortion guess (optional), and finally refines the guesses to subpixel accuracy.

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

### **5. (OPTIONAL) Plot the Camera and Checkers In 3D Space**

Again, the process remains the same as discussed in the original view.

![Camera Centered Extrinsics (Mirror View)](https://user-images.githubusercontent.com/65610334/212606407-4e0ecebd-f88a-4601-be5e-90e711b6797d.jpg)

![World Centered Extrinsics (Mirror View)](https://user-images.githubusercontent.com/65610334/212606469-06ea4d63-1fd7-4d36-91d9-511b0091f3a8.jpg)

### **6. Saving the Calibration Results**

Repeat the same procedure as in the original view calibration to save the calibration results.

Rename the resulting `Calib_Results.mat` to `Calib_Results_mir1.mat` if this is for the first mirror, and to `Calib_Results_mir2.mat` if this is for the second mirror. The mirror numbering convention is subjective and up to you, e.g., left mirror is mirror 1, and right mirror is mirror 2, etc.

## **Wrapping Up the Calibration**

Once you have finished calibrating all the views, you should have the following files (assuming only two views as in our example &ndash; camera and left mirror):

<p align="center" width="100%">
    <img alt="Calibration Results" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/51fb8c43-3cbb-4404-b489-131f0e2dda93">
</p>

To reiterate, `calib_data_{view-name}.mat` saves the clicked corners information if you want to recompute the calibration parameters. `Calib_Results_{view-name}.mat` are the saved calibration results, including the intrinsics and extrinsics that we require for reconstruction.

You will additionally have `Calib_Results_{view-name}.m` as well, which we personally recommend deleting as it is not used in the following steps.

If you are interested in special cases or the flexibility of the visiblity and static view assumptions, view `Documentation/Calibration.md` for more details.

> You can remove the checker pattern at this stage. However, the camera and mirrors should remain stationary for the rest of the steps.

## **Step IV: Merging BCT Result and Simultaneously Converting to DLT Coefficients**

This section discusses how to merge the variables necessary for reconstruction from each view's calibration results into one mat-file. The process simultaneously computes the normalized 11-DLT coefficients form of the calibration result for each view and merges them into one CSV file.

The latter step is only relevant if you are working with videos in DLTdv8a, but this is the most reasonable time to calculate them whether you plan to use DLTdv8a or not.

1. Navigate to the project's root directory from within MATLAB. Again, in our example case, this is `D:/Dev/checker/` for images and `D:/Dev/moving_checker` for videos.

2. Run the script `calib_process_results.m` from the command window:

    ```
    >> calib_process_results
    ```

3. Enter the extrinsic reference image suffix. E.g., if calibration set was labeled {Image1, Image2, ..., Image15.jpg}, the suffixes are {1, 2, ..., 15}. This picks the corresponding extrinsics `Rc_{suffix}` and `Tc_{suffix}`, e.g., `Rc_1`, `Rc_ext`, etc.

    ```
    [PROMPT] Enter calibration image suffix to use as world reference image for extrinsics (blank = default): 3
    ```

    The default value is `1`. Needless to say, extrinsics `Rc_x` and `Tc_x` corresponding to suffix `x` must exist in the calibration results, otherwise an error is thrown.

4. (UI Browser) Locate each view's calibration file. These would normally be manually renamed in the default expected format `Calib_Results_{view-name}.mat`, though it could be any name. Clicking **Cancel** will skip that view (it won't be used in reconstruction). At least 2 views are required for this to work.

    > ADD SCREENSHOT HERE

    > For `{view-name}`, we prefer using {`cam`, `mir1`, `mir2`} for each view.

5. (UI Browser) Choose path to save the merged calibration result in the UI browser, or use the default location by pressing the **Cancel** button.

    > ADD SCREENSHOT HERE

6. (UI Browser) Choose path to save the 11 DLT coefficients for DLTdv8a that are also computed in this step, or use the default location by pressing the **Cancel** button.

    > ADD SCREENSHOT HERE

This will generate the consolidated BCT parameters file and the DLT coefficients file. By default, the merged calibration file is named `bct_params.mat` and the DLT coefficients file is named `dlt_coefs.csv`, and both of them are stored in the `calibration` folder within the project root.

<p align="center">
    <img alt="Merged BCT and DLT Coefs File" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f45ee981-23b1-4d1b-8656-2a2c06cd0759">
</p>

The merged BCT params (viewed in MATLAB workspace).

<p align="center">
    <img alt="Merged BCT In MATLAB Workspace" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/dbba8a06-0bab-4c42-857c-ffa4269cdf13">
</p>

And the DLT coefficients file (viewed in MS Excel). Note that the tags CAMERA and MIRROR 1 are not in the actual file, they were added to make it clear that the first column is the camera view's 11 DLT coefficients and the second column are the mirror view's 11 DLT coefficients.

<p align="center">
    <img alt="DLT Coefs File In Excel" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/b8d73158-14e5-44bc-ab06-2a92883d520e" height="400px">
</p>

## **Step V: Creating, Importing, and Undistorting a Test Image or Video**

This section describes how to gather testing media (images or videos) containing the target object to reconstruct. We can also optionally undistort the imported media, which is recommended to improve the result accuracy.

### **1. Creating Test Media**

Place the object of interest in the calibrated region, and make sure its features are clearly visible in all the calibrated views. Capture as many images as you want of the test object in various positions, making sure the camera and mirrors remain stationary as during calibration.

You may similarly create a video of the object instead of images.

Given below is an example of a test image located at `{cloned-repo}/Test Media/3.jpg`. A test video is also available in the same path: `{cloned-repo}/Test Media/projvid.mp4`.

![Test Image Example](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)

### **2. Importing and Undistorting Test Media**

The process to import the testing media as well as undistort it is detailed below:

1. Navigate to project root directory within MATLAB (either `D:/Dev/checker` for images and `D:Dev/moving_checker` for videos in our case), and then run `import_media.m` in the command window.

    ```
    >> import_media
    ```

2. When prompted, enter whether to import images or a video file in the command window:

    ```
    [PROMPT] Import images or video? ("i" = imgs, "v" = vid): i
    ```

### **A. Image(s) Route**

- (UI Browser) Locate the images containing the object of interest on your computer. 4 such test images are provided in the directory `{cloned-repo}/Test Media/`.

	![Test Images In Repository](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1db1c305-1773-4d97-873e-e145f322f280)

- (UI Browser) Choose which directory of the project to copy them to. Clicking **Cancel** here will place them in the project's `{project-root}/media/images/` folder by default.

	![Imported Test Image](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f7a7c5cb-033f-47b3-918a-bce08208379b)

- Enter `y` in the following prompt to begin the undistortion procedure for the imported images. Otherwise, enter `n` to finish the import process.

    ```
    NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by "calib_process_results.m".
    Undistort the imported images? (y/n): y
    ```

#### **i. No Undistortion Sub-Route**

Proceed to marking points on the image as detailed in Step VI.

#### **ii. Undistortion Sub-Route**

A UI browser should pop up. Here, locate the merged BCT calibration parameters file created earlier in Step IV, or click cancel to look for it in the default save path `{project-root}/calibration/bct_params.mat`.

> ADD SCREENSHOT HERE

> If you did not clear the workspace after Step IV and ran `import_media.m`, this UI prompt will not appear as the location is already recorded in the workspace.

Wait until all the images are undistorted w.r.t. the distortion coefficients from each view. The results are stored in subfolders named `cam_rect`, `mir1_rect`, and `mir2_rect`, created in the same directory as the original images.

<img alt="Undistorted Image Folders" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/ccb7522c-5ab1-4e61-a578-338a5c32120e" width="75%">

The undistortions are visualized below:

![Undistortion Mosaic](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e9e1798b-8395-45b0-b76a-bf80226e58bf)

### **B. Video Route**

- (UI Browser) Locate the video containing the object to be tracked on your computer. The video could be in the various formats accepted by MATLAB's VideoReader, but the import process will convert a copy of it to MP4.

	![Test Video in Repository](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6ad786d5-0cf0-442e-ab1d-e18d9fee6481)

- (UI Browser) Choose the path to import the video into. Clicking **Cancel** will place it in the default location `{project-root}/media/videos/`.

	![Imported Test Video](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/7f6baed5-41c6-4e2f-85b5-876494921175)

- When prompted to undistort the video, type `y` in the command window to begin the undistortion process. Otherwise, type `n` to skip directly to frame extraction without undistortion.

    ```
    NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by "calib_process_results.m".
    Undistort the imported video? (y/n): n
    ```

#### **i. No Undistortion Sub-Route**

- (UI Browser) Choose directory into which you wish to extract the video frames, or click **Cancel** to place them in the default directory `{project-root}/media/frames/`.

- Choose the extension of the extracted frames.

    ```
    Supported Image Formats = .jpg, .png, .tif, .bmp
    Input Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"
    [PROMPT] Enter image extension for extracted video frames (blank = default image extension): j
    ```

Assuming a total of F frames in the video, the frames are named as {Frame1.jpg, Frame2.jpg, ..., FrameF.jpg}.

![Extracted Test Video Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f0da4212-5e73-4dd1-b980-4ed6044ec4fb)

#### **ii. Undistortion Sub-Route**

- (UI Browser) Locate the merged BCT calibration parameters file from Step IV, or click **Cancel** to look for it in the default save path `{project-root}/calibration/bct_params.mat`.

    > ADD SCREENSHOT here

    > If you did not clear the workspace after Step IV and ran `import_media.m`, this UI prompt will not appear as the location is already recorded in the workspace.

- (UI Browser) Choose a directory to extract the video frames into, or click **Cancel** to place them in the default directory `{project-root}/media/frames/`.

- Select the extension of the extracted frames.

    ```
    Supported Image Formats = .jpg, .png, .tif, .bmp
    Input Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"
    [PROMPT] Enter image extension for extracted video frames (blank = default image extension): j
    ```

These frames are then undistorted with the distortion coefficients for each view and stored in new folders (one per view) in the extracted frames' directory. The folders are named after the corresponding views: `cam_rect`, `mir1_rect`, and `mir2_rect`.

<img alt="Undistorted Frame Folders" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e6ce95c5-ac3e-40b7-9416-2bebccc436fa" width="75%">

The undistorted frames are visualized below:

![Undistortion Mosaic For Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/4f2e8830-122c-4890-a6a7-780645bb164f)

Finally, these undistorted frames are stitched back into undistorted videos that are placed in the same directory as the original video with the same name, but suffixed with `{video-name}_cam_rect.mp4`, `{video-name}_mir1_rect.mp4`, and `{video-name}_mir2_rect.mp4`.

![Undistorted Videos](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/b3e4105d-8292-4655-a3f9-a09695a94c5e)

## **Step VI: Marking Points on Imported Test Media for Each View**

There are two ways to approach this. The first is to mark the points on the object of interest in a **single image** for each view manually and store the results. The second is to mark AND track the points in a **video** for each view via DLTdv8a, and then export the trackfiles. We cover both of them below.

## **A. Marking Points in a Single Image or Video Frame**

1. Run `point_marker.m` from the project root (`D:/Dev/checker` in this case) in the command window.

    ```
    >> point_marker
    ```

2. (UI Browser) Locate the test image containing the object of interest that was imported in Step V. This may be a video frame as well.

    > ADD SCREENSHOT HERE

3. (UI Browser) Locate the merged BCT calibration file created in Step IV.

    > ADD SCREENSHOT HERE

4. Enter the number of points to mark in the image. For example, if you want to mark four points in each view, enter `4` in the command window:

    ```
    [PROMPT] Enter the no. of points to mark: 4
    ```

5. When prompted to use undistorted images to mark points in the command window, enter `y` to do so, and `n` otherwise. Only enter `y` if you undistorted images in Step V.

    ```
    HELP: Only enter "y" if you have the undistorted images/video frames.
    [PROMPT] Mark points on undistorted images? (y/n): y
    ```

6. Based on inputs in Steps 2 and 5, either the original or undistorted versions of the image will open up in a figure. Here, mark exactly the number of points you entered in Step 4 by clicking on image points corresponding to the particular view. You can zoom in, out, or reset with `q`, `e`, and `r` respectively.

	![Marked Points Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/35f137d2-f87d-45ad-be45-a1c4ecafaf7d)

7. Repeat Step 6 for all views. Take care to mark points in the ***same physical order*** in each successive view after the first one so the script can correctly associate corresponding points.

	![Marked Points Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/b39bde96-0cf8-4856-ade2-46b6bd01106e)

8. (UI Browser) Choose the path to the save the results, or click **Cancel** to use the default location `{project-root}/reconstruction/marked_points.mat`.

The saved variables are:

    - `x`: A 2D array containing the marked pixel locations of all physical points in all views
    - `num_points`: An integer describing the total number of physical points marked (i.e., the input in Step 3)

The full command window output is attached below:

> ADD SCREENSHOT here

The correspondence between physical points in two different views is visualized below.

<p align="center" width=100%>
	<img alt="Point Correspondence In Two Views" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1914366b-5d18-490f-a8a0-112a88bb12d9" width="40%">
</p>

Within MATLAB from `point_marker.m`, the following is a visualization of the clicking order in the two view images:

![Marked Point Click Order Within MATLAB](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/ee2c4aea-5b0e-4b22-a358-aeda49cfc1d2)

Below, we have attached a picture of an included `marked_points.mat` file with the full set of 140 points marked; the file is located at `{cloned-repo}/Marked 2D Points/P4.mat`:

- `num_points = 140`
- `x = 3 x 280`

<p align="center">
    <img alt="Saved Marked Points File In MATLAB Workspace" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1c293ba8-6f9c-4f74-b0ae-9c768321f23b">
</p>

<p align="center" width="100%">
    <img alt="140 Marked Points Camera View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/81eee341-a29f-4606-aa0a-ed1adde1b6ac" width="48%">
	&nbsp; &nbsp;
	<img alt="140 Marked Points Mirror View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/084d7fd4-5f35-4927-bca2-01b4f1b0f326" width="48%">
</p>

## **B. Marking and Tracking Points in a Video With DLTdv8a**

Extensive video tutorials as well as written manuals on how to work with DLTdv8a are provided by the authors of the software. If you are just starting with the tool, we recommend that you start learning from the [official DLTdv8a online manual](https://biomech.web.unc.edu/dltdv8_manual/). You can also clone their [git repository](https://github.com/tlhedrick/dltdv) which contains additional information and the codebase.

***The toolbox has only been tested with the app version of DLTdv8, i.e. DLTdv8a.***

1. Open up the DLTdv8a app from the project root (`D:/Dev/moving_checker` in this case).

    ![Opening up the DLTdv8a app](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/2b0874c5-f861-4694-9d6e-972308b8f2cb)

2. Create a new project within DLTdv8a and load in the same video 2&ndash;3 times (for 2&ndash;3 views) *UNLESS* videos were undistorted in Step V &ndash; in that case load the separate undistorted videos. Video load order is important as it must correspond to the order of DLT coefficients in the CSV file (1st video uses 11 DLT coefficients in the first column of the CSV file, and so on).

    <p align="left">
        <img alt="Creating a new project" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6093dcd6-562b-4bc2-8090-cac06c520476" width = 48%> &nbsp;&nbsp;&nbsp;&nbsp; <img alt="Video Selection Context Menu" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/9f0ab121-e221-4e6c-8188-4f5bd6511042" width=30.75%>
    </p>

    ![Video Files Selection](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/5358a907-b6d6-42f3-8965-438d9ae7ed64)

3. When prompted if the cameras are calibrated, click **"Yes"** and add the DLT coefficients file generated in Step IV.

    ![DLT Prompt](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/3420c76d-c47f-4073-8579-ef6deed92700)

    ![DLT Coefs File](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/c08ffee6-b455-468c-be27-ce9a67fb4a87)

4. Create as many points as you want to track by using the **Add Point** button. Then, mark all the points in the first frame (or any frame of your choosing) for the first video.

    ![DLTdv8a Add Point Button](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e7a32039-299c-415d-9d04-b6cc9015072f)

    Notice that each marked point draws an epipolar line in the other videos for that frame. Assuming well-calibrated cameras, these are good hints for where the corresponding point is on the mirror views. Note that in the following figure, the lime-colored arrow and the green circle are not drawn by DLtdv8a, they are simply there to indicate the corresponding point on the mirror view.

    ![Mirror View Epiline In Dltdv8a Passing Through Corresponding Point](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/2e101e9c-e2b1-4e92-8b00-2489ef4ec371)

5. Mark the corresponding points ON THE REFLECTIONS of the object in the second and (if available) third videos. If a point is not visible in any view, skip marking it for that view and it will become NaN, which is expected and handled by our toolbox's reconstruction scripts. When you mark a corresponding point, a green diamond indicating the reprojected pixel location from the estimated 3D point (via SVD-based DLT triangulation) should appear assuming you provided the DLT coefficients in Step 3.

    ![Corresponding Points Marked](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/4b9cdd42-b009-4593-98cc-3619fd0d3dfa)

6. Once all the points are marked in all relevant views for the first frame (*or whichever frame, it's not a hard rule*), set the tracking settings in the DLTdv8a interface according to your project's needs and begin tracking.

    ![All Points Marked](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/de174f1c-d811-4320-9218-b1c25ee3e639)

    Our settings for this test video are provided below (they are the default DLTdv8a ones, except for `Show 2D tracks on video images`, which is set to `All`).

    ![DLTdv8a Settings For Multi-Tracking](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/871890c1-d8a7-4c0a-8b03-6f0e796f84b0)

7. Once you have a suitable tracked result, head to the directory inside MATLAB where you would like to export the trackfiles (we recommend using the directory `{project-root}/trackfiles/` to keep things organized). Then, click on the Points tab in the main DLTdv8a dialog box, and export points to begin generating the trackfiles.

    ![Tracked Result Zoomed In](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/ce10781c-0198-4f44-9e03-6e7876cecfcd)

    ![DLTdv8a Export Points Tab](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/9a96c02c-6f9f-492e-a378-23f240072008)

8. This will bring up a few confirmation boxes&mdash;the important one is that you export the points in "flat" format as the sparse format is currently not supported. You can also add a prefix to the trackfiles when exporting them, which is especially helpful if you are exporting multiple different sets of points.

    <p align="left">
        <img alt="Prefix Option" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/793c80eb-64d7-4430-b974-3740c8d9a3c9" width = 30%> &nbsp;&nbsp;&nbsp;&nbsp; <img alt="Sparse/Flat Format Export Menu" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/0d88ee59-5204-48fd-a78d-98a6b00e7cb0" width=40%>
    </p>

DLTdv8a will generate around 4&ndash;5 files in the current directory. The main trackfile that's relevant to us is `{prefix}xypts.csv`, which contains the framewise tracked 2D point (pixel) information for all views.

![Generated Trackfiles](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/662fd3f0-1dd4-459b-b275-9cd2c25ed50b)

Finally, you can optionally save the entire DLTdv8a project as a matfile (*Project Tab > Save as...*) if you wish to do more work later or keep the full state of the project.

## **Step VII: 3D Reconstruction of Marked Points**

By now, you have the poses, the intrinsics, and the 2D corresponding points in multiple views. Thus, you are ready to begin reconstruction of the object's physical points in 3D world coordinates.

Based on whether you followed Step VI-A (single image with manually marked points) or VI-B (tracked points in video file with DLTdv8a), we have two separate routes to follow since route A has an image, and route B has multiple images (video frames). However, the core functionality of both scripts is the same.

## **A. Reconstructing a Single Image**

1. Navigate to the project root within MATLAB (`D:/Dev/checker` in this case), and run the following reconstruction script from the command window:

    ```
    >> reconstruct_marked_pts_bct
    ```

2. (UI Browser) Locate the image on which you marked the points in Step VI-A.

    > ADD SCREENSHOT here

3. (UI Browser) Locate the marked points file created in Step VI-A, or click **Cancel** to use the default save location `reconstruction/marked_points.mat` in the project root.

    > ADD SCREENSHOT here

4. (UI Browser) Locate the merged BCT calibration file created in Step IV, or click **Cancel** to use the default save location, i.e., `calibration/bct_params.mat` in the project root.

    > ADD SCREENSHOT here

5. (UI Browser) Choose the directory where you want to save the results of the reconstruction, or click **Cancel** to use the default save path `reconstruction/{x}.mat` in the project root, where `{x}` is the basename of the image selected in Step 2 (basename means filename w/o extension).

    > ADD SCREENSHOT here

6. When prompted to use undistorted images for reprojections, enter `y` to do so, and `n` otherwise. Only enter `y` if you undistorted the images in Step V.

    ```
    HELP: Only enter "y" if you have the undistorted images/video frames.
    [PROMPT] Mark points on undistorted images? (y/n): n
    ```

And that's it. The script will then estimate the 3D world coordinates for each tracked point in each view using non-linear least squares (`lsqnonlin`) with the **Levenberg-Marquardt** optimization algorithm. It will then reproject pixels on to the images using these estimated coordinates, reconstruct them in 3D, plot the cameras alongside the reconstructed points, and export the results to the directory chosen in Step 5.

```
Estimating world coordinates with lsqnonlin...done.
Reprojecting using the estimated world coordinates... done.

*** ERRORS ***
Mean Reprojection Error (PER-VIEW): 0.185320, 0.246668
Mean Reprojection Error (OVERALL): 0.215994

Saved results to: D:\Dev\checker\reconstruction\test
```

<!--
![Pixel Reprojections With Estimated World Coordinates](https://user-images.githubusercontent.com/65610334/212618909-913d524c-792e-44d0-b6eb-37a7c7d00d78.jpg)
-->

The reprojections with the estimated world coordinates are visualized below:

<p align="center" width="100%">
    <img alt="Reprojections Camera View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/0c11a396-2573-4464-9807-594f2c0e3c2b" width="49%">
	<img alt="Reprojections Mirror View" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d170ce31-93da-4ff6-be1b-de386d653832" width="49%">
</p>

The 3D scene reconstruction WITH cameras present is visualized below:

![Reconstruction With Cameras Mosaic](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/45c978d4-783a-4ff7-bbd6-fff7fff9a009)

The 3D scene reconstruction WITHOUT cameras present is visualized below:
![Reconstruction Without Cameras Mosaic](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/717fe70c-4d97-4ffc-a35f-d3bb66e92ed3)

<p align="center" width="100%">
    <img alt="Error Histogram" src="https://user-images.githubusercontent.com/65610334/212619373-74e057af-ee18-4eb2-b671-9f77acc565dc.jpg">
</p>


## **B. Reconstructing Multiple Video Frames From DLTdv8a Trackfiles**

1. Navigate to the project root within MATLAB (`D:/Dev/moving_checker` in this case) and run the followign reconstruction script from the command window:

    ```
    >> reconstruct_tracked_pts_bct
    ```

2. (UI Browser) Locate the merged BCT calibration file created in Step IV, or click **Cancel** to use the default save location `{project-root}/calibration/bct_params.mat`.

3. (UI Browser) Locate the 2D points trackfile generated by DLTdv8a in Step VI-B, or click **Cancel** to use the default save location `{project-root}/trackfiles/xypts.csv`.

4. (UI Browser) Choose the path to save the estimated 3D world points to, or click **Cancel** to save to the default location `{project_root}/reconstruction/{prefix}xyzpts.csv`.

    > The prefix is determined automatically from the 2D trackfile name `{prefix}xypts.csv`.

5. (UI Browser) Locate the directory containing the video frames, or click **Cancel** to use the default directory `{project-root}/media/frames/`.

6. When prompted to use undistorted images for reprojections, enter `y` to do so, and `n` otherwise. Only enter `y` if you undistorted the images in Step V.

That's it. The script will then perform the computations as in Step VII-A, but this time for all the frames containing tracked points. A point is only reconstructed if it is visible in at least 2 views for a given frame. The 3D estimated points are further exported in DLTdv8 format.

![Estimating World Coordinates of Tracked Points and Reconstructing Them](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6a167a49-ea79-4832-a1a7-cd56eaa5d1c4)

Below is the DLTdv8a format estimated world coordinates export. On the left, you have our result (with the Levenberg Marquardt algorithm), and on the right, you have DLTdv8a's result (with DLT + SVD Based Triangulation).

![Estimated 3D Points (Levenberg Marquardt, i.e., our implementation &ndash; DLT-based Triangulation With SVD, i.e., DLTdv8a implementation)](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/46851acf-341f-4311-aff8-568ffe25a8be)

This concludes the process of 3D reconstruction.

### **Test It Out Yourself**

Feel free to test out the toolbox on other images we have included in this repo. See folders: `Test Media`, `Marked 2D Points`, and `Results` for some of our own images, pre-marked points, and expected results. See `Results/README.md` to understand the naming conventions of the files in these folders. Otherwise, you may setup your own camera + mirrors and take your own images.

## **(OPTIONAL) Step VIII: Extrinsics Verification With Epipolar Geometry**

1. Navigate to the project root (either `D:/Dev/checker` for images or `D:/Dev/moving_checker` for video frames, in our case) within MATLAB and run `epipolar_geometry.m` from the command window:

    ```
    >> epipolar_geometry
    ```

2. (UI Browser) Locate the image on which you want to mark points and verify extrinsics via epilines. Usually, this will be an image you imported in Step V.

    Note that this may be a calibration image or any other image containing any object (not necessarily a checker), as long as it is visible in all the required views. For example, the following image is visible in 2 views (camera and mirror 1 - location: `{this-repo}/Test Media/3.jpg` in this repo).

	![Test Image Example](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)

4. (UI Browser) Locate the merged BCT calibration parameters file from Step II. Clicking the **Cancel** button will attempt to find the file in the default location, and throw an error if it is not found.

    > ADD SCREENSHOT here

5. (UI Browser) Choose a directory to save the results to (i.e., point line distances, images with epilines drawn, etc.). Clicking **Cancel** will store them at: `{project-root}/epipolar/set_{x}` in the project root, where x is the first natural number starting from 1 that corresponds to a non-existing folder in the directory. Thus, previous result sets are not replaced.

    > ADD SCREENSHOT here

6. Choose whether to use the original or undistorted images to mark points and show the epilines on. This is recommended, as the BCT extrinsics are intended to be used with undistorted images. However, if your image does not have much distortion, you can get fairly accurate results even without undistortion.

    ```
    HELP: Only enter "y" if you have the undistorted images or video frames.
    [PROMPT] Use undistorted images for point marking? (y/n): y
    ```

7. Enter the number of points to mark in the image when prompted in the command window. For example:

    ```
    [PROMPT] Enter the no. of points to mark: 4
    ```

8. A figure titled after the view's name (*Camera*, *Mirror 1*, etc.) will show up. Here, you must mark the selected number of points in the corresponding view one-by-one. You can zoom in and out around the cursor by pressing `q` and `e` respectively, or reset the zoom level with `r`. The figure title tracks the progress as the current point being marked over the total to mark. Marked points show up as a plus (`+`) marker with cycling colors.

    ![Marked Points In Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/5b8073b6-9ada-46df-a953-1d6081850b16)

8. Once all points are marked, another figure window will open up. Repeat step 6 for the remaining views. Note that, like `point_marker.m`, the script keeps track of the history. Thus, when marking the i<sup>th</sup> physical point in the second view and onwards, its pixel location in all the previously marked views will be shown on the image as a crossed square with the corresponding color. This helps keep track of corresponding points between views.

    ![Marked Points In Mirror 1 View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/40c0b563-2a74-4dbe-bc7a-be1721d2ed52)

Once all the views are done, the script will compute the required parameters, i.e., fundamental matrix, epipoles, epilines, epiline to corresponding point distance (point-line distances) and plot them for all combinations of view pairs. The results are saved in the directory selected in Step 4.

> ADD SCREENSHOT here

Suppose `{1}` represents the **name** of the image selected in Step 2. `{2}` represents the name of the view that acts as the **original image**. Finally, let `{3}` represents the **reference image**. The difference between the original and reference image is that for points $\mathsf{x}$ in the original image, $\mathsf{l' = Fx}$ gives the epiline in the reference image, whereas for points $\mathsf{x'}$ in reference image, the $\mathsf{F}$ matrix is **transposed**, i.e., $\mathsf{l = F'x}$ gives the epilines in the original image.

For each view pair, the script saves:

- `[{1}@{2}_{3}]-epilines_in_{3}.png`: Image with epipolar lines in the reflected view corresponding to original points (using the fundamental matrix as is).

![Epilines In Reflected Mirror 1 View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d92a8dba-16cf-4c8a-973b-c214feb73574)

- `[{1}@{2}_{3}]-epilines_in_{2}.png`: Image with epipolar lines in the original view corresponding to reflected points (transpose of fundamental matrix).

![Epilines In Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/182d8e17-0d02-4efb-9852-ccd8db3ef0c4)

- `[{1}@{2}_{3}]-fun_and_plds.mat`: A .mat file with the fundamental matrices and point-line distances.

<p align="center" width="100%">
  <img alt="Matfile Containing Saved Variables" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/fcd93fbb-a2b6-49b8-b3a0-1879a427afcd">
</p>

## **Final Notes**
For more comprehensive information and instructions, please take a look inside the Documentation folder, which has much more detail for each step.

If you come across any bugs or problems, please feel free to open an issue. We will try to address it as soon as possible.

## **References**
<a id="1" href="https://doi.org/10.1088/1748-3182/3/3/034001">[1]</a>
Hedrick, T. L. (2008). Software techniques for two-and three-dimensional kinematic measurements of biological and biomimetic systems. Bioinspiration & biomimetics, 3(3), 034001.

<a id="2" href="https://doi.org/10.1088/1748-3182/3/3/034001">[2]</a>
Bouguet, J.-Y. (2022). Camera Calibration Toolbox for Matlab (1.0). CaltechDATA. https://doi.org/10.22002/D1.20164

- [DLTdv8a Webpage](https://biomech.web.unc.edu/dltdv/)
- [BCT Webpage](http://robots.stanford.edu/cs223b04/JeanYvesCalib/)

### MATLAB File Exchange (FEX)
These can optionally be enabled in `defaults.m`.

<a id="3" href="https://www.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort">[3]</a>
Stephen23 (2023). Natural-Order Filename Sort (https://www.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort), MATLAB Central File Exchange. Retrieved July 4, 2023.

<a id="4" href="https://www.mathworks.com/matlabcentral/fileexchange/34055-tightfig-hfig">[4]</a>
Richard Crozier (2023). tightfig(hfig) (https://www.mathworks.com/matlabcentral/fileexchange/34055-tightfig-hfig), MATLAB Central File Exchange. Retrieved July 4, 2023.

<a id="5" href="https://www.mathworks.com/matlabcentral/fileexchange/23629-export-fig">[5]</a>
Yair Altman (2023). export_fig (https://github.com/altmany/export_fig/releases/tag/v3.39), GitHub. Retrieved July 4, 2023.

Relevant variables for enabling/disabling MATLAB File Exchange (FEX) tools in `defaults.m`.

- natsort: `FEX_USE_NATSORT`
- tightfit: `FEX_USE_TIGHTFIG`
- export_fig: `FEX_USE_EXPORTFIG`
