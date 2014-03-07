function imgOut  = collapsePyramid( pyr )

for p = length(pyr)-1:-1:1
    %expand upper tier
    expandedUpperTier = impyramid(pyr{p+1}, 'expand');
    
    %account for any size change
    sz = size(pyr{p});
    expandedUpperTier = imresize(expandedUpperTier, [sz(1), sz(2)]);
    
    %apply to lower tier
    pyr{p} = pyr{p}+expandedUpperTier;
end
imgOut = pyr{1};

end

