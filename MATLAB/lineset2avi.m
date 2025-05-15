function lineset2avi(outputPath, linesetData, fps, w, h, audioInfo, kvargs)
%%LINESET2AVI Convert a lineset to an AVI file
%
% lineset2avi(linesetData, fps, targetWidth, audioInfo, Name, Value, ...)
%
% Inputs:
%   outputPath - Path to the output AVI file
%   linesetData - Cell array of line points generated from video2lineset()
%   fps - Frames per second of the video
%   w - Width of the lineset
%   h - Height of the lineset
%   audioInfo - Struct containing audio data (y, fs) extracted from the video file
%
% Optional inputs:
%   Name, Value - Name/value pairs for additional options
%       BackgroundColor - Color of the background (Default: [0.97, 0.97, 0.97])
%       LineColor - Color of the lines (Default: [0, 0, 0])
%       LineWidth - Width of the lines (Default: 1)
%       TargetWidth - Width of the output video (Default: 1920). The height will be calculated based on the aspect ratio of the lineset.
%       LineColorSequence - Cell array of cell arrays of {framestart, frameend, colorHex} to override LineColor
%           MUST BE IN THE FORMAT: { {framestart, frameend, colorHex} }
%           Frames outside the range will inherit the LineColor
%
% Example:
%   linesetData = video2lineset('video.mp4');
%   lineset2avi(linesetData, fps, targetWidth, audioInfo, 'TargetWidth', 2560);
%
% See also linesetPlayer, video2lineset

arguments
    outputPath (1,:) {mustBeTextScalar}
    linesetData (:,1) cell
    fps (1,1) double {mustBePositive}
    w (1,1) double {mustBeInteger, mustBePositive}
    h (1,1) double {mustBeInteger, mustBePositive}
    audioInfo (1,1) struct = struct

    kvargs.DPI (1,1) double {mustBePositive} = 300
    kvargs.BackgroundColor {validatecolor} = [0.97, 0.97, 0.97]
    kvargs.LineColor {validatecolor} = [0, 0, 0]
    kvargs.LineWidth (1,1) double {mustBePositive} = 1
    kvargs.TargetWidth (1,1) double {mustBeInteger, mustBePositive} = 1920

    % LineColorSequence of cell array will override LineColor
    % MUST BE IN THE FORMAT: { {framestart, frameend, colorHex} }
    % {1xN} cell arrays of {1x3} cell arrays
    % Frames outside the range will inherit the LineColor
    kvargs.LineColorSequence (1,:) cell = cell(1,0)
end

[~, ~, ext] = fileparts(outputPath);
if ~strcmpi(ext, '.avi')
    error('Output must be an AVI file');
end

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
    fprintf("No lineset data to convert.\n");
    return;
end

outputDir = fileparts(outputPath);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

aspectRatio = h / w;
targetHeight = round(kvargs.TargetWidth * aspectRatio);

v = VideoWriter(fullfile(outputPath), 'Motion JPEG AVI');
v.FrameRate = fps;
v.Quality = 100;
open(v);

ss = get(0, 'ScreenSize');
w_inches = kvargs.TargetWidth / kvargs.DPI;
h_inches = targetHeight / kvargs.DPI;
f = figure('Position', [round((ss(3)-w)/2), round((ss(4)-h)/2), w, h], 'Color', kvargs.BackgroundColor, 'PaperSize', [w_inches, h_inches], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
a = axes(f, 'XLim', [0, w], 'YLim', [0, h], 'Box', 'on', ...
    'NextPlot', 'replacechildren', 'Interactions', [], 'Color', kvargs.BackgroundColor);
a.Toolbar.Visible = 'off';
axis(a,'equal', 'tight');

for frameIdx = 1:length(linesetData)
    fprintf('Processing frame %d/%d\n', frameIdx, length(linesetData));
    cla(a);

    currentColor = kvargs.LineColor;
    if ~isempty(kvargs.LineColorSequence)
        for i = 1:length(kvargs.LineColorSequence)
            frameStart = kvargs.LineColorSequence{i}{1};
            frameEnd = kvargs.LineColorSequence{i}{2};
            if frameIdx >= frameStart && frameIdx <= frameEnd
                currentColor = kvargs.LineColorSequence{i}{3};
                break;
            end
        end
    end

    frameLines = linesetData{frameIdx};
    if ~isempty(frameLines)
        for i = 1:length(frameLines)
            if ~isempty(frameLines{i})
                x = double(frameLines{i}(:,1));
                y = double(frameLines{i}(:,2));
                line(a, x, y, 'Color', currentColor, 'LineWidth', kvargs.LineWidth);
            end
        end
    end
    a.XLim = [0, w]; a.YLim = [0, h];

    frame = getframe(f);
    if size(frame.cdata, 1) ~= targetHeight || size(frame.cdata, 2) ~= kvargs.TargetWidth
        frame.cdata = imresize(frame.cdata, [targetHeight, kvargs.TargetWidth]);
    end
    writeVideo(v, frame.cdata);
    drawnow;
end


if isfield(audioInfo, 'y') && isfield(audioInfo, 'fs') && ~isempty(audioInfo.y) && ~isempty(audioInfo.fs)
    audioOut = fullfile(outputDir, 'audio.wav');
    audiowrite(audioOut, audioInfo.y, audioInfo.fs);
end

close(v);
close(f);
end