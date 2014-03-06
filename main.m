clear
clc

run('./vlfeat-0.9.18/toolbox/vl_setup');
w = warning ('off','all');

%[matches, scores] = vl_ubcmatch(da, db) ;
%Camera focal length and distortions
f = 1341.23173;
k1 = -0.05456;
k2 = 0.14122;
img = panorama('Dinosaur_control_small', f, k1, k2);

%generate a random ordering of 1 - # of keypoints 
%perm = randperm(size(fa,2)) ;
%select the first 50
%sel = perm(1:50) ;

