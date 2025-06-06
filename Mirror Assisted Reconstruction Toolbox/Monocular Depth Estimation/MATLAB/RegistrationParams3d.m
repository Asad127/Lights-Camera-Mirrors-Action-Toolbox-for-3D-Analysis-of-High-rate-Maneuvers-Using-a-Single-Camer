classdef RegistrationParams3d
    %{
    Result of 3D registration.
    %}

    properties
        % Original query points, registered onto the target points.
        registered_query_points double = []
        % Transform mapping the query points onto the target points.
        transform RegistrationTransform3d = RegistrationTransform3d()
        % Error metrics between the registered query points and the target points.
        metrics RegistrationMetrics3d = RegistrationMetrics3d()
    end
end