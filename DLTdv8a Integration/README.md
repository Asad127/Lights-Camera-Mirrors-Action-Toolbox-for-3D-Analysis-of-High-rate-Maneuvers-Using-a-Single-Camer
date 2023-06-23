This is practically an indepdenent part of the toolbox. It is inteded for use with DLTdv8a tracking software, which allows working with video data. This is a functional version that, in conjunction with Bouguet Calibration Toolbox (BCT), allows for quickly setting up projects with mirrors. Very few of these functions/scripts are not used in the standard workflow &ndash; they may be removed later. Apart from that, a couple of scripts have untested features (such as mp4 conversion for videos). 

# Tutorial Videos
You can follow along by downloading the `mirror_reconstruction_toolbox` folder and videos from the `test_videos` folder. 

### Step 1: Toolbox Initialization, Project Setup, and Camera + Mirror Calibration
To add the toolbox to the path and generate a couple of important files, run `setup_mirror_recosntruction_toolbox.m`. After that, create a project in any directory using `project_setup.m`. This will create a 'skeleton' of the project, with folders and two files: `project_dir.mat`, that contains the absolute path of this project on the computer, and `defaults.mat`, which contains the default settings shared between various scripts and functions to ensure smooth functionality. 

> You may configure the default settings in `defaults.m` within the toolbox path. Any new projects after these changes will use the new settings. To update existing projects' settings, head to the existing project's directory and run `create_defaults_matfile.m`.

Get started with calibration by running `calib_import_media.m` from the created project's root directory (setting up a project automatically changes directory to the project root). This will ask you to locate the calibration images anywhere on your computer, rename them sequentially in a format acceptable by BCT, and import them either to the default location within the project directory or to any directory of your choosing. 

If you have a video of the checker pattern instead, the script will again import it to a directory of your choosing or within the default location in the project directory, convert it to mp4, and then guide you through process of extracting frames and selecting a subset of candidate images for calibration. 

Either way, once you have the calibration images, you can now begin the calibration process with BCT by moving to the image directory and calling `calib_gui` (the toolbox will automatically change directory to the calibration images upon running the import script). 

The calibration process itself requires Bouguet Calibration Toolbox, which must also be added to the MATLAB path.

##### Notes On Calibration
Accuracy is heavily dependent upon good calibration, so make sure you cover a variety of poses when taking the calibration images or recording the calibration video. Signs that your calibration is faulty: Extremely awkward undistortions, or maybe reprojections are good at some points and bad at others. 

Remember that you only need one common reference image of the checker which is visible in all views (camera + both mirrors) in case of a 3 view setup. Since each view's calibration is independent, you can select different image subsets for calibrating each view, as long as:

1. You ensure that neither the camera, nor the mirrors, move.
2. You ensure that at least one image is commonly visible in all views.

A good choice for point 2 is to leave the checker flat in front of both the mirrors. Usually, we keep this as the first image. After that, you can free yourself of the worry that the checker is visisble in all views and focus only on one particular view at a time. You may also use BCT's Compute Extrinsic function after calibration to generate extrinsics based on a non-calibration image. Again, this image should be visible in all views. 

### Step 2: Calibration Result Consolidation, DLTdv8a Compatible DLT Coefficients Generation, and Video Undistortion
Once we have the calibration results for each view, we need to merge the necessary variables into one mat-file. The script that performs this in conjunction with generating the 11 DLT coefficients file for DLTdv8a is `calib_process_results.m`. By default, the merged calibration file is named `bct_params.mat` and the DLT coefficients file is named `dlt_coefs.csv`. 

