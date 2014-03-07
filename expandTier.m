function imgOut = expandTier( img, a )
 kernelwidth = 5; 
% sigma = 1;
% kernel = fspecial('gauss',kernelwidth,sigma)*4; 
kern = [.25-(a/2) .25 a .25 .25-(a/2)];
kernel = 4*(kern'*kern);

% Note: "Only terms for which i-m/2 j-n/2 are integers are included in the
% sum" According to Burt et. al
% To deal with this in a relatively quick manner we can split up the kernal
% into four smaller ones.
% Each subkernal handling different cases:
% One where a pixel location is two odd numbers (e.g. 1,1)
% Two cases where a pixel location is two odd numbers (e.g. 2,1, or 1,2 )
% One where a pixel location is two even numbers (e.g. 2,2)
%
ker00 = kernel(1:2:kernelwidth,1:2:kernelwidth); % 3*3
ker01 = kernel(1:2:kernelwidth,2:2:kernelwidth); % 3*2
ker10 = kernel(2:2:kernelwidth,1:2:kernelwidth); % 2*3
ker11 = kernel(2:2:kernelwidth,2:2:kernelwidth); % 2*2

img = im2double(img);
[M N] = size(img(:,:,1));
M = 2*M-1;
N = 2*N-1;

imgOut = zeros(M, N, size(img,3));

 for p = 1:size(img,3)
 	singleChan = img(:,:,p);
 	chanPadh = padarray(singleChan,[0 1],'replicate','both'); % horizontally padded
 	chanPadv = padarray(singleChan,[1 0],'replicate','both'); % vertically padded
	
	img00 = imfilter(singleChan,ker00,'replicate','same');
	img01 = conv2(chanPadv,ker01,'valid');
	img10 = conv2(chanPadh,ker10,'valid');
	img11 = conv2(singleChan,ker11,'valid');
	
	imgOut(1:2:M,1:2:N,p) = img00;
    imgOut(1:2:M,2:2:N,p) = img01;
	imgOut(2:2:M,1:2:N,p) = img10;
	imgOut(2:2:M,2:2:N,p) = img11;
 end

% Try to get working - version that doesn't break kernel up
% for p = 1:size(img,3)
% 	singleChan = img(:,:,p);
%     chanPad = padarray(singleChan,[1 1],'replicate','both'); 
%     imgout(1:2:M,2:2:N) = chanPad(:,:,p);
% 	imgFiltered = imfilter(imgout(:,:,p),kernel,'replicate','same');
%     imgout(:,:,p) = imgFiltered;
% end
end