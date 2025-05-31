function linesetPlayer(linesetData, fps, w, h, audioInfo, kvargs)
%%LINESETPLAYER Play a lineset + data generated from video2lineset()
%
% linesetPlayer(linesetData, fps, w, h, audioInfo, Name, Value, ...)
%
% Inputs:
%   linesetData - Cell array of line points generated from video2lineset()
%   fps - Frames per second of the video
%   w - Width of the video
%   h - Height of the video
%   audioInfo - Struct containing audio data (y, fs) extracted from the video file
%
% Optional inputs:
%   Name, Value - Name/value pairs for additional options
%       BackgroundColor - Color of the background (Default: [0.97, 0.97, 0.97])
%       LineColor - Color of the lines (Default: [0, 0, 0])
%       AxisColor - Color of the axis (Default: [0, 0, 0])
%       LineWidth - Width of the lines (Default: 1)
%       Debug - Whether to print debug information (Default: false)
%       LineColorSequence - Cell array of cell arrays of {framestart, frameend, colorHex} to override LineColor
%           MUST BE IN THE FORMAT: { {framestart, frameend, colorHex} }
%           Frames outside the range will inherit the LineColor
%
% Example:
%   linesetData = video2lineset('video.mp4');
%   linesetPlayer(linesetData, fps, w, h, audioInfo);
%
% See also lineset2avi, video2lineset

arguments
    linesetData (:,1) cell
    fps (1,1) double {mustBePositive}
    w (1,1) double {mustBeInteger, mustBePositive}
    h (1,1) double {mustBeInteger, mustBePositive}
    audioInfo (1,1) struct = struct

    kvargs.BackgroundColor {validatecolor} = [0.97, 0.97, 0.97]
    kvargs.LineColor {validatecolor} = [0, 0, 0]
    kvargs.AxisColor {validatecolor} = [0, 0, 0]
    kvargs.LineWidth (1,1) double {mustBePositive} = 1
    kvargs.Debug (1,1) logical = false

    % LineColorSequence of cell array will override LineColor
    % MUST BE IN THE FORMAT: { {framestart, frameend, colorHex} }
    % {1xN} cell arrays of {1x3} cell arrays
    % Frames outside the range will inherit the LineColor
    kvargs.LineColorSequence (1,:) cell = cell(1,0)
end

% Validate LineColorSequence
if ~isempty(kvargs.LineColorSequence)
    for i = 1:length(kvargs.LineColorSequence)
        if ~isnumeric(kvargs.LineColorSequence{i}) && ~iscell(kvargs.LineColorSequence{i}) || length(kvargs.LineColorSequence{i}) ~= 3
            error('Each entry in LineColorSequence must be a 1x3 array/cell {framestart, frameend, colorHex}');
        end

        try
            frameStart = kvargs.LineColorSequence{i}{1};
            frameEnd = kvargs.LineColorSequence{i}{2};
            colorSpec = kvargs.LineColorSequence{i}{3};
        catch
            error('Each entry in LineColorSequence must be a 1x3 cell array of {framestart, frameend, colorHex}');
        end

        if ~isnumeric(frameStart) || ~isscalar(frameStart) || frameStart < 1 || frameStart ~= round(frameStart)
            error('Frame start must be a positive integer');
        end
        if ~isnumeric(frameEnd) || ~isscalar(frameEnd) || frameEnd < 1 || frameEnd ~= round(frameEnd)
            error('Frame end must be a positive integer');
        end
        if frameStart > frameEnd
            error('Frame start must be less than or equal to frame end');
        end

        try
            kvargs.LineColorSequence{i}{3} = validatecolor(colorSpec);
        catch
            error('Invalid color specification in LineColorSequence at position %d', i);
        end
    end
end


if isempty(linesetData)
    fprintf("No data to play.\n");
    return;
end

ss = get(0, 'ScreenSize');
window_w = w; window_h = h;
if w > ss(3)
    window_w = ss(3);
end
if h > ss(4)
    window_h = ss(4);
end
f = figure('Position', [round((ss(3)-window_w)/2), round((ss(4)-window_h)/2), window_w, window_h], 'Color', kvargs.BackgroundColor);
a = axes(f, 'XLim', [0, w], 'YLim', [0, h], 'Box', 'on', ...
    'NextPlot', 'replacechildren', 'Interactions', [], 'Color', kvargs.BackgroundColor);
a.XColor = kvargs.AxisColor; a.YColor = kvargs.AxisColor;
a.Toolbar.Visible = 'off';
axis(a,'equal');
numFrames = length(linesetData);
frameDuration = 1.0 / fps;

aplayer = cell(0);
if isstruct(audioInfo) && isfield(audioInfo, 'y') && isfield(audioInfo, 'fs')
    aplayer = audioplayer(audioInfo.y, audioInfo.fs);
end

i = 1;
playbackStartTime = tic;

while i <= numFrames
    currentTime = toc(playbackStartTime);
    targetFrameStartTime = double(i-1) * frameDuration;

    while currentTime > (targetFrameStartTime + frameDuration) && i <= numFrames
        if kvargs.Debug
            fprintf("Skipping frame %d (Current Time: %.3fs > Target End Time: %.3fs)\n", ...
                i, currentTime, targetFrameStartTime + frameDuration);
        end
        i = i + 1;
        if i > numFrames
            break;
        end
        targetFrameStartTime = double(i-1) * frameDuration;
        currentTime = toc(playbackStartTime);
    end

    if i > numFrames
        break;
    end

    lineset = linesetData{i};
    cla(a);
    if ~isempty(lineset)
        lineColor = kvargs.LineColor;
        if ~isempty(kvargs.LineColorSequence)
            for k = 1:length(kvargs.LineColorSequence)
                if i >= kvargs.LineColorSequence{k}{1} && i <= kvargs.LineColorSequence{k}{2} && ~isempty(kvargs.LineColorSequence{k}{3})
                    lineColor = kvargs.LineColorSequence{k}{3};
                    break;
                end
            end
        end
        hold(a, 'on');
        for k = 1:length(lineset)
            if ~isempty(lineset{k}) && size(lineset{k}, 1) > 0

                line(a, double(lineset{k}(:,1)), double(lineset{k}(:,2)), 'Color', lineColor, 'LineWidth', kvargs.LineWidth);
            end
        end
        hold(a, 'off');
        a.XLim = [0, w]; a.YLim = [0, h];
    end

    if ~isempty(aplayer) && i == 1
        aplayer.play();
    end
    drawnow;

    nextFrameTargetTime = double(i) * frameDuration;
    currentTime = toc(playbackStartTime);

    pauseDuration = nextFrameTargetTime - currentTime;

    if pauseDuration < 0
        if i ~= 1
            if kvargs.Debug
                fprintf("Frame %d draw overrun by %.3f ms. No pause.\n", i, -pauseDuration*1000);
            end
        end
    else
        pause(pauseDuration);
    end

    i = i + 1;
end

totalDuration = toc(playbackStartTime);
expectedDuration = double(numFrames) / fps;
if kvargs.Debug
    fprintf("Total elapsed time: %.3f seconds.\n", totalDuration);
    fprintf("Expected duration:  %.3f seconds.\n", expectedDuration);
end

end