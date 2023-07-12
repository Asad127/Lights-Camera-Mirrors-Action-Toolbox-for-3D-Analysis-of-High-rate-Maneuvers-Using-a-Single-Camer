This functionality of the mirror reconstruction toolbox additionally requires [DLTdv8a tracking software](https://biomech.web.unc.edu/dltdv/), which allows working with moving objects by tracking them over various frames in recorded video data.

As noted by the developers of DLTdv8a, some optional (but exciting) features require the MATLAB Image Analysis and Deep Learning toolboxes.

> *This is different from the repo's root `README.md` file, which only shares Steps I&ndash;III with this and describes the general process for reconstructing an object in a single image with manually marked points (i.e., DLTdv8a is not involved, while it is involved here).*

# **Instructions and Tutorials**
Given below is a list of video tutorials that cover the entire process of working with video data from scratch:

1. [Toolbox Initailization + Project Setup + Calibrating Setup With Videos and BCT](https://youtu.be/S_DW808hsZs)
2. [BCT Result Merging + DLTdv8a Format Conversion + Video Undistortion](https://youtu.be/-hg2HE2-30c)
3. [DLTdv8a Execution + Trackfile Generation](https://youtu.be/f6k406cfXcA)
4. [Estimating 3D World Points + Reconstructing Frame-by-Frame + Exporting World Points in DLTdv8a Format](https://youtu.be/x22F_YB5RK0)

Given below is a comprehensive step-by-step guide towards the workflow as well.

## **Step I: Toolbox Initialization + Project Setup + Calibrating Setup With BCT**

Exactly the same as in the repo root `README.md` file. Please refer to that for details.

## **Step II: Merging BCT Result and Coverting to DLTdv8a Format**

Exactly the same as in the repo root `README.md` file. Please refer to that for details.

## **Step III: Creating Test Images/Frames/Video + Importing + Undistortion**

Exactly the same as in the repo root `README.md` file. Please refer to that for details. We will take the video route in this case.

## **Step IV: DLTdv8a Execution and Trackfile Generation**

This step is fairly straightforward. Extensive video tutorials as well as written manuals on how to work with DLTdv8a are provided by the authors of the software. If you are just starting with the tool, we recommend that you start learning from the [official DLTdv8a online manual](https://biomech.web.unc.edu/dltdv8_manual/). You can also clone their [git repository](https://github.com/tlhedrick/dltdv) which contains additional information and the codebase.

> ***The toolbox has only been tested with the app version of DLTdv8a.***

1. Open up the DLTdv8a app in the project root.

    ![Opening up the DLTdv8a app](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/2b0874c5-f861-4694-9d6e-972308b8f2cb)

2. Create a new project within DLTdv8a and load in the same video 2&ndash;3 times (for 2&ndash;3 views) *UNLESS* videos were undistorted in Step III, in which case load the differently undistorted videos only.

    <p align="left">
        <img alt="Creating a new project" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6093dcd6-562b-4bc2-8090-cac06c520476" width = 48%> &nbsp;&nbsp;&nbsp;&nbsp; <img alt="Video Selection Context Menu" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/9f0ab121-e221-4e6c-8188-4f5bd6511042" width=30.75%>
    </p>

    ![Video Files Selection](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/5358a907-b6d6-42f3-8965-438d9ae7ed64)

    > Generally, load order is important as it must correspond to the order of DLT coefficients (1st video uses 11 DLT coefficients in the first column of the csv file, and so on). However, we have only one video, and the mirrors serve as our other two views in the same video. So, unless we undistorted the videos, we can load the same file in twice or thrice for 2 or 3 views.

3. When prompted if the cameras are calibrated, click **"Yes"** and add the DLT coefficients file generated in Step II.

    ![DLT Prompt](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/3420c76d-c47f-4073-8579-ef6deed92700)

    ![DLT Coefs File](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/c08ffee6-b455-468c-be27-ce9a67fb4a87)

4. Create as many points as you want to track by using the **Add Point** button, and mark each one in the first frame (or any frame of your choosing) of the first video on the actual object.

    ![DLTdv8a Add Point Button](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/e7a32039-299c-415d-9d04-b6cc9015072f)

5. Each marked point generates an epipolar line in the other videos for that frame. Assuming well-calibrated cameras, these are good hints for where the corresponding point is on the mirror views.

    ![Mirror View Epiline In Dltdv8a Passing Through Corresponding Point](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/2e101e9c-e2b1-4e92-8b00-2489ef4ec371)

6. Mark the corresponding points ON THE REFLECTIONS of the object in the second and (if available) third videos. If a point is not visible in any view, skip marking it for that view and it will become NaN, which is expected and handled by the toolbox's reconstruction scripts. When you mark a corresponding point, a green diamond indicating the reprojected pixel location from the estimated 3D point should appear assuming you provided the DLT coefficients in Step 3.

    ![Corresponding Points Marked](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/4b9cdd42-b009-4593-98cc-3619fd0d3dfa)

7. Once the points are marked in all relevant views for the first frame (or whichever frame you want to start at), set the tracking settings in the DLTdv8a interface according to your project's needs and begin tracking.

    ![All Points Marked](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/de174f1c-d811-4320-9218-b1c25ee3e639)

    ![DLTdv8a Settings For Multi-Tracking](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/871890c1-d8a7-4c0a-8b03-6f0e796f84b0)

8. Once you have a suitable tracked result, head to the directory where you would like to export the trackfiles, click on the Points tab in the main DLTdv8a dialog box, and export points to begin generating the trackfiles. A folder `trackfiles` should be in the project root directory, it is recommended to use it to store the trackfiles as it is the default expected location, allowing speedy file input resolutions.

    ![Tracked Result Zoomed In](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/ce10781c-0198-4f44-9e03-6e7876cecfcd)

    ![DLTdv8a Export Points Tab](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/9a96c02c-6f9f-492e-a378-23f240072008)

9. This will bring up a few confirmation boxes&mdash;the important one is that you export the points in "flat" format as the sparse format is currently not supported. DLTdv8a will generate around 4&ndash;5 files in the current directory. The main trackfile that's relevant to us is `{prefix}xypts.csv`, which contains the framewise tracked 2D point (pixel) information for all views.

    > You can also add a prefix to the trackfiles when exporting them, which is especially helpful if you are exporting multiple different sets of points.

    <p align="left">
        <img alt="Prefix Option" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/793c80eb-64d7-4430-b974-3740c8d9a3c9" width = 20%> &nbsp;&nbsp;&nbsp;&nbsp; <img alt="Sparse/Flat Format Export Menu" src="https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/0d88ee59-5204-48fd-a78d-98a6b00e7cb0" width=30%>
    </p>

    ![Generated Trackfiles](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/662fd3f0-1dd4-459b-b275-9cd2c25ed50b)

10. (OPTIONAL) Save the entire DLTdv8a project as a matfile (*Project Tab > Save as...*) if you wish to do more work later or keep the full state of the project.

## **Step V: Tracked Point Reconstruction and DLTdv8a-Compatible Estimated World Coordinates Export**

Reconstruction may be performed using either the DLT file or the merged BCT calibration file, but currently the toolbox only supports the BCT variant as that preserves the view labels/identity (i.e., the index of the camera parameters corresponds exactly to the label of the view it belongs to regardless of the total number of views) as a secondary variable.

1. Run `reconstruct_tracked_pts_bct.m` inside the MATLAB command window from the project root directory. You will be prompted for a total of 4 things:

    - The merged BCT calibration results file (default: `bct_params.mat`) generated in Step II

    - The DLTdv8a 2D points trackfile (default: `{prefix}xypts.csv`) generated in Step V

    - Path to save the estimated 3D world points to (default: `reconstruction/{prefix}xyzpts.csv`)

        > The prefix is determined automatically from the 2D trackfile name `{prefix}xypts.csv`.

    - Whether to use undistorted video frames or not (only valid if the optional undistortion in Step III was performed)

And that's it. The script will then estimate the 3D world coordinates for each tracked point in each view using non-linear least squares (`lsqnonlin`) with the **Levenberg-Marquardt** optimization algorithm. It will then reproject pixels on to the images using these estimated coordinates, reconstruct them in 3D, plot the cameras alongside the reconstructed points, and finally export them in DLTdv8a format.

![Estimating World Coordinates of Tracked Points and Reconstructing Them](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/6a167a49-ea79-4832-a1a7-cd56eaa5d1c4)

Below is the DLTdv8a format estimated world coordinates export. On the left, you have our result (with the Levenberg Marquardt algorithm), and on the right, you have DLTdv8a's result (with DLT + SVD Based Triangulation).

![Estimated 3D Points (Levenberg Marquardt, i.e., our implementation &ndash; DLT-based Triangulation With SVD, i.e., DLTdv8a implementation)](https://github.com/Asad127/Lights-Camera-Mirrors-Action-Toolbox-for-3D-Analysis-of-High-rate-Maneuvers-Using-a-Single-Camer/assets/94681976/46851acf-341f-4311-aff8-568ffe25a8be)

#### **Frame Mismatch Warning**

When selecting the 2D trackfile created in Step V, the script might produce a warning that the number of frames in the trackfile does not agree with the number of extracted frames. This generally happens when MATLAB's VideoReader (which we use to read frames) does not identify the same number of total frames as DLTdv8a. Usually, it's a matter of 1&ndash;2 frames near the end of the video.

Even if the warning appears, it is usually not a problem if the last couple of frames are not important to you. If you enter `y` on the warning's proceed prompt, the script will automatically assume that you are working on the minimum of the reported frames to avoid indexing errors.

# **(OPTIONAL) Step VI: Extrinsics Verification With Epipolar Geometry**
Exactly the same as in the repo root `README.md` file. Please refer to that for details.