After running the script, simply follow the prompts:
- Choose the extrinsic reference image via its suffix (e.g., if calibration set was labeled [Image1, Image2, ..., Image15.jpg}, the suffixes are {1, 2, ..., 15}. If the extrinsic reference is not part of the calibration set (meaning extrinsics were computed via Compute Extrinsic function of BCT, you would enter 'ext' here without the quotes.
- Choose the camera, mirror 1, and mirror 2 calibration result files one by one. If not using a particular view, cancel its selection and it will be skipped. However, you need a minimum of 2 views for this to work.
- Decide where to save the merged BCT parameters and the DLT coefficients file.

This will generate the consolidated BCT parameters file and the DLT coefficients file. Now, if your camera has noticeable distortion or you would just like to work with undistorted videos and images, you can begin the undistortion procedure (otherwise, skip ahead to step 3):

- Run `vid_import.m` in the command window from within the project root directory.
- Locate the video containing the object to be tracked on your computer. The video could be in the various formats accepted by MATLAB's VideoReader, but the import process will convert a copy of it to MP4 and save it in either the default project directory or to a path of your choosing.
- When prompted to undistort the video, type 'y' (w/o quotes) to begin the undistortion process described in `create_undistorted_vid_and_frames.m`.
- When prompted, located and select the merged BCT calibration parameters file from earlier.
- Choose a directory to extract the video frames into. These frames are then undistorted using the distortion coefficients for each view and stored in new folders (one per view) in the extracted frames' directory. The folders are named after the corresponding views, so `cam_rect`, `mir1_rect`, and `mir2_rect`.
- Wait until the script undistorts frames for each view and then re-creates the videos from these undistorted frames. Thus, you will get as many videos as the number of views, each one using a different distortion profile. The videos are stored in the same directory as the original video wit the same name, but suffixed with `{original-name}_cam_rect.mp4`, `{original-name}_mir1_rect.mp4`, and `{original-name}_mir2_rect.mp4`.

> If you already have the video in your project directory, run `create_undistorted_vid_and_frames.m` instead of `vid_import.m`.

> Color is preserved in the undistorted videos and frames, but if you would llike grayscale, you can set the corresponding argument of the function `undistort_imgs.m` true in the script `create_undistorted_vid_and_frames.m`. 

##### Notes On Merged BCT Parameters

The merged BCT file contains two shared variables between all views:

1. Extrinsic Reference Image Suffix: This is the image number which we use as our reference for extrinsic parameters. This is just the image no. and not the actual iamge itself. Having a common extrinsic reference for all views is crucial in developing the correct scene pose.
2. View Labels: If you label your view according to some convention (e.g., camera is view 1, LEFT mirror is view 2, and RIGHT mirror is view 3), then in a 2-view project, you might want to preserve the numbering convention even when views involved are 1 and 3. That's what this variable does.

> Make sure that in the selected extrinsic reference image, the calibration pattern is visible in all views!

View labeling is also helpful if you are testing multiple number of views. However, to set it up correctly, you must carefully select the corresponding calibration result files. Thus, assuming convention mentioned in point 2 just now, if your 2-view setup involved the camera and RIGHT mirror, you would select camera calibration file, SKIP mirror 1 (left mirror) calibration file, and select mirror 2 (right mirror) calibration file.

You might wonder that indexing with 1 and 3 and no 2 in-between would cause problems when dealing with arrays or making loops based on the number of views, and you'd be right. This is why we need the view labels variable in the first place: it allows us to index to the appropriate parameter, but we do not use it for slicing into arrays within the script &ndash; for that, we use the number of views as arrays must always be contiguous. 

Additionally, there are five parameters unique to each view. The unique parameters are:

1. `kc`: Undistortion Coefficients
2. `KK`: View Intrinsics
3. `Rc`: Rotation Matrix
4. `Tc`: Translation Vector
5. `CF`: Path to the original calibration file &ndash; this is mainly just to keep track of what came from where

These are indexed according to the view label, as `kc_1` (distortion coefficeints for view 1) and Tc_3 (translation vector for view 3). Which view number corresponds to which view is subjective and up to you.

### Step 3: DLTdv8a Execution and Trackfile Generation

This step is fairly straightforward. Extensive video tutorials as well as written manuals on how to work with DLTdv8a are provided by the authors of the software. If you are just starting with the tool, we recommend that you start learning from the [official DLTdv8a online manual](https://biomech.web.unc.edu/dltdv8_manual/). You can also clone their [git repository](https://github.com/tlhedrick/dltdv) which contains additional information and the codebase. 

> The toolbox has only been tested with the app version of DLTdv8a.

- Open up the DLTdv8a app in the project root.
- Create a new project within DLTdv8a and load the videos. Generally, load order is important as it must correspond to the order of DLT coefficients (1st video uses 11 DLT coefficients in the first column of the csv file, 2nd video uses the 2nd column and so on). However, we have only one video, and the mirrors serve as our other two videos, so we can load the same file in twice or thrice for 2 or 3 views.
- When prompted, add the DLT coefficients file generated in the previous step.
- Create as many points as you want to track, and mark each one in the first video on the actual physical object.
- Each marked point generates an epipolar line in the other video frames. Assuming well-calibrated cameras, these are good hints for where the corresponding point is on the mirror views.
- Mark the corresponding points ON THE REFLECTIONS of the object in the second and third videos. If a point is not visible in any view, skip marking it for that view and it will become NaN, which is expected and handled by the toolbox's reconstruction scripts.
- Once the points are marked in all relevant views, set the tracking settings in the DLTdv8a interface according to your project's needs and begin tracking.
- Once you have a suitable tracked result, head to the Points tab in the main DLTdv8a dialog box and export points to begin generating the trackfiles.
- This will pop up a few confirmation boxes &ndash; the important one is that you export the points in "flat" format as sparse is not currently supported.
- Save the entire project DLTdv8a project as a matfile if you wish to do more work later or keep the full state of the project.

> Note that you may export the trackfiles anywhere on your device, but for your convenience, it would be best to place them in the trackfiles folder from the project root directory. You can also add any prefix when DLTdv8a asks you to.

The main trackfile that's relevant to us is `{prefix}xypts.csv`, which contains the framewise tracked 2D point (pixel) information for all views.

### Step 4: Tracked Point Reconstruction, Estimated World Coordinate Export in DLTdv8a Format

