# Bad Apple in MATLAB

> View the results on YouTube: https://youtu.be/m1gnREM8zGM

Well, actually, the code works for any arbitrary video file, as long as the scenes are not too complex.

Fully automated, simply provide the path to a video file, wait a bit for the pre-processing, and the playback would follow. For most cases, playback should be realtime with minimal frame drops. Videos with busy scenes will take longer to pre-process and likely have more frame drops during playback.

## Usage

Requires MATLAB 2020b or later. The Mapping Toolbox is optional, but if installed, will be used for reducing detected points density, likely resulting in faster frame time (more FPS).

```matlab
% Pre-process video
[lineset, fps, w, h, audio] = video2lineset("/path/to/video.mp4");

% Playback
linesetPlayer(lineset, fps, w, h, audio)

% optionally, enable debugging to see dropped frames
linesetPlayer(lineset, fps, w, h, audio, true)

% You can save the [lineset, fps, w, h, audio] variables to a file for later use
```

## Results

Included in this repo is the [pre-processed data](./BadApple.mat) for [Bad Apple](https://www.youtube.com/watch?v=FtutLA63Cp8). You can directly test out the playback as follows:

```matlab
load("BadApple.mat");
linesetPlayer(lineset, fps, w, h, audio)
```

An additional pre-processed data file for a more complex video, [MIMI - Science (ft. Kasane Teto)](https://www.youtube.com/watch?v=m-bvW4pKT68) is included in the [other_examples](./other_examples) folder. Check out the final playback for this video on YouTube: [MIMI  - Science (ft.  Kasane Teto), but it's MATLAB](https://youtu.be/P-463r36IFo)