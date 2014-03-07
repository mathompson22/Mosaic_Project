function [ finalImage ] = stitchImages( images, homographies )
    center = ceil(length(images)/2);
    H_map{center} = eye(3);
    
    for i=(center+1):length(images)
        H_map{i} = H_map{i-1}*homographies{i-1};
    end
    
    for i=(center-1):-1:1
        H_map{i} = H_map{i+1}/(homographies{i+1}); % same as multiplying by the inverse
    end
    
    
    % Compute size of output panorama image
    min_row = 1;
    min_col = 1;
    max_row = 0;
    max_col = 0;


    % Determine the dimensions of the panorama
    for i=1:length(images)
        cur_image = images{i};
        [rows,cols,~] = size(cur_image);

        % create a matrix with the coordinates of the four corners of the current image
        pt_matrix = cat(3, [1,1,1]', [1,cols,1]', [rows, 1,1]', [rows,cols,1]');

        % Map each of the 4 corner's coordinates into the coordinate system of the reference image
        for j=1:4
            %apply the homography to see how the corners will be affected
            %Note: H_map is a map of composed homographies
            result = H_map{i}*pt_matrix(:,:,j);

            %This determines the four corners of the panorama
            %Choose the minimum between your current row and the warped row
            %whichever is lowest, set that to the new minimum
            min_col = floor(min(min_col, result(1)));
            min_row = floor(min(min_row, result(2)));
            %similar logic applies to the max 
            max_col = ceil(max(max_col, result(1)));
            max_row = ceil(max(max_row, result(2))); 
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
    for i=1:length(images)
        %reads in unaltered image
        cur_image = im2double(images{i});

        % Create a list of all pixels' coordinates in output image
        [x,y] = meshgrid(1:im_cols, 1:im_rows);
        % Create list of all row coordinates and column coordinates in separate vectors, x and y, including offset
        x = reshape(x,1,[]) - col_offset;
        y = reshape(y,1,[]) - row_offset;

        % Create homogeneous coordinates for each pixel in output image
        pan_pts(1,:) = x;
        pan_pts(2,:) = y;
        pan_pts(3,:) = ones(1,size(pan_pts,2));

        % Perform inverse warp to compute coordinates in current input image
        image_coords = H_map{i}\pan_pts;
        row_coords = reshape(image_coords(2,:),im_rows, im_cols);
        col_coords = reshape(image_coords(1,:),im_rows, im_cols);

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
    finalImage = im2uint8(output);
    imwrite(finalImage,'panorama.jpg','jpg');
    
end

