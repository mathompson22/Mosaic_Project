function [ finalImage ] = stitchImages( images, imageMasks, homographies )
    disp('Running pre-stitching calculations');
    
    center = ceil(length(images)/2);
    
    % calculate the adjusted homography for each image based on the center
    % image being (0,0)
    H_map{center} = eye(3);
    
    %images to the right of the center
    for i=(center+1):length(images)
        H_map{i} = H_map{i-1}/homographies{i-1};
        H_map{i} = H_map{i}/H_map{i}(3,3);
    end
    
    %images to the left of the center
    for i=(center-1):-1:1
        H_map{i} = H_map{i+1}*homographies{i};
        H_map{i} = H_map{i}/H_map{i}(3,3);
    end
    
    % the final homography used to align the first and last images
    endHomography = H_map{length(images)}/homographies{length(images)};
    endHomography = endHomography/endHomography(3,3);
    
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
        pt_matrix = cat(3, [1,1,1]', [cols,1,1]', [1, rows,1]', [cols,rows,1]');

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
    disp('Stitching image 1');
    [pan_image, pan_mask] = expandImage( im2double(images{1}), imageMasks{1}, H_map{1}, im_rows, im_cols, row_offset, col_offset );
    output = zeros(im_rows, im_cols, 3);
    
    for i=2:length(images)
        mess = sprintf('Stitching Image %d',i);
        disp(mess);
        [cur_image, cur_mask] = expandImage( im2double(images{i}), imageMasks{i}, H_map{i}, im_rows, im_cols, row_offset, col_offset );
        
        %NOTE: Perform the blending here instead of just overlaying the
        %       images.
        for x=1:im_cols
            for y=1:im_rows
                if (cur_mask(y,x) > 0)
                    if (pan_mask(y,x) >0)
                        pan_image(y,x,:) = 0.5*pan_image(y,x,:) + 0.5*cur_image(y,x,:);
                    else
                        pan_mask(y,x) = 1;
                        pan_image(y,x,:) = cur_image(y,x,:);
                    end
                end
            end
        end
        
        %tempImg = im2uint8(pan_image);
        %imshow(tempImg);
    end
    
    [pan_image ~] = cropAndAlign(pan_image, pan_mask, ...
        images{1}, imageMasks{1}, H_map{1}, ...
        images{length(images)}, imageMasks{length(imageMasks)}, H_map{length(H_map)}, ...
        row_offset, col_offset, endHomography);
    
    finalImage = im2uint8(pan_image);
    imwrite(finalImage,'panorama.jpg','jpg');
    
end


function [ expandedImage, imageMask ] = expandImage ( sIm, sImMask, homography, rows, cols, rowOffset, colOffset )
    expandedImage = zeros(rows, cols, 3);
    imageMask = zeros(rows,cols);
    
    imgCols = size(sIm,1);
    imgRows = size(sIm,2);
    
    
    pt_matrix = cat(3, [1,1,1]', [imgCols,1,1]', [1, imgRows,1]', [imgCols,imgRows,1]');
    minRow = 1;
    minCol = 1;
    maxRow = 0;
    maxCol = 0;

    % Map each of the 4 corner's coordinates into the coordinate system of the reference image
    for j=1:4
        %apply the homography to see how the corners will be affected
        %Note: H_map is a map of composed homographies
        result = homography*pt_matrix(:,:,j);

        %This determines the four corners of the image in the panorama
        %Choose the minimum between your current row and the warped row
        %whichever is lowest, set that to the new minimum
        minCol = floor(min(minCol, result(1)));
        minRow = floor(min(minRow, result(2)));
        %similar logic applies to the max 
        maxCol = ceil(max(maxCol, result(1)));
        maxRow = ceil(max(maxRow, result(2))); 
    end
    
    minRow = rowOffset + minRow;
    maxRow = rowOffset + maxRow;
    
    minCol = colOffset + minCol;
    maxCol = colOffset + maxCol;
    
    for y=minRow:maxRow
        for x=minCol:maxCol
            p = [x-colOffset; y-rowOffset; 1];
            p = homography\p; %calculate the original pixel location in the image
            
            % make sure the point is within the image bounds
            if and( and(p(1)>=1, p(1)<=size(sIm,2)), and(p(2)>=1, p(2)<=size(sIm,1)) )
                if (sImMask(round(p(2)),round(p(1))) > 0) % only use this part of the image if it wasn't previously masked by the cylinder warp
                    expandedImage(y,x,:) = sIm(round(p(2)),round(p(1)),:);
                    imageMask(y,x) = 1;
                end
            end
            
        end
    end
end


function [ croppedImg, croppedMask ] = cropAndAlign( panImg, panMask, ...
    firstImg, firstMask, firstHomo, ...
    lastImg, lastMask, lastHomo, ...
    rowOffset, colOffset, edgeHomo )
    
    
    imgCols = size(lastImg,2);
    imgRows = size(lastImg,1);
    pt_matrix = cat(3, [1,1,1]', [imgCols,1,1]', [1, imgRows,1]', [imgCols,imgRows,1]');
    
    %find x_max from the last image
    p = [size(lastImg,2); 1; 1];
    p = lastHomo*p;
    x_max = ceil(p(1));
    p = [size(lastImg,2); size(lastImg,1); 1];
    p = lastHomo*p;
    x_max = ceil(max(x_max,p(1)));
    x_max = colOffset + x_max;
    
    %find x_min and y_actual from the first image
    p = [1; 1; 1];
    p = firstHomo*p;
    x_min = floor(p(1));
    y_actual = rowOffset + floor(p(2));
    p = [1; size(lastImg,2); 1];
    p = firstHomo*p;
    x_min = floor(min(x_min,p(1)));
    x_min = colOffset + x_min;
    
    %find x_est and y_est based on repeating the first image at the end
    p = [1; 1; 1];
    p = edgeHomo*p;
    x_est = ceil(p(1) + colOffset);
    y_est = ceil(p(2) + rowOffset);
    x_diff = x_max - x_est;
    y_diff = y_actual - y_est;
    
    %crop the sides of the image
    crop1 = panImg(:, x_min:(x_max-x_diff), :);
    crop1Mask = panMask(:, x_min:(x_max-x_diff));
    
    %perform a linear shift in the y direction based on x
    shiftedImg = zeros(size(crop1,1)+abs(y_diff),size(crop1,2),3);
    shiftedMask = zeros(size(crop1,1)+abs(y_diff),size(crop1,2));
    finalWidth = x_max - x_diff - x_min;
    a = -y_diff/finalWidth;
    y_adj = min(0,y_diff); %if the y_diff is negative we need to shift things down
    for x=1:size(crop1,2)
        for y=1:size(crop1,1)
            if (crop1Mask(y,x) > 0 )
                yPrime = y - floor(a*x);
                shiftedImg(yPrime-y_adj,x,:) = crop1(y,x,:);
                shiftedMask(yPrime-y_adj,x) = 1;
            end
        end
    end
    
    %crop the height of the final shifted image
    y_crop_min = 1;
    while (sum(shiftedMask(y_crop_min,:)) == 0) 
        y_crop_min = y_crop_min + 1; 
    end
    
    y_crop_max = size(shiftedMask,1);
    while (sum(shiftedMask(y_crop_max,:)) == 0)
        y_crop_max = y_crop_max - 1;
    end
    
    croppedImg = shiftedImg(y_crop_min:y_crop_max,:,:);
    croppedMask = shiftedMask(y_crop_min:y_crop_max,:);
    
    
end

