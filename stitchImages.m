function [ finalImage ] = stitchImages( images, homographies )
    center = ceil(length(images)/2);
    H_map{center} = eye(3);
    
    for i=(center+1):length(images)
        %H_map{i} = H_map{i-1}*homographies{i-1};
        H_map{i} = H_map{i-1}/homographies{i-1};
    end
    
    for i=(center-1):-1:1
        H_map{i} = H_map{i+1}*homographies{i+1};
        %H_map{i} = H_map{i+1}/(homographies{i+1}); % same as multiplying by the inverse
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
        pt_matrix = cat(3, [1,1,1]', [cols,1,1]', [1, rows,1]', [cols,rows,1]');

        % Map each of the 4 corner's coordinates into the coordinate system of the reference image
        for j=1:4
            %apply the homography to see how the corners will be affected
            %Note: H_map is a map of composed homographies
            foo = pt_matrix(:,:,j);
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
    %pan_image = zeros(im_rows, im_cols, 3);
    [pan_image, pan_mask] = expandImage( im2double(images{1}), H_map{1}, im_rows, im_cols, row_offset, col_offset );
    output = zeros(im_rows, im_cols, 3);
    
    for i=2:length(images)
        [cur_image, cur_mask] = expandImage( im2double(images{i}), H_map{i}, im_rows, im_cols, row_offset, col_offset );
        
        %NOTE: Perform the blending here instead of just overlaying the
        %       images.
        for x=1:im_cols
            for y=1:im_rows
                if (cur_mask(y,x) > 0)
                    pan_image(y,x,:) = cur_image(y,x,:);
                end
            end
        end

    end
    
    finalImage = im2uint8(pan_image);
    imwrite(finalImage,'panorama.jpg','jpg');
    
end


function [ expandedImage, imageMask ] = expandImage ( sIm, homography, rows, cols, rowOffset, colOffset )
    expandedImage = zeros(rows, cols, 3);
    imageMask = zeros(rows,cols);
    
    for y=1:rows
        for x=1:cols
            p = [x-colOffset; y-rowOffset; 1];
            p = homography\p; %calculate the original pixel location in the image
            
            % make sure the point is within the image bounds
            if and( and(p(1)>=1, p(1)<=size(sIm,2)), and(p(2)>=1, p(2)<=size(sIm,1)) )
                expandedImage(y,x,:) = sIm(round(p(2)),round(p(1)),:);
                imageMask(y,x) = 1;
            end
            
        end
    end
end