function imgOut  = collapsePyramid( pyr, a )

for p = length(pyr)-1:-1:1
    pyr{p} = pyr{p}+expandTier(pyr{p+1}, a);
end
imgOut = pyr{1};

end

