function H = calcH(im1_pts, im2_pts)
%RANSAC alg needs to be implemented
    n = size(im1_pts, 1);
    if n < 4
        error('Not enough points');
    end
    
    A = zeros(n*3,9);
    b = zeros(n*3,1);
    for i=1:n
        A(3*(i-1)+1,1:3) = [im2_pts(i,:),1];
        A(3*(i-1)+2,4:6) = [im2_pts(i,:),1];
        A(3*(i-1)+3,7:9) = [im2_pts(i,:),1];
        b(3*(i-1)+1:3*(i-1)+3) = [im1_pts(i,:),1];
    end
    x = (A\b)';
    H = [x(1:3); x(4:6); x(7:9)];
    
end

