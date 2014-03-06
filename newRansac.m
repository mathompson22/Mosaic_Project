function [ finalHomography, finalMatches ] = newRansac( image1, image2 )

    run('./vlfeat-0.9.18/toolbox/vl_setup');

    numRandPoints = 4;
    numIterations = 3000;

    im1Gray = single(rgb2gray(image1));
    im2Gray = single(rgb2gray(image2));

    % f has the format [x;y;s;th], where each column is a keypoint
    [f1, d1] = vl_sift(im1Gray);
    [f2, d2] = vl_sift(im2Gray);

    % matches stores in the format [i1; i2], where each column is the index in
    % image1 and image2 descriptors
    % scores are a euclidian distance between the two
    [matches, scores] = vl_ubcmatch(d1, d2)
    
    finalHomography = [];
    finalMatches = [];
    topInlierCount = -1;

    for i=1:numIterations

        mess = sprintf('Iteration %d',i);
        disp(mess);
        
        % start solving for a new homography hypothesis
        A = zeros(3*numRandPoints,8);
        b = zeros(3*numRandPoints,1);
        usedMatches = zeros(numRandPoints);
        k = 1;
        for j=1:numRandPoints
            %select a random point from image 1 that hasn't been used yet
            nextRand = randi(size(matches,2));
            while (ismember(nextRand,usedMatches))
                nextRand = randi(size(matches,2));
            end
            usedMatches(j) = nextRand;

            p1r = f1(2,matches(1,nextRand));
            p1c = f1(1,matches(1,nextRand));

            p2r = f2(2,matches(2,nextRand));
            p2c = f2(1,matches(2,nextRand));

            A(k,:) = [p1c p1r 1 0 0 0 (-p2c*p1c) (-p2c*p1r)];
            b(k,1) = p2c;

            A(k+1,:) = [0 0 0 p1c p1r 1 (-p2r*p1c) (-p2r*p1r)];
            b(k+1,1) = p2r;

            k = k + 2;
        end
        
        %solve for the variables in the homography
        x = A\b;
        homo = vec2mat(x,3,1);
        
        
        inlierCount = 0;
        inliers = [];
        for j=1:size(matches,2)
            p1 = [f1(1,matches(1,j)); f1(2,matches(1,j)); 1];
            p1 = homo*p1;
            
            p2 = [f2(1,matches(2,j)); f2(2,matches(2,j)); 1];
            
            if ( ((p1(1)-p2(1))^2 + (p1(2)-p2(2))^2) <= 4)
                inlierCount = inlierCount + 1;
                inliers = [inliers; matches(1,j) matches(2,j)];
            end
        end
        
        if (inlierCount > topInlierCount)
            finalMatches = inliers
            topInlierCount = inlierCount
            finalHomography = homo
        end
        
    end %for i=1:numIterations
    
    im3 = appendimages(image1,image2);
    figure('Position', [100 100 size(im3,2) size(im3,1)]);
    colormap('gray');
    imagesc(im3);
    hold on;
    cols1 = size(image1,2);
    for i = 1: size(finalMatches,1)
        line([f1(1,finalMatches(i,1)) (f2(1,finalMatches(i,2))+cols1)], ...
            [f1(2,finalMatches(i,1)) f2(2,finalMatches(i,2))], 'Color', 'c');
    end
    hold off;

end

