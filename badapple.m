clear;clc;

disp('Setting.');
cores = input('Number of Processors be used at Parallel Computing ? ');
[filename,pathname] = uigetfile('*.avi','Select the video file','C:\Users\rnd\AppData\Roaming\PotPlayerMini64\Capture')
disp('Setting.');
disp('Waiting for user.');
%cores = str2num(cores);
disp('Done.');
pause(1);
clc;

disp('Loading files.');
xyloObj = VideoReader([pathname filename])
nFrames = 480;
vidHeight = xyloObj.Height;
vidWidth = xyloObj.Width;
vidFrameRate = xyloObj.FrameRate;

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

disp('Processing frames.');
% Read one frame at a time.
parfor k = 1 : nFrames
    mov(k).cdata = read(xyloObj, k);
end

disp('Convert image to binary image.');
%L Convert image to binary image by thresholding.
parfor k = 1 : nFrames
    bwmov(k).cdata = im2bw(mov(k).cdata);
end

disp('Create edges of the image.');
%L [optional]finds edges using the Prewitt approximation to the derivative.
parfor k = 1 : nFrames
    %bwmov(k).cdata = edge(bwmov(k).cdata,'prewitt');
    bwmov(k).cdata = edge(bwmov(k).cdata,'sobel');
end

disp('Find bitrate per matrix.');
%L Convert matrix.
cal=[];
parfor k = 1 : nFrames
[B,L,N,A] = bwboundaries(bwmov(k).cdata);
calx = 0;
    for ki=1:length(B)
        calx=calx + length(B{ki});
    end
     bwmov(k).cal = calx;  
end
for k = 1 : nFrames
    cal = uint16([cal;bwmov(k).cal]);
end
maxcal = max(cal).*2; %注意这里改变最高采样数量 2倍并不适合大部分音频设备 效果不好时去掉*2
fill = [maxcal - cal ,floor(maxcal./cal),mod(maxcal,cal)];


disp('Data reorganization.');
%L Convert BWimage to single matrix.
filename = '\video.txt';
if(exist('pathname','var')) == 0
    pathname = uigetdir('','Select folder to SAVE data file') ;
end
dlmwrite([pathname filename],[max(cal)*vidFrameRate,0],'delimiter','\t');
parfor k=1:nFrames
c = [];
cx = [];
data = [];
[B,L,N,A] = bwboundaries(bwmov(k).cdata);
    for ki=1:length(B)
        data = B{ki};
        data(:,1) = vidHeight - data(:,1);% Mirror
        data(:,2) = vidWidth - data(:,2);% Reverse
        data=data(:,[2 1]);% Rotate 90
        cx = [cx;data]; 
        %cx = [cs;vidHeight - B{ki}(:,2) , vidWidth - B{ki}(:,1)]   
    end
c = [c;cx];
    if fill(k,2)>1 && fill(k,2)< max(cal)
        for u = 1 : fill(k,2) - 1 
            c = [c;cx];
        end
    end
    if fill(k,3)>0 && fill(k,3)< max(cal)
        c = [c;cx(1:fill(k,3),:)];
    end
    bwmov(k).cal = uint16(c);    
end

disp('Create data matrix.');
h = waitbar(0,'Create Data Please wait...');
c=[];
for k = 1 : nFrames
    c = [c;bwmov(k).cal];
    waitbar(k / nFrames);
end
close(h)

disp('Parallel Computing Enviornment Stop.');
matlabpool close force;

disp('Remove useless vars.');
clearvars f x y e k m u data B L N A ki kx col row cidx rndRow boundary calx colors cx h ans cores;
clearvars fill;

disp('Files.');
reply = input('Do you want a File? Y/N [N]: ', 's');
if (isempty(reply))
    reply = 'N';
end
if ( reply == 'Y' | reply == 'y')
    h = waitbar(0,'File I/O Please wait...');
    for k = 1 : nFrames
        dlmwrite([pathname filename],c,'-append','delimiter','\t');
        waitbar(k / nFrames);
    end
close(h)
end

disp('Output.');
reply = input('Output Data via PC sound? Y/N [N]: ', 's');
if (isempty(reply))
    reply = 'N';
end
if ( reply == 'Y' | reply == 'y')
c = double(c);
cal = double(cal);
    soundsc(c,vidFrameRate*max(cal)*2,16);

%注意这里改变最高采样数量

    end
close(h)

