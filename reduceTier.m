function imgout = reduceTier(img, a )
%used impyramid as a guide
kernelWidth = 5;
sigma = 1;
kernel = fspecial('gauss',kernelWidth,sigma);
% kern = [.25-(a/2) .25 a .25 .25-(a/2)];
% kernel = kern'*kern;

imgout = [];
[M N ~] = size(img);

for p = 1:size(img,3)
	singleChan = img(:,:,p);
	blurredImg = imfilter(singleChan,kernel,'replicate','same');
    %imgout(:,:,p) = imresize(blurredImg, [ceil(M/2), ceil(N/2)]);
	imgout(:,:,p) = blurredImg(1:2:M,1:2:N);
end

end