function panImg = panorama( imagepath, f, k1, k2 )
% Process input imagepath
%files = dir(imagepath);
%imagelist = files(3:end);
% Ia = imread('Dinosaur_small\DSC03622.JPG');
% Ib = imread('Dinosaur_small\DSC03623.JPG');

%load in all the images
%    \o
%     |\
%    / \
files = dir(imagepath);
images = {};
k = 1;
for i=1:(length(files))
    if (~files(i).isdir)
        disp(strcat('Reading in image ', imagepath, '\', files(i).name));
        images{k} = imread(strcat(imagepath,'\',files(i).name));
        k = k+1;
    end
end

% map each image to a cylinder
disp('Mapping images to cylinder');
cylImages = {};
for i=1:length(images)
    cylImages{i} = cylindricalProjection(images{i}, f, k1, k2);
end


disp('Getting SIFT information from images.');
grayImages = {};
siftFeatures = {};
siftDescriptors = {};
for i=1:length(cylImages)
    grayImages{i} = single(rgb2gray(cylImages{i}));
    [f d] = vl_sift(grayImages{i});
    siftFeatures{i} = f;
    siftDescriptors{i} = d;
end

disp('Calculating homographies');
homographies = {};
for i=1:length(grayImages)
    k = mod(i,length(grayImages)) + 1; %also match the last with the first
    
    mess = sprintf('Ransacing image %d with image %d',i,k);
    disp(mess);
    
    [homo, matches] = ransac(siftFeatures{i}, siftDescriptors{i}, ...
        siftFeatures{k}, siftDescriptors{k});
    disp('Number of Matches: ');
    disp(length(matches));
    disp('Homography');
    disp(homo);
    homographies{i} = homo;
end

% The vl_sift command requires a single precision gray scale image. 
% It also expects the range to be normalized in the [0,255] interval

%[homography, matches] = ransac(grayImages{1}, grayImages{2});

%[~, matchIndex, loc1, loc2] = match(cyla, cylb);
%[~, matchIndex, loc1, loc2] = match(Ia, Ib);

panImg = images{1};

end

