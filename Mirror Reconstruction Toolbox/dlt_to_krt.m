function [K, Rc, Tc] = dlt_to_krt(dlt)
%{
Most of this function is just comments.

Recovering KRT from DLT. Our case is simple since the image and camera
conventions in the Bouguet Calibration Toolbox are the same as MATLAB's.
Otherwise, some transformation would be required to ensure proper results.
Refer to algorithm explanation below for more detail on the conventions.

This would allow reconstructing with DLT coefficients. However, since we
cannot embed view labels into the DLT file due to the specific format
required by DLTdv8a, we cannot maintain view integrity in reconstruction.
If view integrity is not of interest, however, it's fine to reconstruct
with DLT coefficients.

To understand what we mean by view integrity, consider that you have just
two views. The first view is from the camera, and the second is from the
second mirror. In this case, following the typical view naming conventions,
we would get view labels 1 (camera) and 3 (second mirror). However, in DLT
coefficients file, there can be no index gap between columns (each column
has the 11 DLT coefficients minus the 12th one, which depicts arbitrary 
scale and is normalized to unity). Thus, you would have the first 2 columns
corresponding to the first and third view, and there is no way to tell that
the second column actually belonged to the second mirror. Similar issues
arise when we have first and second mirrors (view labels 2 and 3).

A higher-level fix for this is to export view labels for the calibration
into a separate mat-file, rather than making it exclusive to the BCT merged
calibration results. This would require adjusting some scripts, unless we
keep the view labels in the BCT file as they already are.

TAKES
=====
dlt:
    The 11 normalized DLT coefficients/params as fed to DLTdv8a, and
    computed from krt2dlt.m

RETURNS
=======
K:
    The camera's intrinsics (may be virtual as long as DLT were computed
    correctly.
Rc:
    The rotation mapping the world frame axes to the camera frame axes.
Tc:
    The translation from camera frame origin to world frame origin in
    camera coordinates.

NOTES
=====
KRT Usage: x = K * [Rc Tc] * X, where X are the 3D world coordinates.

ALGORITHM EXPLANATION
===========================================================================
SOURCE: https://ksimek.github.io/2012/08/14/decompose/
Detail of the algorithm as we understand it follows.
===========================================================================
Let world frame origin be worg, camera frame origin be corg, Rc be the
rotation matrix such that it aligns the world frame to the camera frame, 
and let Tc be the coordinates of the world origin in camera coordinates. 
Then, Tw is its inverse, such that:

Tw = -Rc' * Tc => Tc = -(Rc')_inv * Tw.

