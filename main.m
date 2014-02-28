clear
clc

%[matches, scores] = vl_ubcmatch(da, db) ;
%Camera focal length and distortions
f = 595;
k1 = -0.15;
k2 = 0;
img = panorama('pics', f, k1, k2);

%generate a random ordering of 1 - # of keypoints 
%perm = randperm(size(fa,2)) ;
%select the first 50
%sel = perm(1:50) ;

