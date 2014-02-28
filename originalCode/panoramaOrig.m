function output = panoramaOrig(imagepath)
% Process input imagepath
files = dir(imagepath);
imagelist = files(3:end);

for i=1:length(imagelist)-1
    image1 = imagelist(i).name;
    image2 = imagelist(i+1).name;
    
    % Find matching feature points between current two images using SIFT
    [~, matchIndex, loc1, loc2] = match(image1, image2);
    im1_ftr_pts = loc1(find(matchIndex > 0), 1 : 2);
    im2_ftr_pts = loc2(matchIndex(find(matchIndex > 0)), 1 : 2);

    % Calculate 3x3 homography matrix, H, mapping coordinates in image2 into coordinates in image1
    H = calcH(im1_ftr_pts, im2_ftr_pts);
    H_list(i) = {H};
end

% Select one input image as the reference image (first image)
new_H = eye(3);
H_map(1) = {new_H};

% Generate new homographies that map every other image directly to the reference image by composing H matrices in H_list
for i=1:length(H_list)
    new_H = new_H * H_list{i};
    H_map(i+1) = {new_H};
end

% Compute size of output panorama image
min_row = 1;
min_col = 1;
max_row = 0;
max_col = 0;

% for each input image
for i=1:length(H_map)
    cur_image = imread(imagelist(i).name);
    [rows,cols,~] = size(cur_image);
    
    % create a matrix with the coordinates of the four corners of the current image
    pt_matrix = cat(3, [1,1,1]', [1,cols,1]', [rows, 1,1]', [rows,cols,1]');
    
    % Map each of the 4 corner's coordinates into the coordinate system of the reference image
    for j=1:4
        result = H_map{i}*pt_matrix(:,:,j);
    
        min_row = floor(min(min_row, result(1)));
        min_col = floor(min(min_col, result(2)));
        max_row = ceil(max(max_row, result(1)));
        max_col = ceil(max(max_col, result(2))); 
    end
    
end

% Calculate output image size
im_rows = max_row - min_row + 1;
im_cols = max_col - min_col + 1;

% Calculate offset of the upper-left corner of the reference image relative to the upper-left corner of the output image
row_offset = 1 - min_row;
col_offset = 1 - min_col;

% Initialize output image to black (0)
pan_image = zeros(im_rows, im_cols, 3);


output = zeros(im_rows, im_cols, 3);

% Perform inverse mapping for each input image
for i=1:length(H_map)
    cur_image = im2double(imread(imagelist(i).name));

    
    % Create a list of all pixels' coordinates in output image
    [x,y] = meshgrid(1:im_cols, 1:im_rows);
    % Create list of all row coordinates and column coordinates in separate vectors, x and y, including offset
    x = reshape(x,1,[]) - col_offset;
    y = reshape(y,1,[]) - row_offset;
    
    % Create homogeneous coordinates for each pixel in output image
    pan_pts(1,:) = y;
    pan_pts(2,:) = x;
    pan_pts(3,:) = ones(1,size(pan_pts,2));
    
    % Perform inverse warp to compute coordinates in current input image
    image_coords = H_map{i}\pan_pts;
    row_coords = reshape(image_coords(1,:),im_rows, im_cols);
    col_coords = reshape(image_coords(2,:),im_rows, im_cols);

    % Bilinear interpolate color values
    pixel_color_r = interp2(cur_image(:,:,1), col_coords, row_coords, 'linear', 0);
    pixel_color_g = interp2(cur_image(:,:,2), col_coords, row_coords, 'linear', 0);
    pixel_color_b = interp2(cur_image(:,:,3), col_coords, row_coords, 'linear', 0);
    
    pan_image(:,:,1) = pixel_color_r;
    pan_image(:,:,2) = pixel_color_g;
    pan_image(:,:,3) = pixel_color_b;

    %Store warped images for blending below
    warped_im(i) = {pan_image};
  
    output = output+pan_image;
    
    %Blend
    if (i > 1)
        diff = rgb2gray(warped_im{i-1}) & rgb2gray(warped_im{i});
        inv = imcomplement(diff);
        
        %Create weights 
        weightLeft = 1 : -1/(size(output,2)-1) : 0;
        weightLeftMatrix = repmat(weightLeft, size(output,1), 1);
        weightRight = 1 - weightLeft;
        weightRightMatrix = repmat(weightRight, size(output,1), 1);
        
        %Extract overlap first image and apply weight
        r_right = (warped_im{i-1}(:,:,1).*diff).*weightRightMatrix;
        g_right = (warped_im{i-1}(:,:,2).*diff).*weightRightMatrix;
        b_right = (warped_im{i-1}(:,:,3).*diff).*weightRightMatrix; 
        
        rightOverlap(:,:,1) = r_right;
        rightOverlap(:,:,2) = g_right;
        rightOverlap(:,:,3) = b_right;
        
        %Extract overlap from second image and apply weight
        r_left = (warped_im{i}(:,:,1).*diff).*weightLeftMatrix;
        g_left = (warped_im{i}(:,:,2).*diff).*weightLeftMatrix;
        b_left = (warped_im{i}(:,:,3).*diff).*weightLeftMatrix;
        
        leftOverlap(:,:,1) = r_left;
        leftOverlap(:,:,2) = g_left;
        leftOverlap(:,:,3) = b_left;
        
        %Remove overlap from panorama
        output(:,:,1) = output(:,:,1).*inv;
        output(:,:,2) = output(:,:,2).*inv;
        output(:,:,3) = output(:,:,3).*inv;
        
        %Replace with weighted/blended overlaps
        output = output + rightOverlap + leftOverlap;
    end

end
output = im2uint8(output);
imwrite(output,'panorama.jpg','jpg');
end

