function panImg = panorama( imagepath, f, k1, k2 )
% Process input imagepath
%files = dir(imagepath);
%imagelist = files(3:end);
Ia = imread('testingImages\100NIKON-DSCN0008_DSCN0008.JPG');
Ib = imread('testingImages\100NIKON-DSCN0009_DSCN0009.JPG');

%convert each image into cylindrical coordinates
cyla = cylindricalProjection( Ia, f, k1, k2 );
cylb = cylindricalProjection( Ib, f, k1, k2 );

% The vl_sift command requires a single precision gray scale image. 
% It also expects the range to be normalized in the [0,255] interval

[homography, matches] = ransac(cyla, cylb);

%[~, matchIndex, loc1, loc2] = match(cyla, cylb);
%[~, matchIndex, loc1, loc2] = match(Ia, Ib);



panImg = Ia;


end

