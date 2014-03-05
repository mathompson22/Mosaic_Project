


function [ homography, matches ] = ransac( image1, image2 )

%The number of keypoints to randomly select with SIFT
numRandPoints = 4;
numIterations = 150;

% Find SIFT keypoints for each image
[im1, des1, loc1] = sift(image1);
[im2, des2, loc2] = sift(image2);
showkeys(im1,loc1);
showkeys(im2,loc2);
% disp(loc1);

[maxY, maxX] = size(im2);
maxX = maxX + 3;
maxY = maxY + 3;

homography = [];
matches = [];
topMatchCount = -1;

for j=1:numIterations

    mess = sprintf('Iteration %d',j);
    disp(mess);
    matchCount = 0;
    myMatches = [];
    

    A = zeros(3*numRandPoints,8);
    b = zeros(3*numRandPoints,1);
    usedPoints1 = zeros(numRandPoints);
    usedPoints2 = zeros(numRandPoints);
    k = 1;
    for i=1:numRandPoints
        %select a random point from image 1 that hasn't been used yet
        nextRand = randi(size(loc1,1));
        while (ismember(nextRand,usedPoints1))
            nextRand = randi(size(loc1,1));
        end
        usedPoints1(i) = nextRand;
        
        %set values for the A matrix
        p1r = loc1(nextRand,1);
        p1c = loc1(nextRand,2);

        A(k,1) = p1c;
        A(k,2) = p1r;
        A(k,3) = 1;
        A(k+1,4) = p1c;
        A(k+1,5) = p1r;
        A(k+1,6) = 1;
        A(k+2,7) = p1c;
        A(k+2,8) = p1r;

        %select a random point from image 2 that hasn't been used yet
        nextRand = randi(size(loc2,1));
        while (ismember(nextRand,usedPoints2))
            nextRand = randi(size(loc2,1));
        end
        usedPoints2(i) = nextRand;
        
        %set values for the b matrix
        p2r = loc2(nextRand,1);
        p2c = loc2(nextRand,2);

        b(k,1) = p2c;
        b(k+1,1) = p2r;

        k = k + 3;

    end

    %solve for the variables in the homography
    x = A\b;
    nextHomo = vec2mat(x,3,1);
    
    
    for i=1:size(loc1)
        
        %if we didn't use this point for the homography
        if (~ismember(i,usedPoints1))
            %find the adjusted point location
            p1 = [loc1(i,2); loc1(i,1); 1];
            p1 = nextHomo*p1;
            
            %find the closest matching point in the second image
            bestMatch = -1;
            bestMatchVal = -1;
            if and(and(and(p1(1)>=-3, p1(2)>=-3),p1(1)<=maxX),p1(2)<=maxY)
                for k=1:size(loc2)
                    if (~ismember(k,usedPoints2))
                        dist = (p1(1)-loc2(k,2))^2 + (p1(2)-loc2(k,1))^2;
                        if (dist <=4)
                            bestMatchVal = dist;
                            bestMatch = k;
                            break;
                        end
                    end
                end

                if (bestMatch >= 0)
                    myMatches = [myMatches; i bestMatch];
                    matchCount = matchCount + 1;
                end
            end
        end
    end
    
    
    if (matchCount > topMatchCount)
        matches = myMatches
        topMatchCount = matchCount
        homography = nextHomo
    end

end

% Create a new image showing the two images side by side.
im3 = appendimages(im1,im2);

% Show a figure with lines joining the accepted matches.
figure('Position', [100 100 size(im3,2) size(im3,1)]);
colormap('gray');
imagesc(im3);
hold on;
cols1 = size(im1,2);
for i = 1: size(matches,1)
  if (matches(i) > 0)
    line([loc1(matches(i,1),2) loc2(matches(i,2),2)+cols1], ...
         [loc1(matches(i,1),1) loc2(matches(i,2),1)], 'Color', 'c');
  end
end
hold off;

end

