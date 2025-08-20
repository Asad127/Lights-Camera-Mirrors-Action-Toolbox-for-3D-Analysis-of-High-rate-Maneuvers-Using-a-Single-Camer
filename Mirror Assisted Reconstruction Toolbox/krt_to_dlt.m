function dlt = krt_to_dlt(K, Rc, Tc)
%{
Computes DLT in DLTdv8a compatible format using the intirnsics (K) and 
extrinsics (R & T) from Bouguet Calibration Toolbox. The returned DLT 
contains 11/12 parameters as a row-major flattened column vector, suitable 
for writing a csv file as needed by DLTdv8a. 

The 12th parameter (arbitrary scale) is used to normalize the DLT vector
and discarded afterwards. If you need to use it, append 1 to the returned
vector.

TAKES
=====
K:
    The camera intrinsics.
Rc:
    The rotation matrix mapping the world frame axes to camera frame axes.
Tc:
    The translation from camera frame origin to world frame origin in
    camera coordinates.

RETURNS
=======
dlt:
    11 normalized DLT parameters in flattened form as accepted by DLTdv8a. 
    The 12th scale element is equal to 1 and discarded.

EXPLANATION
===========================================================================
Note that camera matrix P from x = PX:

P = p11 p12 p13 p14
    p21 p22 p23 p24
    p31 p32 p33 p34

DLT = [p11 p12 p13 p14 p21 p22 p23 p24 p31 p32 p33 p34], where p34 = scale.

DLT is the ROW-MAJOR FLATTENED version of P. Default MATLAB reshape is
COLUMN-MAJOR instead, i.e.,

P(:) = [p11 p21 p31 p12 p22 p32 p13 23 p33 p14 p24 p34], which is wrong.

We can force the row-major by transposing P before flattening.

P' =  p11 p21 p31
      p12 p22 p32
      p13 p23 p33
      p14 p24 p34

P'(:) = [p11 p12 p13 p14 p21 p22 p23 p24 p31 p32 p33 p34], which is right.
%}

switch nargin
    case 0
        error("Missing intrinsics KK and extrinsics in the form of a rotation " + ...
            "matrix and translation vector Rc_x and Tc_x respectively," + ...
            "where x is an integer corresponding to the reference image number from BCT calibration.");
    case 1
        error(['Missing extrinsics in the form of a rotation matrix and ' ...
            'translation vector Rc_x and Tc_x respectively, where x is an ' ...
            'integer corresponding to the reference image number from BCT calibration.']);
    case 2
        error(['Missing translation vector Tc_x, where x is an integer ' ...
            'corresponding to the reference image number from BCT calibration.'])
end

dlt = K * [Rc Tc];
dlt = dlt/dlt(3,4);  
dlt = dlt';          
dlt = reshape(dlt, [], 1);        
dlt = dlt(1:11);

return

end