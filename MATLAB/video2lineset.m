function [lineset, fps, w, h, audio] = video2lineset(videoPath)

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
    BW = flip(BW)';
    [B,~] = bwboundaries(BW,'holes');
    poly = cell([length(B), 1]);
    for k = 1:length(B)
        po = B{k};
        try
            [x, y] = reducem(po(:,1), po(:,2));
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