function linesetPlayer(linesetData, fps, w, h, audioInfo, debug)

if nargin < 5
    audioInfo = struct;
end
if nargin < 6
    debug = false;
end
if ~islogical(debug)
    debug = false;
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
f = figure('Position', [round((ss(3)-window_w)/2), round((ss(4)-window_h)/2), window_w, window_h]);
a = axes(f, 'XLim', [0, w], 'YLim', [0, h], 'Box', 'on', ...
         'NextPlot', 'replacechildren', 'Interactions', []);
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
        if debug
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
        hold(a, 'on');
        for k = 1:length(lineset)
            if ~isempty(lineset{k}) && size(lineset{k}, 1) > 0
                line(a, double(lineset{k}(:,1)), double(lineset{k}(:,2)), 'Color', 'k', 'LineWidth', 1);
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
            if debug
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
if debug
    fprintf("Total elapsed time: %.3f seconds.\n", totalDuration);
    fprintf("Expected duration:  %.3f seconds.\n", expectedDuration);
end

end