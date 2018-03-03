close all
clear 
clc
addpath(genpath(pwd))
% initialise the vidoe reader
videoSource = vision.VideoFileReader('1.mp4',...
              'ImageColorSpace','rgb','VideoOutputDataType','uint8');
 % declare the foregorund detector using GMM
detector = vision.ForegroundDetector(...
       'NumTrainingFrames', 50, ...
       'InitialVariance', 'Auto');
 % morphological operation  
   blob = vision.BlobAnalysis(...
       'CentroidOutputPort', false, 'AreaOutputPort', true, ...
       'BoundingBoxOutputPort', true, ...
       'MinimumBlobArea',60,'MaximumBlobArea',600);
   shapeInserter = vision.ShapeInserter('BorderColor','Custom',...
                                            'CustomBorderColor',[0 255 0]);
   textInserter = vision.TextInserter('%s', 'Color',  [255, 255, 255], ...
                                       'FontSize', 24,'Location',[405,705]);
   videoPlayer = vision.VideoPlayer();
   [row,colm,~]=size(step(videoSource));
   prevframe=zeros(row,colm);
   prevSI=zeros(row,colm);
   prevBG=zeros(row,colm);
   prevBI=zeros(row,colm);
   gh=zeros(row,colm);
   eh=zeros(row,colm);
   temp=zeros(row,colm);
   k=0.96;
while ~isDone(videoSource) % loop till frame ends
     frame  = step(videoSource);
     grayFrame=rgb2gray(frame);
     G = fspecial('gaussian',[3 3],2);
    %# Filter it
    neframes= imfilter(grayFrame,G,'same');
    FD= double(neframes)-double(prevframe);
    prevframe=neframes;
    FD=wiener2(FD);
    glcm = graycomatrix(FD,'offset',[ 1 1]);% co occurrance matrix
    contrst=graycoprops(glcm, 'contrast'); % co occurrance matrix contrast
    blksize=[3 3];  % needs tuning for images
    lmean=conv2(FD,ones(blksize)/blksize(1)^2,'same'); % calculating local mean
    % std=stdfilt(I,true(blksize));% calculating local standard deviation
    th=k*(lmean+sqrt(mean(contrst.Contrast))); % calculating local threshold
    for p=1:row
        for q=1:colm
            if  FD(p,q)>th(p,q)||FD(p,q)==th(p,q)
                fdm(p,q) = 1;
                
            else
                fdm(p,q) = 0;
                
            end
        end
    end
    FDM=fdm;
    %%%%%%%%%%%
    for p=1:row
        for q=1:colm
            if  FDM(p,q) == 1               
                SI(p,q)=0;                          
            else
                SI(p,q)=prevSI(p,q)+1;
            end
        end
    end
    prevSI=SI;
    %%%%%%%%%%
    
    th2 = thrshold(SI,k);
    for p=1:row
        for q=1:colm
            if SI(p,q)+1==round((th2(p,q)))
%                 cnt=cnt+1;
                BG(p,q)=neframes(p,q);
                BI(p,q)=1;
            else
                BG(p,q)=prevBG(p,q);
                BI(p,q)=prevBI(p,q);
            end
        end
    end
    prevBG=BG;
    prevBI=BI;
    %%%%%%%%%%%%%
    BD=double(neframes)-double(prevBG);
    
    th1 = thrshold(BD,k);
    for p=1:row
        for q=1:colm
            if BD(p,q)>th1(p,q)|| BD(p,q)==th1(p,q)
                BDM(p,q)=1;
            else
                BDM(p,q)=0;
            end
        end
    end
    %%%%%%%%
    for p=1:row
        for q=1:colm
            if BI(p,q)==1
                IOM(p,q)=BDM(p,q);
            else
                IOM(p,q)=FDM(p,q);
            end
        end
    end
    se = strel('square',20);
    IOM=imclose(IOM,se);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for p=1:row
        for q=1:colm
%             if  FDM(p,q)==1 && BDM(p,q)==1&&BI(p,q)==1 && IOM(p,q)==1
             if   BDM(p,q)==1 && IOM(p,q)==1
                gh(p,q,1:3)=frame(p,q,1:3);
%                 frame(p,q,1)=255;
%                 frame(p,q,2)=0;
%                 frame(p,q,3)=0;
                temp(p,q)=1;
            
            end

        end
    end
    [area,bbox]   = step(blob, logical(temp));

    %%%%%%%%%%%%
    if isempty(bbox)
        step(videoPlayer, uint8(frame));
    else
        out    = step(shapeInserter, double(frame), bbox);
        out=insertText(out,[1000,10],['Soldiers Detected: ',num2str(numel(area))],...
                      'FontSize',20,'TextColor',[255,0,0]);
        step(videoPlayer, uint8(out));

    end
     
end