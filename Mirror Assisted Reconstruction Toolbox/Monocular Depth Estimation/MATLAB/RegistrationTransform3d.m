classdef RegistrationTransform3d
    %{
    The rigid (if scaling disabled) or similarity (if scaling enabled) transformation that maps the query points onto
    the target points.
    %}

    properties
        % The 4x4 homogeneous transformation matrix that maps query points onto target points.
        transformation_matrix double = eye(4)
        % The 3x3 rotation matrix that maps query points onto target points.
        rotation_matrix double = eye(3)
        % The 3x1 translation vector that maps query points onto target points.
        translation_vector double = zeros(3,1)
        % The scalar scaling factor that maps query points onto target points.
        scale_factor double = 1.0
    end
end