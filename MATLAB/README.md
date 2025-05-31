# Bad Apple in MATLAB

> View the results on YouTube: https://youtu.be/pQj3HNsaUds

Well, actually, the code works for any arbitrary video file, as long as the scenes are not too complex.

Fully automated, simply provide the path to a video file, wait a bit for the pre-processing, and the playback would follow. For most cases, playback should be realtime with minimal frame drops. Videos with busy scenes will take longer to pre-process and likely have more frame drops during playback.

## Usage

Requires MATLAB 2020b or later. The Mapping Toolbox is optional, but if installed, will be used for reducing detected points density, likely resulting in faster frame time (more FPS).

### Quick Start

```matlab
% Pre-process video
[lineset, fps, w, h, audio] = video2lineset("/path/to/video.mp4");

% Playback
linesetPlayer(lineset, fps, w, h, audio)

% optionally, enable debugging to see dropped frames
linesetPlayer(lineset, fps, w, h, audio, true)

% You can save the [lineset, fps, w, h, audio] variables to a file for later use
```

### Documentation

For full documentation, check the `.m` files or simply run the MATLAB `help` command on the functions:

```matlab
help video2lineset
help linesetPlayer
help lineset2avi
```

## Save as Video

After a video has been processed with `video2lineset`, you can save also save the output as a video file:

```matlab
% Save as video
lineset2avi("./video.avi", lineset, fps, w, h, audio, 'TargetWidth', 2560);

% For more options, check the help command
help lineset2avi
```

If `audio` is provided, it will also be saved to a file called `audio.wav` in the same directory as the output video. You can then combine the video and audio, as well as convert the video to other formats, using tools like FFmpeg:

```bash
ffmpeg -i "./video.avi" -i "./audio.wav" -pix_fmt yuvj420p -preset:v slow -b:v 10M -c:a aac -b:a 320k "./final_output.mp4"
```