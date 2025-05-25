function [lineset, fps, w, h, audio] = video2lineset(videoPath, addDetails)
%%VIDEO2LINESET Convert a video file to a lineset for plotting
%
% [lineset, fps, w, h, audio] = video2lineset(videoPath, addDetails)
%
% Converts a video file to a lineset for plotting. The lineset is a cell
% array of line points that can be plotted with line() or converted into a polygon with polyshape().
%
% Input:
%   videoPath - Path to the video file to convert
%   addDetails - Whether to do an extra edge detection pass to add more details to the lineset (Default: false)
%
% Output:
%   lineset - Cell array of line points
%   fps - Frames per second of the video
%   w - Width of the video
%   h - Height of the video
%   audio - Struct containing audio data (y, fs) extracted from the video file
%
% Example:
%   [lineset, fps, w, h, audio] = video2lineset('video.mp4');
%   linesetPlayer(lineset, fps, w, h, audio);
%
% See also linesetPlayer, lineset2avi

arguments
    videoPath {mustBeFile}
    addDetails (1,1) logical = false
end

video = VideoReader(fullfile(videoPath));
[~, name, ext] = fileparts(videoPath);

f = waitbar(0,'Retrieving video metadata...', 'Name', strcat(name, ext));

w = video.Width; h = video.Height; fps = video.FrameRate;
audio = struct;
try
    [y,audio_fs] = audioread(videoPath);
    audio.y = y; audio.fs = audio_fs;
catch
    fprintf("Video file does not contain audio, 'audio' output will be an empty struct.\n");
end

lineset = cell([video.NumFrames, 1]);
i = 1;
while hasFrame(video)
    progress = i/(video.NumFrames + 1);
    try
        waitbar(progress, f, sprintf("Frame %d / %d (%.2f%%)", i, video.NumFrames, progress*100));
    catch
        disp("Operation aborted. Output may not contains all video frames.");
        return
    end
    I = readFrame(video);
    I = im2gray(I);
    BW = imbinarize(I);

    if addDetails
        edges = edge(I, 'Canny'); % Add edge detection to capture more details
        BW = BW | edges;
    end

    BW = flip(BW)';
    [B,~] = bwboundaries(BW,'holes');
    poly = cell([length(B), 1]);
    for k = 1:length(B)
        po = B{k};
        try
            [x, y] = reducem(po(:,1), po(:,2)); % Reduce points to reduce plotting time
        catch
            x = po(:,1); y = po(:,2);
        end
        poly{k,1} = [x, y];
    end

    lineset{i,1} = poly;
    i = i + 1;
end

waitbar(1,f,'Finishing');
close(f)

end