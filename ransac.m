function [ finalHomography, finalMatches ] = ransac( f1, d1, f2, d2 )


    numRandPoints = 4;
    numIterations = 5000;

    %im1Gray = image1;%single(rgb2gray(image1));
    %im2Gray = image2;%single(rgb2gray(image2));

    % f has the format [x;y;s;th], where each column is a keypoint
    %[f1, d1] = vl_sift(im1Gray);
    %[f2, d2] = vl_sift(im2Gray);

    % matches stores in the format [i1; i2], where each column is the index in
    % image1 and image2 descriptors
    % scores are a euclidian distance between the two
    [matches, scores] = vl_ubcmatch(d1, d2);
    
    finalHomography = [];
    finalMatches = [];
    topInlierCount = -1;

    for i=1:numIterations

        mess = sprintf('Iteration %d',i);
        %disp(mess);
        
        % start solving for a new homography hypothesis
        A = zeros(2*numRandPoints,8);
        b = zeros(2*numRandPoints,1);
        usedMatches = zeros(numRandPoints);
        k = 1;
        for j=1:numRandPoints
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
            finalMatches = inliers;
            topInlierCount = inlierCount;
            finalHomography = homo;
        end
        
    end %for i=1:numIterations
    
    % NOTE: Stuff below this line was supposed to calculate a new final
    % homography using all the inlier points. However, the homography it
    % was calculating was kind of crap, so we disabled it for now and just
    % went with the best homography that was found earlier.
    
    
%     disp('Best homography estimate:');
%     disp(finalHomography);
    
    % start solving for the final homography
%     A = zeros(2*size(finalMatches,1),8);
%     b = zeros(2*size(finalMatches,1),1);
%     k = 1;
%     for j=1:size(finalMatches,1)
% 
%         p1r = f1(2,finalMatches(j,1));
%         p1c = f1(1,finalMatches(j,1));
% 
%         p2r = f2(2,finalMatches(j,2));
%         p2c = f2(1,finalMatches(j,2));
% 
%         A(k,:) = [p1c p1r 1 0 0 0 (-p2c*p1c) (-p2c*p1r)];
%         b(k,1) = p2c;
% 
%         A(k+1,:) = [0 0 0 p1c p1r 1 (-p2r*p1c) (-p2r*p1r)];
%         b(k+1,1) = p2r;
% 
%         k = k + 2;
%     end
% 
%     %solve for the variables in the homography
%     x = A\b;
%     finalHomography = vec2mat(x,3,1);
%     
%     disp('Final homography estimate:');
%     disp(finalHomography);
    
    
    %some testing code
%     inlierCount = 0;
%     inliers = [];
%     for j=1:size(matches,2)
%         p1 = [f1(1,matches(1,j)); f1(2,matches(1,j)); 1];
%         p1 = finalHomography*p1;
% 
%         p2 = [f2(1,matches(2,j)); f2(2,matches(2,j)); 1];
% 
%         if ( ((p1(1)-p2(1))^2 + (p1(2)-p2(2))^2) <= 4)
%             inlierCount = inlierCount + 1;
%             inliers = [inliers; matches(1,j) matches(2,j)];
%         end
%     end
%     disp('Final Inlier count:');
%     disp(inlierCount);
    
%     im3 = appendimages(image1,image2);
%     figure('Position', [100 100 size(im3,2) size(im3,1)]);
%     colormap('gray');
%     imagesc(im3);
%     hold on;
%     cols1 = size(image1,2);
%     for i = 1: size(finalMatches,1)
%         line([f1(1,finalMatches(i,1)) (f2(1,finalMatches(i,2))+cols1)], ...
%             [f1(2,finalMatches(i,1)) f2(2,finalMatches(i,2))], 'Color', 'c');
%     end
%     hold off;

end

