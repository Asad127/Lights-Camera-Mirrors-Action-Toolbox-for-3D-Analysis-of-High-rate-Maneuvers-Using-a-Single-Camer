classdef RegistrationMetrics3d
    %{
    Error metrics between the registered query points and the target points.

    Attributes:
        max_error (double): Maximum squared Euclidean distance between corresponding points.
        lse_error (double): Least squares error (sum of squared Euclidean distances).
        mse_error (double): Mean squared error (LSE divided by number of points).
        rms_error (double): Root mean square error (square root of MSE).
    %}
    properties
        max_error double = NaN
        lse_error double = NaN
        mse_error double = NaN
        rms_error double = NaN
    end

    methods
        function obj = RegistrationMetrics3d(registered_query_points, points_target)
            %{
            Constructor for RegistrationMetrics3d.

            Parameters
            ----------
            registered_query_points : double, optional
                Aligned query points, shape (3, N) or (N, 3).
            points_target : double, optional
                Target points, shape (3, N) or (N, 3).
            %}
            if nargin == 2
                obj = obj.compute_metrics(registered_query_points, points_target);
            end
            % If nargin == 0, properties remain NaN as initialized by default.
        end

        function obj = compute_metrics(obj, registered_query_points, points_target)
            %{
            Compute error metrics between registered query points and target points.
            %}

            if nargin < 3 || ...
               isempty(registered_query_points) || isempty(points_target) || ...
               (isnumeric(registered_query_points) && size(registered_query_points, 2) == 0 && size(registered_query_points, 1) ~= 3) || ... % handles 0x0, 0xN cases
               (isnumeric(points_target) && size(points_target, 2) == 0 && size(points_target, 1) ~= 3) || ...
               (isnumeric(registered_query_points) && size(registered_query_points, 1) == 3 && size(registered_query_points, 2) == 0) || ... % handles 3x0
               (isnumeric(points_target) && size(points_target, 1) == 3 && size(points_target, 2) == 0)

                obj.max_error = NaN;
                obj.lse_error = NaN;
                obj.mse_error = NaN;
                obj.rms_error = NaN;
                return;
            end

            % Ensure inputs are numeric before size checks
            if ~isnumeric(registered_query_points) || ~isnumeric(points_target)
                error('Inputs must be numeric arrays.');
            end

            % Validate and reshape to (3, N).
            if size(points_target, 1) ~= 3
                if size(points_target, 2) == 3
                    points_target = points_target';
                else
                    error('Target points must be 3xN or Nx3. Given size: %s', mat2str(size(points_target)));
                end
            end
            if size(registered_query_points, 1) ~= 3
                if size(registered_query_points, 2) == 3
                    registered_query_points = registered_query_points';
                else
                    error('Query points must be 3xN or Nx3. Given size: %s', mat2str(size(registered_query_points)));
                end
            end

            % Ensure arrays have the same shape (3,N) after potential transpose.
            if ~isequal(size(registered_query_points), size(points_target))
                error('Point sets must have the same shape (3xN) after normalization. Query: %s, Target: %s', ...
                    mat2str(size(registered_query_points)), mat2str(size(points_target)));
            end

            num_points = size(registered_query_points, 2);
            if num_points == 0 % This case should be caught earlier, but good to have.
                obj.max_error = NaN; obj.lse_error = NaN;
                obj.mse_error = NaN; obj.rms_error = NaN;
                return;
            end

            differences = registered_query_points - points_target;
            squared_distances = sum(differences.^2, 1);

            obj.max_error = max(squared_distances);
            obj.lse_error = sum(squared_distances);
            obj.mse_error = obj.lse_error / num_points;
            obj.rms_error = sqrt(obj.mse_error);
        end

        function metrics_dict = get_metrics_as_dict(obj)
            %{
            Return metrics as a dictionary (struct in MATLAB).
            %}
            metrics_dict = struct(...
                'max_error', obj.max_error, ...
                'lse_error', obj.lse_error, ...
                'mse_error', obj.mse_error, ...
                'rms_error', obj.rms_error ...
            );
        end
    end
end