Since Rc is orthognal, Rc_inv = Rc', and (Rc'_inv) = (Rc')' = Rc. Thus:

Tc = -Rc * Tw -- [EQUATION 1]

Thus, x = PX = K * [Rc Tc] * X. In any case, all that's important here is
that Rc and Tc are both in the camera frame of reference.

Now, we have P as a 3x4 matrix such that all of its elements are the DLT 
parameters. The 12th parameter is the depth scale, so we can discard that.

We are uninterested in estimating DLT params since we have K, R, and T, 
which makes going to DLT quite simple (with the Bouguet convetions).

    p11 p12 p13 p14
P = p21 p22 p23 p24
    p31 p32 p33 p34

P = K * [Rc Tc]
P = [K*Rc | K*Tc], where K*Rc is 3x3 * 3x3 = 3x3 and K*Tc is 3x3 * 3x1 = 3x1.

Using [EQUATION 1], we can get K*Rc on the vector block as:

P = [K*R | K*(-Rc*Tw)] = [K*Rc | -K*Rc*Tw]

Let M = K*Rc and Tw = C, the camera center in world coordinates. Then:

P = [M | -M*C]. Here:

         p11 p12 p13                     p14
KR = M = p21 p22 p23  ; K*Rc*Tw = -M*C = p24
         p31 p32 p33                     p34

As M is 3x3 and invertible (both R and K are invertible), so:

C = -M_inv * -M * C -- [EQUATION 2]

But this is not equal to Tc from the calibration toolbox, as that's defined
in camera coordinates and C is in world coordinates. Once we have Rc, we 
can use [EQUATION 1] to get Tc. 

Now, we need to find the values of K and Rc. We do that by RQ decomposition 
of M. RQ decomposition decomposes a matrix into a upper/right triangular 
part R and an orthognal part Q. This works for us, since K is upper
triangular and Rc is orthognal.

Sadly, MATLAB does not provide a function for RQ decomposition, but it does
provide QR decomposition. The difference here is the multiplication order 
of the decomposed parts. We require that the upper triangular be left 
multiplied with the orthognal part as it is K * Rc (i.e., RQ), and not 
Rc * K, which is what QR would give us.

Implementation wise, QR starts the orthognalization process from the first
column, and RQ starts from the last row (as per the following link):
https://en.wikipedia.org/wiki/QR_decomposition#Relation_to_RQ_decomposition

So we can kind of force QR(M) to act like RQ(M) if we bring the last row of
M to the first column. This is done by vertically flipping M which makes 
the last row the first, followed by a transpose which makes it the first
column. Let's call this modifed matrix M`.

QR(M`) now gives us the Q` and R`, which are our Rc` and K`, respectively. 
Since M` is not according to the original conventions, we need to undo our
our transformations to get the actual K and Rc from K` and Rc`. So first, 
we un-transpose, and then, we un-flip. 

Q`*R` = M`
R*Q = K*Rc = M 

For some intuition, suppose X, Y, Z, +, o, and x, are references just to 
keep track of things.
---------------------------------------------------------------------------
    + + +             X Y Z                X x +
M = x x x => flipud = x x x => transpose = Y x + = M`
    X Y Z             + + +                Z x +

     X Y Z                X x x              Z x x
Q` = x x x => transpose = Y x x => flipud => Y x x = Q = Rc
     + + +                Z x x              X x x

     X x x                X o o             x x Z             Z x x
R` = o Y x => transpose = x Y o => flipud = x Y o => fliplr = o Y x = R = K
     o o Z                x x Z             X o o             o o X
---------------------------------------------------------------------------
And so, K and R are corrected. Note that K may be scaled unless the DLT 
params were normalized, so normalize it  w.r.t. K(3,3) just to be safe. R`
needed an additional fliplr to keep the upper triangular property.

Since this RQ decomposition is not unique, enforce +ve diagonal entries of 
K. Our camera conventions from BCT match the image conventions, so this is
not a problem as we will always have +ve focal lengths.

We create a diagonal matrix D with negative values along the diagonal 
indicating the corresponding -ve entries along the K diagonal, as with
D = diag(signum(diag(K))). Thus, negative terms in K are multiplied by -1,
making them +ve. Since M = K * R, K * D * D_inv * R = KR. This D is self-
inverting i.e., in D*D, all +ve entires are multiplied by +ve entries 
and all-ve entries are multiplied by -ve entries, so end result = I since
all entries are unity. So, we need K = K * D, Rc = D * Rc - no need to 
invert diag for R.

Finally, using [EQUATION 1], we can now get Tc using the value of Tw = C
from [EQUATION 2]:

Tc = -Rc * Tw = -Rc * C
%}

M = dlt(:, 1:3);  % M = K*Rc
MC = dlt(:, 4);   % -MC = -K*Rc*Tw, Tw = C (camera center in world frame)
C = -M \ MC;      % -M_inv * -M * C = I * C = C = Tw

% QR decompose on transformed M. R is upper-triangular, Q is orthognal.
[Q, R] = qr(flipud(M)');  
K = R;
Rc = Q;

% Undo transformations to recover actual RQ decomposition.
K = K';        
K = flipud(K);  
K = fliplr(K);  
Rc = Rc';                
Rc = flipud(Rc);  

% Force positive diagonals for K and normalize it w.r.t. (3,3) element.
diagonal_posifier = diag(sign(diag(K)));  
K = K * diagonal_posifier;
Rc = diagonal_posifier * Rc;
Tc = -Rc * C;
K = K / K(3, 3);            

% Manually set skew to zero. It should be extremely small (below 1e-10).
% if abs(K(1, 2)) < 1e-10
%     fprintf("Skew < 1e-10. The extracted intrinsics and extrinsics are probably fine.\n")
% else
%     fprintf("WARNING: Skew > 1e-10.") 
%     fprintf("The intrinsics and extrinsics may not have been recovered correctly.\n")
% end
K(1, 2) = 0;

return

end