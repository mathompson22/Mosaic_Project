close all
clear
imga = im2double(imread('apple1.jpg'));
imgb = im2double(imread('orange1.jpg')); % size(imga) = size(imgb)

%create masks
v = size(imga, 2)/2;        %choosing middle of image
maska = zeros(size(imga));
maska(:,1:v,:) = 1;
maskb = 1-maska;

pyramidBlend(imga, imgb, maska, maskb, 5);
