function  pyr = generatePyramid( img, level, a )
pyr = cell(1,level);
pyr{1} = img;

%Build Gaussian pyramid
for p = 2:level
    pyr{p} = reduceTier(pyr{p-1}, a);
    %figure, imshow(pyr{p});
end

%expanded tier loses dimensions to we must compensate for that
for p = level-1:-1:1
	expandedTierSize = 2*size(pyr{p+1})-1;
	pyr{p} = pyr{p}(1:expandedTierSize(1),1:expandedTierSize(2),:);
end

%finalize pyramid
for p = 1:level-1
	pyr{p} = pyr{p}-expandTier(pyr{p+1}, a);
    %figure, imshow(pyr{p});
end

end