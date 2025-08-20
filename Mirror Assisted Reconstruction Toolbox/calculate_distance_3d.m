function dist = calculate_distance_3d(point1, point2)
    % Calculate the Euclidean distance between two 3D points
    % Input: point1, point2 - 1x3 arrays containing [x, y, z] coordinates
    % Output: dist - scalar distance between the points
    
    % Compute differences in x, y, z coordinates
    delta = point2 - point1;
    
    % Calculate Euclidean distance
    dist = sqrt(sum(delta.^2));
end