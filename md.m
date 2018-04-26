clear;clc;
 
disp('Setting.');
cores = input('Number of Processors be used at Parallel Computing ? ');
%[filename,pathname] = uigetfile('*.avi','Select the video file','C:\Users\rnd\AppData\Roaming\PotPlayerMini64\Capture');
disp('Setting.');
disp('Waiting for user.');
%cores = str2num(cores);
disp('Done.');
pause(1);

disp('loading files.');
xyloObj = VideoReader('badapple.avi');
nFrames = xyloObj.NumberOfFrames;
vidHeight = xyloObj.Height;
vidWidth = xyloObj.Width;
vidFrameRate = xyloObj.FrameRate;
 
%disp('Preallocate structure.');
% Preallocate movie structure.
%mov(1:nFrames) = ...
%    struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
%           'colormap', []);

disp('Check Data.');
if( vidHeight > 255 | vidWidth > 255 )
errordlg('Video resolution is too high.It can not be use in 8bit MCU!','Warning');
end
if( vidHeight > 800 | vidWidth > 600 )
errordlg('Video resolution is too high.It can not be use in this code!','Error');
break;
end

disp('Preallocate structure.');
% Preallocate movie structure.
mov(1:nFrames) = ...
    struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
           'colormap', []);
% Preallocate movie structure.
bwmov(1:nFrames) = ...
    struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
           'cal', []);

disp('Parallel Computing Enviornment initialization.');
close all;
matlabpool close force;
if matlabpool('size')<=0 
    matlabpool('open','local',cores); 
end

%%%new end

disp('Processing frames.');
% Read one frame at a time.
for k = 1 : nFrames
    mov(k).cdata = read(xyloObj, k);
end
 
disp('Convert image to binary image.');
%L Convert image to binary image by thresholding.
for k = 1 : nFrames
    bwmov(k).cdata = im2bw(mov(k).cdata);
end
 
disp('Create edges of the image.');
%L [optional]finds edges using the Prewitt approximation to the derivative.
for k = 1 : nFrames
    %bwmov(k).cdata = edge(bwmov(k).cdata,'prewitt');
    bwmov(k).cdata = edge(bwmov(k).cdata,'sobel');
end
 
disp('Find bitrate per matrix.');
%L Convert matrix.
cal=[];
for k = 1 : nFrames
    [y,x,data]=find(bwmov(k).cdata == 1);
    [m,e] = size(x);
    cal = [cal;m];
end
    fill = [max(cal) - cal ,floor(max(cal)./cal),mod(max(cal),cal)];

disp('Create single matrix.');
%L Convert BWimage to single matrix.
c = [];
for k = 1 : nFrames
    [y,x,data] = find(bwmov(k).cdata == 1);
    y = vidHeight - y;
    x = vidWidth - x;
    c = [c;x,y];
    if fill(k,2)>0 && fill(k,2)< max(cal)
        for u = 1 : fill(k,2)
            c = [c;x,y];
        end
    end
    if fill(k,3)>0 && fill(k,3)< max(cal)
        c = [c;x(1:fill(k,3),1),y(1:fill(k,3),1)];
    end
end
 
disp('Remove useless vars.');
clearvars x y e k m u data;
 
%直接用声卡输出会出现问题，跳过这段%
%disp('Signal output. Connected to an oscilloscope in X/Y mode.');
%    soundsc(c,max(cal)*vidFrameRate,16)
 
%用matlab描点输出数据%
disp('Frame check 2.(Ctrl+c to Stop)');
set (gcf,'Position',[100,50,800,500],'doublebuffer','on');
k=1;
ki = 0;
cx=[];
cx=c(1:cal(1),:);
grid on;
scatter(cx(:,1),cx(:,2));
xlim([0 vidWidth]);
ylim([0 vidHeight]);
title('Player');
        if fill(k,2)>0 && fill(k,2)< max(cal)
            [i,e] = size (cx); 
            ki = i * fill(k,2) + ki + i;
        end
        if fill(k,3)>0 && fill(k,3)< max(cal)
            ki = ki + fill(k,3);
        end
pause;
for k = 2 : nFrames
    if(cal(k) > 0 && cal(k-1) > 0)
        cx=c(ki:cal(k)+ki,:);
        grid(gca,'minor');
        subplot(2,3,[1 2 4 5]);
        h=scatter(cx(:,1),cx(:,2));
        set(h,'MarkerEdgeColor','g');
        title('Output');
        grid(gca,'minor');
        xlim([0 vidWidth]);
        ylim([0 vidHeight]);
        subplot(2,3,3);
        subimage(bwmov(k).cdata);
        title('Image');
        subplot(2,3,6);
        subimage(mov(k).cdata);
        title('Video');
        if fill(k,2)>0 && fill(k,2)< max(cal)
            [i,e] = size (cx); 
            ki = i * fill(k,2) + ki  + i;
        end
        if fill(k,3)>0 && fill(k,3)< max(cal)
            ki = ki + fill(k,3);
        end
    end
    pause(0.01);
end

%add

disp('Output.');
reply = input('Output Data via PC sound? Y/N [N]: ', 's');
if (isempty(reply))
    reply = 'N';
end
if ( reply == 'Y' || reply == 'y')
c = double(c);
cal = double(cal);
    soundsc(c,vidFrameRate*max(cal)*2,16);

%注意这里改变最高采样数量

end
