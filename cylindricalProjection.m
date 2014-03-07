function [ cylImg, cylMask ] = cylindricalProjectionOrig( img, f, k1, k2 )
width = size(img,2);
height = size(img,1);

%figure, imshow(img);
for y=1:height
    for x=1:width
        theta = (x - width / 2) / f;
        h = (height / 2 - y) / f;
        
        %get cylindrical coordinates
        xhat = sin(theta);
        yhat = h;
        zhat = cos(theta);
        
        %normalize coordinates
        xn = xhat / zhat;
        yn = yhat / zhat;
        
        %account for radial distortion
        r_sqr = xn^2 + yn^2;
        radDist = (1 + k1 * r_sqr + k2 * r_sqr^2);
        xd = xn/radDist;
        yd = yn/radDist;
        
        %reverses distortion
        %xd = xn*radDist;
        %yd = yn*radDist;
        
        %Convert to cylindrical image coordinates
        xCylImg = floor(width / 2 + (f * xd));
        yCylImg = floor(height / 2 - (f * yd));
        
        if yCylImg > 0 && yCylImg <= height && xCylImg > 0 && xCylImg <= width
            cylImg(y, x, 1) = uint8(img(yCylImg, xCylImg, 1));
            cylImg(y, x, 2) = uint8(img(yCylImg, xCylImg, 2));
            cylImg(y, x, 3) = uint8(img(yCylImg, xCylImg, 3));
            
            cylMask(y,x) = 1;
        end
    end
end
%figure, imshow(cylImg);
end

