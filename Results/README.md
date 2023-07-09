To reproduce these results, you must follow the single image reconstruction procedure described in the repo's root `README.md`, and in the following playlist of tutorial videos:

*R1.jpg* and *R2.jpg* are the same image, with a different number of marked points. *R3*, *R4*, and *R5.jpg*, on the other hand, are all unique images.

*R1.jpg* and *R2.jpg* represent the test image *1.jpg* in the `Test Images` folder. Afterwards, *R3.jpg* &rarr; *2.jpg*, *R4.jpg* &rarr; *3.jpg*, and *R5.jpg* &rarr; *4.jpg*.

# Marked Points

You can find the marked points files in the `Marked 2D Points` folder in the repo root, or you can mark them yourself with `point_marker.mat` (requires calibration to enable hsitory and ensure correct view labeling &ndash; might add a version that does not need it in the future).

The marked points are indexed according to the `R` indexing series above. So, *P1.mat* corresponds to *R1.jpg*, *P2* to *R2*, and so on.

Note that, except *P4.mat* which has an undistorted version, **all the points are marked on NON-UNDISTORTED IMAGES**, so if you try to get the results on undistorted images for those, you'll get bad results. However, all the rest of the steps in the process remain the same, just press no whenever asked for undistorted images if you are using these pre-marked points.