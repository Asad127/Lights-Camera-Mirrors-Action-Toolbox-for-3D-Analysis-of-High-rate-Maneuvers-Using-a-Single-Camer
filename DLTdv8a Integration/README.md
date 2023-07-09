This functionality of the mirror reconstruction toolbox requires [DLTdv8a](https://biomech.web.unc.edu/dltdv/) tracking software, which allows working with moving objects by tracking them in recorded video data.

In conjunction with [Bouguet Calibration Toolbox (BCT)](http://robots.stanford.edu/cs223b04/JeanYvesCalib/), the toolbox allows for quickly setting up DLTdv8a-compatible projects with a camera and two-mirror setup.

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

2. Create a new project within DLTdv8a and load in the same video 2&ndash;3 times (for 2&ndash;3 views) *UNLESS* videos were undistorted in Step III, in which case load the differently undistorted videos.

    > Generally, load order is important as it must correspond to the order of DLT coefficients (1st video uses 11 DLT coefficients in the first column of the csv file, and so on). However, we have only one video, and the mirrors serve as our other two views in the same video. So, unless we undistorted the videos, we can load the same file in twice or thrice for 2 or 3 views.

3. When prompted, add the DLT coefficients file generated in Step II.

4. Create as many points as you want to track, and mark each one in the first video on the actual physical object.

5. Each marked point generates an epipolar line in the other video frames. Assuming well-calibrated cameras, these are good hints for where the corresponding point is on the mirror views.

6. Mark the corresponding points ON THE REFLECTIONS of the object in the second and third videos. If a point is not visible in any view, skip marking it for that view and it will become NaN, which is expected and handled by the toolbox's reconstruction scripts.

7. Once the points are marked in all relevant views, set the tracking settings in the DLTdv8a interface according to your project's needs and begin tracking.

8. Once you have a suitable tracked result, head to the directory where you would like to export the trackfiles, click on the Points tab in the main DLTdv8a dialog box, and export points to begin generating the trackfiles.

9. This will bring up a few confirmation boxes&mdash;the important one is that you export the points in "flat" format as the sparse format is currently not supported.

    DLTdv8a will generate around 4&ndash;5 files in the current directory. The main trackfile that's relevant to us is `{prefix}xypts.csv`, which contains the framewise tracked 2D point (pixel) information for all views.

    > Note that you may export the trackfiles anywhere on your device, but for convenience, it would be best to place them in the `trackfiles` folder from the project root directory. You can also add a prefix to the trackfiles when exporting them.

10. (OPTIONAL) Save the entire project DLTdv8a project as a matfile if you wish to do more work later or keep the full state of the project.

## **Step V: Tracked Point Reconstruction and DLTdv8a-Compatible Estimated World Coordinates Export**

Reconstruction may be performed using either the DLT file or the merged BCT calibration file, but currently the toolbox only supports the BCT variant as that preserves the view labels/identity (i.e., the index of the camera parameters corresponds exactly to the label of the view it belongs to regardless of the total number of views) as a secondary variable.

1. Run `reconstruct_tracked_pts_bct.m` inside the MATLAB command window from the project root directory. You will be prompted for a total of 4 things:

    - The merged BCT calibration results file (default: `bct_params.mat`) generated in Step II

    - The DLTdv8a 2D points trackfile (default: `{prefix}xypts.csv`) generated in Step V

    - Path to save the estimated 3D world points to (default: `reconstruction/{prefix}xyzpts.csv`)

        > The prefix is determined automatically from the 2D trackfile name `{prefix}xypts.csv`.

    - Whether to use undistorted video frames or not (only valid if the optional Step III was completed)

And that's it. The script will then estimate the 3D world coordinates for each tracked point in each view using non-linear least squares (`lsqnonlin`) with the **Levenberg-Marquardt** optimization algorithm. It will then reproject pixels on to the images using these estimated coordinates, reconstruct them in 3D, plot the cameras alongside the reconstructed points, and finally export them in DLTdv8a format.

#### ***Frame Mismatch Warning***

When selecting the 2D trackfile created in Step V, the script might produce a warning that the number of frames in the trackfile does not agree with the number of extracted frames. This generally happens when MATLAB's VideoReader (which we use to read frames) does not identify the same number of total frames as DLTdv8a. Usually, it's a matter of 1&ndash;2 frames near the end of the video.

This is usually not a problem if the last couple of frames are not important to you. the number of extracted frames is less than or equal to the number of frames detected by DLTdv8a. To be completely safe from indexing errors, however, you can manually delete the extra rows or extra frames from the trackfile or video frames directory, respectively (depending on which is greater).

# **(OPTIONAL) Step VI: Extrinsics Verification With Epipolar Geometry**
Exactly the same as in the repo root `README.md` file. Please refer to that for details.
