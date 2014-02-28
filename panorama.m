function panImg = panorama( imagepath, f, k1, k2 )
% Process input imagepath
%files = dir(imagepath);
%imagelist = files(3:end);
Ia = imread('roofs1.jpg');
Ib = imread('roofs2.jpg');

%convert each image into cylindrical coordinates
cyla = cylindricalProjection( Ia, f, k1, k2 );
cylb = cylindricalProjection( Ib, f, k1, k2 );

% The vl_sift command requires a single precision gray scale image. 
% It also expects the range to be normalized in the [0,255] interval


%[~, matchIndex, loc1, loc2] = match(cyla, cylb);
[~, matchIndex, loc1, loc2] = match(Ia, Ib);



panImg = Ia;


end

