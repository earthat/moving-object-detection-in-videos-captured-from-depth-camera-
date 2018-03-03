function th = thrshold(input,k)
glcm = graycomatrix(input,'offset',[ 1 1]);% co occurrance matrix
    contrst=graycoprops(glcm, 'contrast'); % co occurrance matrix contrast
    blksize=[4 4];  % needs tuning for images
    lmean=conv2(double(input),ones(blksize)/blksize(1)^2,'same'); % calculating local mean
    % std=stdfilt(I,true(blksize));% calculating local standard deviation
    th=k*(lmean+sqrt(mean(contrst.Contrast))); % calculating local threshold
end