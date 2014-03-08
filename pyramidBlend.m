function imgOut = pyramidBlend( img1, img2, mask1, mask2, level, a )
%convert to double if images aren't already in double form
img1 =  im2double(img1);
img2 =  im2double(img2);

%verify that images are the same size?

%feather masks
gKernel = fspecial('gauss',30,15); %original value
%gKernel = fspecial('gauss',10,5); 
mask1 = imfilter(mask1,gKernel,'replicate');
mask2 = imfilter(mask2,gKernel,'replicate');

%figure, imshow(mask1);
%figure, imshow(mask2);

%create pyramids
lapPyr1 = generatePyramid(img1,level, a); % the Laplacian pyramid
lapPyr2 = generatePyramid(img2,level, a);

%blend and combine pyramids
combinedPyr = cell(1,level); 
for p = 1:level
    %assuming that img1 and img2 could be different dimensions
	[M1 N1 ~] = size(lapPyr1{p});
    [M2 N2 ~] = size(lapPyr2{p});
    %resizes masks so that are the same size as images or else mask application
    %will not work
	maskResize1 = imresize(mask1,[M1 N1]);
	maskResize2 = imresize(mask2,[M2 N2]);
    appliedMask1 = lapPyr1{p}.*maskResize1;
    appliedMask2 = lapPyr2{p}.*maskResize2;

	combinedPyr{p} = appliedMask1 + appliedMask2;
end

imgOut = collapsePyramid(combinedPyr, a);
figure,imshow(imgOut);

end

