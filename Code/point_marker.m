%% SETUP %%
%{
Mark the corresponding points on a set of at least 2 or at most 3 images
corresponding to a single camera and 2-mirror setup.
%}

% The no. of points to click.
npoints = input("No. of points to mark: ");

% Input which images to use.
disp("Enter the image numbers in the form of a vector.") 
disp("For example, [7 8 9] for the 7th, 8th, and 9th images.")
imgs = input("Images to use (min 2, max 3): ");

% Input check!
n_views = numel(imgs);
if n_views > 3 || n_views == 1
    disp('[ERROR] Unsupported number of views. Enter exactly 2 or 3 images.')
    return
end

disp("Beginning the point marking process.")
xj = [];
% For each input image (view)...
for k = 1 : n_views
    fprintf("\t- View %d - Marking Points: ", k)
    % Indexing convenience - img no. `j` for k'th view
    j = imgs(k);

    % Load image and click points to estimate world coordinates of.
    figure(k);
    eval(['I = imread("Image' num2str(j) '.jpg");']);
    imshow(I); hold on;
    xlabel('x (pixel)'); ylabel('y (pixel)');

    if k == 1
        title(['View ' num2str(k) ' (Img ' num2str(j) ') - Click any ' num2str(npoints) ' points']);
    else
        title(['View ' num2str(k) ' (Img ' num2str(j) ') - Click on ' num2str(npoints) ' corresponding points']);
    end

    for i = 1 : npoints
        progress_msg = sprintf("%d/%d...", i, npoints);
        fprintf(progress_msg)
        num_chars = strlength(progress_msg);

        [x_click, y_click] = ginput(1);
        plot(x_click, y_click, 'm+', 'linewidth', 1, 'MarkerSize', 8);
        xj = [xj cat(2, x_click, y_click, 1)'];
        if i < npoints
            for c = 1 : num_chars
                fprintf("\b")
            end
        end
    end
    fprintf("done.\n")
    hold off;
end

% Save to disk and cleanup.
save("marked_points.mat", 'npoints', 'xj')
clear
close all
disp("All done! Check script directory for the results.")