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

Note that there are two other READMEs, one in the repo's `Calibration` folder and the other in `DLTdv8a Integration` folder. The former contains instructions on how to calibrate the camera and mirrors using BCT and notes on some special cases, while the latter contains instructions on how to use the mirror reconstruction toolbox with DLTdv8a to reconstruct tracked points in a video.

> All the scripts can be called directly from the command window from anywhere after initializing the toolbox (which adds it to the MATLAB path.

## **Step I: Toolbox Initialization + Project Setup + Calibrating Setup With BCT**

Before we start, we need to initialize the toolbox and set up a project directory in which we will be working. The project directory contains all the necessary files and folders for the mirror reconstruction toolbox to work effectively, and is also where the calibration and reconstruction results are stored.

1. Clone this repository, launch MATLAB in any folder apart from the cloned one, and navigate to the folder `Mirror Reconstruction Toolbox` from within MATLAB.

2. Open up the file `setup_mirror_reconstruction_toolbox.m` and run it. This will add the toolbox to MATLAB's path and generate a couple of important files to keep track of and manage the projects you'll be creating (`project_dirs.m` and `toolbox_dir.mat`).

	> WARNING: If you run `setup_mirror_reconstruction_toolbox.m` directly from its folder (so that MATLAB opens in its directory), the script will think that the toolbox is already on the path, and enter reintiailzie/reset mode. Therefore, it is recommended to launch MATLAB in some other path and then navigate to the `Mirror Reconstruction Toolbox` directory for a first-time setup. Otherwise, you may proceed with re-initialize mode, and manually save the current working directory (i.e., `Cloned Path/Mirror Reconstruction Toolbox/` to toolbox path by running `savepath(pwd)` in the command window.  
 
3. Create a project in any directory by navigating to it inside MATLAB and running the following in the command window:

	```
	>> project_setup
	```

	Which outputs the following:

	```
	Creating a project in the current folder.
	NOTE: You can configure the structure globally by editing "defaults.m" in the toolbox path.

	[PROMPT] Enter the name of the project: checker
	```

	![Project Skeleton Checker](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/702a7ec3-dd4a-4f43-a1a1-f5d8bd3b2f18)

    This will create a 'skeleton' of the project under a folder with the name above (in this case, `checker`), with pre-defined folders and two files: `project_dir.mat`, that contains the absolute path of this project on the computer, and `defaults.mat`, that contains the project-specific default settings (described in Mirror Reconstruction Toolbox's `defaults.m`). The default settings are used when executing the toolbox's various scripts and functions to ensure smooth behavior within the project.

   > From here on out, before executing any of the mirror reconstruction toolbox's scripts, move to the project's root directory from within MATLAB, otherwise the missing `defaults.mat` will throw errors. Note that setting up a project with `project_setup.m` automatically changes directory to the project's root directory.

5. Gather the calibration images as described in this repo's `Calibration/README.md`, Step I.

6. Begin the preliminary calibration preparation by moving to the *project's root directory* and running (in command window):

    ```
    >> calib_import_media
    ```

7. Enter whether you have calibration images (`i`) or video (`v`).

    ```
    [PROMPT] Do you have calibration images or video? ("i" = imgs, "v" = vid): i
    ```

### **Images Route**

- (UI Browser) Select the calibration images anywhere on your computer.

	> A set of 11 calibration images is provided in the repo's `Calibration` directory.

	![11 Calibration Images In Repo Calibration Folder](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/374b6226-9ff0-4dc3-9b01-f1597e776a69)

- (UI Browser) Choose the directory to put the images in, relative to the project's root directory. Click **Cancel** to place them in the default location (`project_root/calibration/images/`). The script will automatically rename them in a format optimized for BCT as described in `defaults.m`, e.g., from {img1.jpg, img5.jpg, ..., imgK.jpg} &rarr; {Image1.jpg, Image2.jpg, ..., ImageN.jpg}.

	![11 Calibration Images Imported to Project Directory](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/8deecb57-6486-4891-b6f5-92848745faec)

If you have manually imported the calibration images somewhere into the project root instead, skip Steps 5&ndash;6 + the two above, and proceed directly to Step 7. Note that if these images are not in numbered order, simply rename them sequentially by directly running the following in the command window from the project root:

```
>> imgs_sequential_rename
```

This will ask if you want to rename a directory of images, or a subset of selected images. Based on your choice, you will have to locate a directory or select a set of images in a UI browser, and the images inside will be renamed. At this point, you can proceed to Step 7 (calibration) below.

> WARNING: `imgs_sequential_rename.m` will rename the files without making copies of the original. Make a backup of the original images before you run it!

### **Video Route**

- (UI Browser) Select the calibration video from anywhere on your computer. The script will copy and auto-convert it to MP4 if it is in any other format.

	> A calibration video can be found in the repo's `DLTdv8a Integration/test_vids/` directory.

	![Calibration Video in Repository](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e8e4590a-8cc0-4fae-9367-97c8849e0f98)

- (UI Browser) Select the path to save the video to within the project directory. The script will then auto-run `calib_extract_vid_frames.m` to extract the video frames.

	![Calibration Video Imported](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f7f1c0ca-d7fb-4706-81f8-60e519c94feb)

- (UI Browser) Select the directory to extract the frames into. Alternatively, click **Cancel** to quickly use the default directory instead (`calibration/frames/`).

- Enter the starting and stopping times for the video in HMS format when prompted. E.g., for 15&ndash;30 seconds, enter `00:00:15` for start and `00:00:30` for stop time. By default (blank inputs) the whole video is used.

    ```
    [PROMPT] Enter start timestamp in H:M:S format (blank = from video start):
    [PROMPT] Enter stop timestamp in H:M:S format (blank = until video end):
    ```

- Enter the format in which to extract the frames (by default, JPG).

    ```
    Supported Image Formats = .jpg, .png, .tif, .bmp
    Input Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"
    [PROMPT] Enter image extension for extracted calibration frames (blank = default image extension): j
    ```

    The script will now extract the frames as {Frame1.jpg, Frame2.jpg, ..., FrameF.jpg} and auto-run `calib_select_img_subset.m`.

	![Calibration Video Extracted Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/91886e3c-8d0e-4f64-848f-019df148196f)

- Select a subset of the extracted frames to use as calibration images. These frames will be renamed in consecutive order sequetntially, so if you selected {Frame40, Frame80, Frame100, Frame180}, these would be renamed to {Image1, Image2, Image3, Image4} respectively.

	![Calbration Images From Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/29bc0ee0-464e-48c3-883f-18602e09a793)

Note that if you have manually imported the calibration video into the project root and it is already MP4, skip steps 5&ndash;6 and directly run `calib_extract_vid_frames.m` instead, which will again auto-run `calib_select_img_subset.m`.

If the video is not MP4, run `convert_vid_to_mp4.m` first, and then run `calib_extract_vid_frames.m`.

7. **CALIBRATION STEP:** Assuming Bouguet Calibration Toolbox (BCT) is correctly setup and on the MATLAB path, move to the calibration images directory and call `calib_gui` to begin the **BCT calibration process**. Note that the mirror reconstruction toolbox will automatically change directory to the calibration images once they are ready.

***For full details on the calibration process with Bouguet Calibration Toolbox (BCT), view `Calibration/README.md`.*** It is very comprehensive, and it is highly recommended to read through it at least once, especially if you are not familiar with BCT.

By the end of the calibration process, you should have the following files (assuming two views, 1 camera + 1 mirror):

<p align="center">
    <img alt="Calibration Result Files For Two Views" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/51fb8c43-3cbb-4404-b489-131f0e2dda93">
</p>

Here, `calib_data.mat` saves the clicked corners information if you want to recompute the calibration parameters. `Calib_Results.mat` are the saved calibration results, including the intrinsics and extrinsics that we require for reconstruction. Step II deals with how to process these results and export them into a format that's suitable for the reconstruction scripts.

### **Camera And Mirror Movement**

Once you have setup the camera and mirrors for calibration, ensure they remain stationary for the remaining steps as well as during calibration. If they do move after calibration, you will need to recompute the reference extrinsics with BCT's **Comp. Extrinsic** function, which is a little tricky to setup and remains largely untested on our end as it occasionally produces spurious results (see ***Special Scenarios*** section, item no. 1 at the end of `Calibration/README.md` for details).

## **Step II: Merging BCT Result and Simultaneously Converting to DLTdv8a Format**

Once we have the calibration results for each view (as many `.mat` files as the no. of views), we need to merge the variables necessary for reconstruction into one mat-file. We also need to convert the BCT results from KRT form to the normalized 11-DLT coefficients form &ndash; this is to use the calibration result when working with videos in DLTdv8a (otherwise, the epipolar lines won't show).

> You can remove the calibration checker pattern at this stage if you want to. It is no longer needed.

Moving back to the scripts, the step-wise process is described below:

1. Move to the project's root directory from within MATLAB.

2. Run the script `calib_process_results.m` from the command window:

    ```
    >> calib_process_results
    ```

3. Enter the extrinsic reference image suffix. E.g., if calibration set was labeled {Image1, Image2, ..., Image15.jpg}, the suffixes are {1, 2, ..., 15}. This picks the corresponding extrinsics `Rc_{suffix}` and `Tc_{suffix}`, e.g., `Rc_1`, `Rc_ext`<sup>+</sup> , etc.

    ```
    [PROMPT] Enter calibration image suffix to use as world reference image for extrinsics (blank = default): 3
    ```

    The default value is `1`. Needless to say, extrinsics `Rc_x` and `Tc_x` corresponding to suffix `x` must exist in the calibration results, otherwise an error is thrown.

    > <sup>+</sup>If the extrinsic reference is not part of the calibration set (meaning extrinsics were computed via **Comp. Extrinsic** function of BCT), you would enter `ext` here (see ***Special Scenarios*** section, item no. 1 at the end of `Calibration/README.md`).

4. (UI Browser) Locate each view's calibration file. These would normally be manually renamed in the default expected format `Calib_Results_{view-identifier}.mat`, though it could be any name. Clicking **Cancel** will skip that view (it won't be used in reconstruction). At least 2 views are required for this to work.

    > For `{view-identifier}`, we prefer using {`cam`, `mir1`, `mir2`} for each view.

5. (UI Browser) Choose path to save the merged calibration result in the UI browser, or use the default location by pressing the **Cancel** button.

6. (UI Browser) Choose path to save the 11 DLT coefficients for DLTdv8a that are also computed in this step, or use the default location by pressing the **Cancel** button.

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

> **Following are a few important notes on this step to help understand what's happening in more detail. You may skip to Step III.**

### **Details On Merged BCT Parameters**

The merged BCT file contains two shared variables between all views:

1. `ext_ref_suffix` = Extrinsic Reference Image Suffix: This is the image number which we use as our reference for extrinsic parameters. This is just the image no. and not the actual iamge itself. Having a common extrinsic reference for all views is crucial in developing the correct scene pose.

    > Make sure that in the selected extrinsic reference image, the checker is visible in all views!

2. `view_labels` = View Labels: If you label your view according to some convention (e.g., camera is view 1, LEFT mirror is view 2, and RIGHT mirror is view 3 per our assumptions), then in a 2-view project, you might want to preserve the numbering convention even when views involved are 1 and 3. That's what this variable does.

View labeling is also helpful if you are testing multiple number of views. However, to set it up correctly, you must carefully select the corresponding calibration result files. Thus, assuming convention mentioned in point 2 just now, if your 2-view setup involved the camera and RIGHT mirror, you would select camera calibration file, SKIP mirror 1 (left mirror) calibration file, and select mirror 2 (right mirror) calibration file.

You might wonder that indexing with 1 and 3 and no 2 in-between would cause problems when dealing with arrays or making loops based on the number of views, and you'd be right. This is why we need the view labels variable in the first place: it allows us to index to the appropriate parameter, but we do not use it for slicing into arrays within the scripts &ndash; for that, we use the number of views, which disregards view labels.

Additionally, there are five parameters unique to each view. The unique parameters are:

1. `kc`: Undistortion Coefficients
2. `KK`: View Intrinsics
3. `Rc`: Rotation Matrix (permuted for mirror views to enforce left-handedness)
4. `Tc`: Translation Vector
5. `CF`: Path to the original calibration file &ndash; this is mainly just to keep track of what came from where

These are indexed according to the view label, as `kc_1` (distortion coefficeints for view 1) and Tc_3 (translation vector for view 3). Which view number corresponds to which view is subjective and up to you.

We classify `CF` (unique), `view_labels` (shared), and `ext_ref_suffix` (shared) as secondary variables that are not directly associated with calibration results. On the other hand, the remaining variables including distortion coefficients `kc` (unique), intrinsics `KK` (unique), and extrinsics `Rc` and `Tc` (unique) are primary results.

### **Correcting BCT's Forced World Frame Right-Handedness in the Mirror Images**

A very important step `calib_process_results.m` performs internally is a permutation transform to correctly convert the mirror view world frames to left-handed convention, as is the case with mirror reflections.

**BCT forces right-handedness** of the estimated world frames on the checker (after marking the internal corner points). While this is a valid constraint for real cameras since they are rigid bodies, it remains that mirror reflection of a typical right-handed frame ***swaps*** the handedness, so that it becomes left-handed. This is clearly not the case with BCT, as mirror reflections of the checker are forced to be right-handed.

This essentially creates the problem that there are two different world reference frames that share the same world Z-axis (pointing up, i.e., out of the checker plane), but the world X and Y-axis (on the checker plane) are swapped depending on whether we have the actual checker (camera view) or its reflection (mirror view). The swapping in reflected views occurs to preserve the right-handedness and keep Z-axis pointing up.

Thus, when estimating world coordinates via some optimization technique, **the optimization would simply fail to converge** as the original world frame's X is the reflected frame's Y, and vice versa, so that they never agree. To fix this, we have two options:

1. In each optimization iteration, only for the reflected views, swap the XY coordinates of the current state of the world points vector. This tricks the optimization into thinking the world coordinates are in the same frame convention as the original camera view, and it proceeds smoothly.

```math
\begin{bmatrix} X \\ Y \\ Z \end{bmatrix} \rightarrow \begin{bmatrix} Y \\ X \\ Z \end{bmatrix}
```

2. Apply a **permutation transformation** to the rotation matrices of the mirror views, so that the first two columns corresponding to X and Y coordinates are swapped. We get the rotation matrices for a certain checker position in an image from the calibration step (either directly via calibration or from BCT's **Comp. Extrinsic** function), so this is a one-time operation.

We have tested both approaches, and both work. However, **approach 1** is cumbersome in that **(a)** it requires the swap operation in every step of the optimization, and **(b)** when reprojecting points to the reflected views, we need to re-swap the estimated world coordinates back to the original form.

On the other hand, **method 2** is much more permanent as it addresses the root cause of the issue, i.e., the **misalignment of coordinates in the rotation matrix**. Note that we do not need to permute translation vector $T$ as it is already defined w.r.t. the camera frame and the camera frame is not the issue &ndash; only the world frame is. This is in contrast to rotation matrix $R$, which is defined such that it takes points defined w.r.t. world frame to the camera frame.

Let's consider $xyz$ the camera frame and $XYZ$ the world frame. Then, the required permutation matrix $T_\text{permutation}$ is:

```math
T_\text{permutation} = \begin{bmatrix} 0 & 1 & 0 \\ 1 & 0 & 0 \\ 0 & 0 & 1 \end{bmatrix}
```
```math
R = \begin{bmatrix} r_{xX} & r_{xY} & r_{xZ} \\ r_{yX} & r_{yY} & r_{yZ} \\ r_{zX} & r_{zY} & r_{zZ} \end{bmatrix} \cdot \begin{bmatrix} 0 & 1 & 0 \\ 1 & 0 & 0 \\ 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} r_{xY} & r_{xX} & r_{xZ} \\ r_{yY} & r_{yX} & r_{yZ} \\ r_{zY} & r_{zX} & r_{zZ} \end{bmatrix}
```

In effect, the permutation operation essentially makes the rotation matrix as if the world's X was its Y, and Y was X, and so it is now defined w.r.t. the world frame in the original camera view.

Below, we provide a side-by-side comparison of the variables in the workpsace to show that the first and second columns are swapped. The images correspond to the tutorial we have been following so far, so the reference extrinsics image suffix was `3`. Additionally, in the merged BCT file, we follow the view labels {1, 2, 3} for {Camera, Mirror 1 (Left Mirror), and Mirror 2 (Right Mirror)}. 

Keeping the above in mind, the image on the left (with variable `Rc_calibration`) corresponds to `Rc_3` from BCT calibration result file `Calib_Results_mir1.mat`, and the image on the right (with variable `Rc_permuted`) corresponds to `Rc_2` from the merged BCT calibration file created in Step II (by default, `bct_params.mat`).

<p align="center" width="100%">
    <img alt="Rotation at Calibration Time (Rc_3 in Calib_Results.mat file)" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6a4199ef-2588-4ab4-a8f1-313e3c46371b" width="48%">
	&nbsp; &nbsp;
	<img alt="Rotation Permuted On Process (Rc_2 in merged BCT file)" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/fd081270-9df0-4e4d-a2b4-ba431ed615c8" width="48%">
</p>

This swapping only happens for mirror views, so in the case of camera view, `Rc_3` from `Calib_Results_cam.mat` and `Rc_1` (corresponding to camera view) from merged BCT calibration file (default, `bct_params.mat`) are both exactly the same.

## **Step III: Creating Test Images/Frames/Video + Importing + Undistortion**

Now that we have the merged calibration file ready, we can begin gathering some test images or videos of the object that we want to reconstruct.

Place the object you want to reconstruct in the calibrated region, and make sure its features are clearly visible in all the calibrated views. Capture as many images as you want with the test object in various positions, making sure the camera and mirror setup remains in the same position as during calibration.

Given below is an example of a test image (location: `Test Images/3.jpg` in this repository).

![Test Image Example](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)

If your camera has noticeable distortion or you would just like to work with undistorted videos/images, you can begin the undistortion procedure by pressing `y` when prompted. Otherwise, type `n` to skip undistortion.

Step-wise, the process is described below:

1. Run `import_media.m` in the command window from within the project root directory.

    ```
    >> import_media
    ```

2. When prompted, enter whether you want import images or a video file in the command window:

    ```
    [PROMPT] Import images or video? ("i" = imgs, "v" = vid): i
    ```

### **Image Route**

- (UI Browser) Locate the images containing the object of interest anywhere on your computer.

	> 4 test images are provided in this repo's `Test Images` folder.

	![Test Images In Repository](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1db1c305-1773-4d97-873e-e145f322f280)

- (UI Browser) Choose which directory of the project to copy them to. Clicking **Cancel** here will place them in the project's `media/images/` folder by default.

	![Imported Test Image](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f7a7c5cb-033f-47b3-918a-bce08208379b)

- When prompted to undistort the images, type `y` to auto-run `create_undistorted_imgs.m` and begin the undistortion procedure for the imported images. Otherwise, type `n` to finish the import process.

#### **No Undistortion Sub-Route**

Nothing else to do. Proceed to marking points on the image as detailed in Step IV.

#### **Undistortion Sub-Route**

```
NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by "calib_process_results.m".
Undistort the imported images? (y/n): y
```

- (UI Browser) Locate the merged BCT calibration parameters file from Step II.

Wait until all the images are undistorted w.r.t. the distortion coefficients from each view. The results are stored in subfolders named `cam_rect`, `mir1_rect`, and `mir2_rect` in the same directory as the original images. Each folder contains the undistorted images corresponding to the distortion coefficients for that view. The image names are not changed within the folders, but you can edit the script to add suffixes which are supported by the undistortion functions/scripts.

> `create_undistorted_imgs.m` can be run standalone. In that case, the user is asked to locate a directory containing images or a set of image files to undistort.

<img alt="Undistorted Image Folders" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/ccb7522c-5ab1-4e61-a578-338a5c32120e" width="50%">

The undistortions are visualized below:

![Undistortion Mosaic](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e9e1798b-8395-45b0-b76a-bf80226e58bf)

### **Video Route**

> **If you enter this route, follow instructions in `DLTdv8a Integration/README.md` AFTER this step. You can still follow the steps listed here if you want to reconstruct a single frame of the video, but that's likely not your intention with video data.**

- (UI Browser) Locate the video containing the object to be tracked on your computer. The video could be in the various formats accepted by MATLAB's VideoReader, but the import process will convert a copy of it to MP4.

	![Test Video in Repository](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6ad786d5-0cf0-442e-ab1d-e18d9fee6481)

- (UI Browser) Choose the path to import the video into. Clicking **Cancel** will place it in the default location (`media/videos/`).

	![Imported Test Video](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/7f6baed5-41c6-4e2f-85b5-876494921175)

- When prompted to undistort the video, type `y` in the command window to begin the undistortion process described in `create_undistorted_vid_and_frames.m`. Otherwise, type `n` to skip directly to frame extraction without undistortion.

#### **No Undistortion Sub-Route**

```
NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by "calib_process_results.m".
Undistort the imported video? (y/n): n
```

The script `vid_extract_frames` is auto-run by `import_media`.

- (UI Broswer) Choose directory into which you wish to extract the video frames. Clicking **Cancel** will place them in the default location (`media/frames/`).

- Choose the extension of the extracted frames.

    ```
    Supported Image Formats = .jpg, .png, .tif, .bmp
    Input Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"
    [PROMPT] Enter image extension for extracted video frames (blank = default image extension): j
    ```

Assuming a total of F frames in the video, the frames are named as {Frame1.jpg, Frame2.jpg, ..., FrameF.jpg}.

![Extracted Test Video Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/f0da4212-5e73-4dd1-b980-4ed6044ec4fb)

#### **Undistortion Sub-Route**

```
NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by "calib_process_results.m".
Undistort the imported video? (y/n): y
```

The script will auto-run `create_undistorted_vid_and_frames.m` to undistort the video and extract the frames.

> If you already have the video in your project directory and it is MP4, directly run `create_undistorted_vid_and_frames` in the command window instead of `import_media`. If the video is not MP4, use `convert_vid_to_mp4.m` to convert it to MP4 first.

- (UI Browser) Locate and select the merged BCT calibration parameters file from Step II.

- (UI Browser) Choose a directory to extract the video frames into. Clicking **Cancel** will place them in the default location (`media/frames/`).

- Select the extension of the extracted frames.

    ```
    Supported Image Formats = .jpg, .png, .tif, .bmp
    Input Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"
    [PROMPT] Enter image extension for extracted video frames (blank = default image extension): j
    ```

These frames are then undistorted with the distortion coefficients for each view and stored in new folders (one per view) in the extracted frames' directory. The folders are named after the corresponding views: `cam_rect`, `mir1_rect`, and `mir2_rect`.

<img alt="Undistorted Frame Folders" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e6ce95c5-ac3e-40b7-9416-2bebccc436fa" width="50%">

The undistorted frames are visualized below:

![Undistortion Mosaic For Frames](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/4f2e8830-122c-4890-a6a7-780645bb164f)

Additionally, these undistorted frames are stitched back into undistorted videos that are placed in the same directory as the original video with the same name., but suffixed with `{original-name}_cam_rect.mp4`, `{original-name}_mir1_rect.mp4`, and `{original-name}_mir2_rect.mp4`.

![Undistorted Videos](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/b3e4105d-8292-4655-a3f9-a09695a94c5e)

### **Undistortion: Grayscale or RGB?**

Note that color is preserved in the undistorted videos and frames or images by default, if the video/frame is RGB (see `undistort_img.m`). If images are grayscale, then a grayscale variant of the function is used (see `undistort_img_gray.m`).

> **From this point on, if you are working with images, continue reading this document. Otherwise for instructions related to video data and DLTdv8a, head to `DLTdv8a Integration/README.md` and follow the instructions from Step IV there.**

# **Step IV: Manually Marking Corresponding Points On Test Image**

Before we can reconstruct the object, we first need to manually mark corresponding points on the object in all the relevant views.

1. Run `point_marker.m` from the project root in the command window.

    ```
    >> point_marker
    ```

2. (UI Browser) Locate the test image containing the object of interest (to be reconstructed) that was imported in Step III. This may be a video frame as well.

3. (UI Browser) Locate the merged BCT calibration file created in Step II.

4. Enter the number of points to mark in the image. For example, if you want to mark four points in each view, enter `4` in the command window:

    ```
    [PROMPT] Enter the no. of points to mark: 4
    ```

5. When prompted to use undistorted images to mark points in the command window, enter `y` to do so, and `n` otherwise. Only enter `y` if you undistorted images in Step III, otherwise an error is thrown.

    ```
    HELP: Only enter "y" if you have the undistorted images/video frames.
    [PROMPT] Mark points on undistorted images? (y/n): y
    ```

6. Based on inputs in Steps 2 and 5, either the original or undistorted versions of the image will open up in a figure. Here, mark exactly the number of points you entered in Step 3 by clicking on image points corresponding to the particular view. The marked points will show up as colored plus (`+`) markers. Once all the points are marked, a new figure will open.

    > We will be reconstructing the 3D coordinates using these 2D points, so ***it is important to mark the corresponding points in all views accurately.***

	![Marked Points Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/35f137d2-f87d-45ad-be45-a1c4ecafaf7d)

7. Repeat Step 6 until the remaining views are exhausted, taking care to mark points in the ***same physical order*** in each successive view as in the first view. Like in epipolar verification, the script keeps track of the marked points' history, so when marking the i<sup>th</sup> point in the second view and onwards, its pixel location in all the previously marked views will be shown on the image as a crossed square with the corresponding color.

	![Marked Points Mirror View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/b39bde96-0cf8-4856-ade2-46b6bd01106e)

7. (UI Browser) will open up. Here, choose the path to the save the results, or click **Cancel** to use the default location, i.e., `reconstruction/marked_points.mat` in the project root. The saved variables are:

    - `x`: A 2D array containing the marked pixel locations of all physical points in all views
    - `num_points`: An integer describing the total number of physical points marked (i.e., the input in Step 3)

Command window output:

```
Entering point-marking mode...
NOTE: Press "q" to zoom in, "e" to zoom out, and "r" to reset zoom level. Zoom is around cursor!

	o Camera View - Marking Points: 4/4...done.
	o Mirror 1 View - Marking Points: 4/4...done.

All done. Results: D:\Dev\checker\reconstruction\marked_points.mat
```

The correspondence between physical points in two different views is visualized below.

<p align="center" width=100%>
	<img alt="Point Correspondence In Two Views" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/1914366b-5d18-490f-a8a0-112a88bb12d9" width="40%">
</p>

Within MATLAB from `point_marker.m`, the following is a visualization of the clicking order in the two view images:

![Marked Point Click Order Within MATLAB](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/ee2c4aea-5b0e-4b22-a358-aeda49cfc1d2)

And the following is a display of the `x` array containing all the marked pixel locations. You can see they match up with the above figure:

![Display of Marked Points `x` Array](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/3c11f36c-9dd3-469d-8c26-e3a734d43e40)

### **Output Details**

For `num_views` correspondences over a certain `num_points`, `x` is a `(3, num_views * num_points)` matrix. Each column represents a homogenous pixel's coordinates, `[x_px; y_px; 1]`. The set of columns `1 : num_points` are the points marked in the first view (usually the camera view) and columns `num_points + 1 : 2 * num_points` are the corresponding points in the second view (usually the first mirror reflection). Similarly, columns `2 * num_points + 1 : 3 * num_points` are the points marked in the third view (usually the second mirror reflection).

Simultaneously, assuming the user marked the points in the same physical order, the pixel location depicted in the **column `1`** of `x` (i.e., first marked point in the first view) *corresponds* to the same physical point as the pixel location in **column `n + 1`** (i.e., first marked point in the mirror view) and so on for successive views. Similarly, the second pixel in column 2 corresponds to the reflected pixel at `n + 2`, and so on. In general, the pixel in column `k` such that `k <= num_points` corresponds to the pixel in column `k + num_points`. Each of these pixel correspondences represents a single physical point in the world. We can then use `x` by appropriately slicing it to select the set of corresponding points that we need for reconstructing a single physical point.

Below, we have attached a picture of an included `marked_points.mat` file with the full set of 140 points marked (you can find it at `Marked 2D Points/P4.mat`):

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

> In the above figure, while we mark a total of `2n` pixels over two images, we are actually only dealing with `n` real-world points. They are just projected to two views. If we had k views, we would have a total of `k * n` points.

## **Step V: 3D Reconstruction of Different Objects In Single Test Image**

By now, we have the poses, the intrinsics, and the 2D corresponding points for both views. We are finally ready to begin reconstruction of the object's physical points in 3D world coordinates. The script `reconstruct_marked_pts_bct.m` performs the reconstruction process for a single image.

1. From the project's root directory, run the reconstruction script from the command window:

    ```
    >> reconstruct_marked_pts_bct
    ```

2. (UI Browser) Locate the image on which you marked the points in Step IV.

3. (UI Browser) Locate the file containing the marked points created in Step IV. Click **Cancel** to use the default save location, i.e., `reconstruction/marked_points.mat` in the project root.

4. (UI Browser) Locate the merged BCT calibration file created in Step II. Click **Cancel** to use the default save location, i.e., `calibration/bct_params.mat` in the project root.

5. (UI Browser) Choose the directory where you want to save the results of the reconstruction. Clicking **Cancel** will use the default location, i.e., `reconstruction/{1}.mat` in the project root, where `{1}` is the basename of the image in Step 2 (w/o extension).

6. When prompted to use undistorted images to mark points in the command window, enter `y` to do so, and `n` otherwise. Only enter `y` if you undistorted images in Step III, otherwise an error is thrown.

    ```
    HELP: Only enter "y" if you have the undistorted images/video frames.
    [PROMPT] Mark points on undistorted images? (y/n): n
    ```

That is all. The script will proceed to perform the world point estimation, compute the average reprojection error, plot the 3D error hsitogram if the distances are provided (though this is not fully supported as it is very siutational), and save the results in the directory specified in Step 5.

```
% THESE RESULTS FOR 140 POINTS MARKED ON TEST IMAGE, NOT 4!
% Use "Marked 2D Points/P4_undistorted.mat" when prompted for
% marked points to reproduce.
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

This concludes the process of 3D reconstruction.

### **Test It Out Yourself**

Feel free to test out the toolbox on other images we have included in this repo. See folders: `Test Images`, `Marked 2D Points`, and `Results` for some of our own images, pre-marked points, and expected results. See `Results/README.md` to understand the naming conventions. Otherwise, you may setup your own camera + mirrors and take your own images.

At this point, we recommend viewing Optional Step VI (extrinsics verification with epipolar geometry) and learning how to work with video data by checking out `DLTdv8a Integration/README.md` in this repo. You may also test different calibration scenarios, especially the ones near the end of `Calibration/README.md`.

### **Details On Estimation of 3D World Points (`lsqnonlin`)**

The script that performs reconstruction for marked points in a single image is `reconstruct_marked_pts_bct.m`, and over video data assuming tracked points in each frame with DLTdv8a is `reconstruct_tracked_pts_bct.m`. Both of them use the same process for estimating the 3D world coordinates, defined in the internal optimization target function `reconst_coords_per_px`.

At its core, our approach to the problem of reconstruction is simply that of an optimization problem. We presume that a fairly accurate solution for the depth (world Z-coordinate) of each point on the object exists, given that any two views of the object commonly observe that point. In this case, of course, we have just one image. The views apart from the camera come from the mirrors, which act as virtual cameras.

If an object point is visible in at least two views (camera-mirror, mirror-mirror, and other combinations), we have the constraint that the two rays from the camera centers to the object point in 3D space will intersect at that object point, which is at some depth Z.

Now, since there is only one world reference frame, the same 3D world points must project to two different pixel locations on the two cameras. We already know these pixel locations -- we marked them just now! So all we really need to do is figure out the choice of 3D points for which the forward projection (i.e., pixel projection `x = K * [R T] * X`) of both the views is correct (i.e., the reprojection error in both images is collectively minimized).

Like with other optimization problems, we start with a wild guess for the world coordinates of a physical point `X`, calculate the reprojection error in each view w.r.t. the marked point, i.e., `x_marked - x_reproj`, vectorize the result as `[xcam_reproj, xmir1_reproj, xmir2_reproj]`, compute the mean squared reprojection error (loss function), and update our guess accordingly. Assuming we have $J$ views, the vector of true pixel locations is $\boldsymbol{x_\text{marked}}$, and that the vector of reprojected points is $\boldsymbol{x_\text{reproj}}$, then the loss function is:

```math
\text{loss} = \frac{1}{J} \sum_{j=1}^{J} \left( x_\text{reproj} - x_\text{marked} \right)^2
```

We repeat this for all the points we marked, and we have the 3D world coordinates for all the points.

> NOTE: `lsqnonlin` implements mean square error implicitly using the vectored error provided and calculates gradients based on their collective minimzation, so we can be sure it optimizes the world coordinates of a point over all views collectively.

#### ***Merged BCT Parameters vs. DLT Coefficients for Reconstruction***

Reconstruction may be performed using either the merged BCT calibration file, which contains intrinsics `K` and extrinsics `R` and `T`, or the DLT coefficients file, either by `DLT = P = K * [R | T]` in projection equations within reconstruction, or by converting from DLT to KRT form as described in `dlt_to_krt.m`, and then the rest of the process remains the same as with the standard merged BCT file.

However, the toolbox currently only supports the BCT variant since that preserves the view labels/identity/integrity as a secondary variable in the merged result. For DLT parameters, we would need to save a separate matfile containing the view labels or ask the user about them, as there is no way to embed that information in the 11 DLT coefficients file.

## **(OPTIONAL) Step VI: Extrinsics Verification With Epipolar Geometry**

1. Run `epipolar_geometry.m` from the project root in the command window:

    ```
    >> epipolar_geometry
    ```

2. (UI Browser) Locate the image on which you want to mark points and verify extrinsics via epilines. Usually, this will be an image you import in Step III.

    ```
    Locating the image to mark points and plot epilines on...done.
    ```

    Note that this may be a calibration image or any other image containing any object (not necessarily a checker), as long as it is visible in all the required views. For example, the following image is visible in 2 views (camera and mirror 1 - location: `Test Images/3.jpg` in this repo).
   
	![Test Image Example](https://user-images.githubusercontent.com/65610334/212613772-6859659b-80d0-4e0b-9f01-360d90cae2f0.jpg)

4. (UI Browser) Locate the merged BCT calibration parameters file from Step II. Clicking the **Cancel** button will attempt to find the file in the default location, and throw an error if it is not found.

    ```
    Locating the merged BCT calibration file...done.

    Created total of 1 view pair(s) based on the merged calibration file:
    	Camera --> Mirror 1
    ```

5. (UI Browser) Choose a directory to save the results to (point line distances, images with epilines drawn, etc.). Clicking **Cancel** will store them to: `epipolar/set_{x}` in the project root, where x is the first natural number starting from 1 that corresponds to a non-existing folder in the directory. Thus, previous result sets are not replaced.

    ```
    Choosing directory to store results in...done.
    ```

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

```
Entering point-marking mode...
NOTE: Press "q" to zoom in, "e" to zoom out, and "r" to reset zoom level. Zoom is around cursor!

	o Mark points in Camera view: 4/4...done.
	o Mark points in Mirror 1 view: 4/4...done.

All views done. Exiting point-marking mode.

Calculating fundamental matrix, epipoles, epilines, and point-line distances (PLDs) for 1 view pair(s)...

Pair 1: Camera --> Mirror 1
	Computing fundamental matrix...plotting epilines...calculating PLDs...saving results...done.
	Avg. PLD Over View Pair: 1.475250 (pixels) | 0.000412 (normalized)

All done. Results saved to:
	D:\Dev\checker\epipolar\set_3
```

> Existing results from a previous test if the new test's results are saved to the same directory. However, when using the default location to store results, a unique, non-existent folder is created for each new run of the script.

### **Saved Results**

Suppose `{1}` represents the **name** of the image selected in Step 2. `{2}` represents the name of the view that acts as the **original image**. Finally, let `{3}` represents the **reference image**. The difference between the original and reference image is that for points $x$ in the original image, $l' = Fx$ gives the epiline in the reference image, whereas for points $x'$ in reference image, the F matrix is transposed, i.e., $l = F'x$ gives the epilines in the original image.

For each view pair, the script saves:

- `[{1}@{2}_{3}]-epilines_in_{3}.png`: Image with epipolar lines in the reflected view corresponding to original points (using the fundamental matrix as is).

![Epilines In Reflected Mirror 1 View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/d92a8dba-16cf-4c8a-973b-c214feb73574)

- `[{1}@{2}_{3}]-epilines_in_{2}.png`: Image with epipolar lines in the original view corresponding to reflected points (transpose of fundamental matrix).

![Epilines In Camera View](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/182d8e17-0d02-4efb-9852-ccd8db3ef0c4)

- `[{1}@{2}_{3}]-fun_and_plds.mat`: A .mat file with the fundamental matrices and point-line distances.

<p align="center" width="100%">
  <img alt="Matfile Containing Saved Variables" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/fcd93fbb-a2b6-49b8-b3a0-1879a427afcd">
</p>

### **Notes On History Of Marked Points**

This sort of history where, in the current view, we exactly know the pixel location of a marked point in another view, is **unique to our mirror setup**. This is because we are marking points in mirror views &ndash; in a typical multi-camera setup, the marked pixel in one view practically NEVER corresponds to the same pixel location in another view as they are completely different images. Here, we have just one image, and we are repeating it for each view to get the mirror images. The only difference comes from the distinct undistortion profiles - you will notice that with undistorted images, the history is completely accurate.

To iterate further on the undistortion comment, remember that the history of marked points is not very accurate when using undistorted images, since each view has a unique distortion profile and, therefore, a unique transformation to rectify it. This means that the pixel location of an object point in the undistorted camera view is NOT necessarily the same as the pixel location of the same object point in the first mirror, given that the undistortions change the locations.

#### **History Fix: Composite Undistortions (Not Implemented)**

To correct the locations of pixels when using undistorted images, we need to use composite rectification transformations. We first need to fit a geometric transformation between each view's distorted (original) and undistorted image, which is information we receive during undistortion, and save it as a .mat file somewhere.

Then, assuming we have a marked point in the undistorted camera view and would like to visualize it in the undistorted mirror view, we can apply the following composite: distort pixel to original image coordinates by using inverse undistortion transformation for camera view &rarr; undistort pixel to the mirror view coordinates by using undistortion transformation for mirror view.

The reason we have not implemented this is simply because we save the undistorted images to speed up the reconstruction process. At that point, it does not make sense to have the transformation pairs for the main objective of the toolbox as we can just load in the undistorted image. However, this might be added in the future, along with a live epipolar line plotter.

### **Image Resolution and Point-Line Distances**

Since the corresponding points are marked manually, there is always some **human error** involved. Particularly, if the image resolution is high, even a slight offset can produce a seemingly large point-line distance (2-3 pixel distances even when the reprojection error is extremely low).

Thus, in addition to the point-line distances in pixel units, the script additionally computes the point-line distance in normalized units. This is computed as:

```math
\text{PLD}_\text{normalized} = \frac{\text{PLD}_\text{pixels}}{\sqrt[]{ \left( \text{width}_\text{img} \right)^2 + \left( \text{height}_\text{img} \right)^2 }}
```

That is, we divide the pixel distance error by the length of the image diagonal (which is the largest straight side in a rectangle).

Thus, a 2-pixel distance in an image with a 1000-pixel diagonal is equivalent to a 0.002 normalized distance, which puts things in perspective.

## **Final Notes**
If you come across any issues or bugs, please feel free to open an issue. We will try to address it as soon as possible.

Pull requests are also welcome (please direct them towards the `dev-tests` branch). For major changes, kindly open an issue first to discuss what you would like to change.

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
