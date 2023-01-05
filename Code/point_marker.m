%% SETUP %%
clear;
close all;
clc;

% Load the calibration results.
npoints = 48;         % no. of points to click

% Input which images to use.
disp("When prompted, enter the image numbers in the form of a vector.") 
disp("For example, [1 5 10] for the 1st, 5th, and 10th image. Blank input means all.")
imgs_to_use = input("Which images to use? ([] = all): ");
if isempty(imgs_to_use)
    imgs_to_use = 1 : n_ima;
end
n_views = numel(imgs_to_use);
view = imgs_to_use;

xj = [];
% For each input image (view)...
for j = 1 : n_views
    k = view(j);  % indexing convenience - img no. for k'th view
    % Load image and click points to estimate world coordinates of.
    figure(j);
    eval(['I = imread("Image' num2str(k) '.jpg");']);
    imshow(I); hold on;
    xlabel('x (pixel)'); ylabel('y (pixel)');
    if j == 1
        title(['View ' num2str(j) ' (Img ' num2str(k) ') - Click any ' num2str(npoints) ' points']);
    else
        title(['View ' num2str(j) ' (Img ' num2str(k) ') - Click on ' num2str(npoints) ' corresponding points']);
    end
    for i = 1 : npoints
        [x_click, y_click] = ginput(1);
        plot(x_click, y_click, 'm+', 'linewidth', 1, 'MarkerSize', 8);
        xj = [xj cat(2, x_click, y_click, 1)']; 
    end
    hold off;
end
save("points_48_nimo_column.mat", 'npoints', 'xj')
close all
clear all