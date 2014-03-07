function  pyr = generatePyramid( img, level )
pyr = cell(1,level);
pyr{1} = img;

for p = 2:level
	pyr{p} = impyramid(pyr{p-1}, 'reduce');
end

for p = 1:level-1
    sz = size(pyr{p});
    pyrExp = impyramid(pyr{p+1}, 'expand');
    pyrExp = imresize(pyrExp, [sz(1), sz(2)]);
	pyr{p} = pyr{p}-pyrExp;
end

end