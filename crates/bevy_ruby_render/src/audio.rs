use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PlaybackMode {
    Once,
    Loop,
    Despawn,
}

impl Default for PlaybackMode {
    fn default() -> Self {
        Self::Once
    }
}

#[derive(Debug, Clone)]
pub struct AudioSettings {
    pub volume: f32,
    pub speed: f32,
    pub paused: bool,
    pub mode: PlaybackMode,
    pub fade_in: Option<FadeSettings>,
    pub fade_out: Option<FadeSettings>,
}

impl Default for AudioSettings {
    fn default() -> Self {
        Self {
            volume: 1.0,
            speed: 1.0,
            paused: false,
            mode: PlaybackMode::Once,
            fade_in: None,
            fade_out: None,
        }
    }
}

impl AudioSettings {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_volume(mut self, volume: f32) -> Self {
        self.volume = volume.clamp(0.0, 2.0);
        self
    }

    pub fn with_speed(mut self, speed: f32) -> Self {
        self.speed = speed.clamp(0.1, 10.0);
        self
    }

    pub fn with_mode(mut self, mode: PlaybackMode) -> Self {
        self.mode = mode;
        self
    }

    pub fn looping(mut self) -> Self {
        self.mode = PlaybackMode::Loop;
        self
    }

    pub fn with_fade_in(mut self, duration_secs: f32) -> Self {
        self.fade_in = Some(FadeSettings::new(duration_secs));
        self
    }

    pub fn with_fade_out(mut self, duration_secs: f32) -> Self {
        self.fade_out = Some(FadeSettings::new(duration_secs));
        self
    }
}

#[derive(Debug, Clone, Copy)]
pub struct FadeSettings {
    pub duration_secs: f32,
    pub elapsed: f32,
    pub target_volume: f32,
}

impl FadeSettings {
    pub fn new(duration_secs: f32) -> Self {
        Self {
            duration_secs,
            elapsed: 0.0,
            target_volume: 1.0,
        }
    }

    pub fn with_target(mut self, target: f32) -> Self {
        self.target_volume = target;
        self
    }

    pub fn progress(&self) -> f32 {
        if self.duration_secs <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration_secs).clamp(0.0, 1.0)
        }
    }

    pub fn is_complete(&self) -> bool {
        self.elapsed >= self.duration_secs
    }

    pub fn update(&mut self, delta_secs: f32) {
        self.elapsed += delta_secs;
    }
}

#[derive(Debug, Clone)]
pub struct AudioTrack {
    pub path: String,
    pub settings: AudioSettings,
    pub current_time: f32,
    pub duration: Option<f32>,
    current_fade: Option<Fade>,
}

#[derive(Debug, Clone, Copy)]
pub enum Fade {
    In(FadeSettings),
    Out(FadeSettings),
}

impl AudioTrack {
    pub fn new(path: String) -> Self {
        Self {
            path,
            settings: AudioSettings::default(),
            current_time: 0.0,
            duration: None,
            current_fade: None,
        }
    }

    pub fn with_settings(mut self, settings: AudioSettings) -> Self {
        self.settings = settings;
        self
    }

    pub fn start_fade_in(&mut self, duration_secs: f32) {
        self.current_fade = Some(Fade::In(FadeSettings::new(duration_secs)));
    }

    pub fn start_fade_out(&mut self, duration_secs: f32) {
        self.current_fade = Some(Fade::Out(
            FadeSettings::new(duration_secs).with_target(0.0),
        ));
    }

    pub fn update(&mut self, delta_secs: f32) {
        if let Some(fade) = &mut self.current_fade {
            match fade {
                Fade::In(settings) | Fade::Out(settings) => {
                    settings.update(delta_secs);
                    if settings.is_complete() {
                        self.current_fade = None;
                    }
                }
            }
        }
    }

    pub fn effective_volume(&self) -> f32 {
        let base_volume = self.settings.volume;
        match &self.current_fade {
            Some(Fade::In(settings)) => base_volume * settings.progress(),
            Some(Fade::Out(settings)) => base_volume * (1.0 - settings.progress()),
            None => base_volume,
        }
    }

    pub fn is_fading(&self) -> bool {
        self.current_fade.is_some()
    }
}

#[derive(Debug, Clone)]
pub struct AudioChannel {
    pub name: String,
    pub volume: f32,
    pub muted: bool,
    pub tracks: Vec<u32>,
}

impl AudioChannel {
    pub fn new(name: String) -> Self {
        Self {
            name,
            volume: 1.0,
            muted: false,
            tracks: Vec::new(),
        }
    }

    pub fn with_volume(mut self, volume: f32) -> Self {
        self.volume = volume.clamp(0.0, 2.0);
        self
    }

    pub fn mute(&mut self) {
        self.muted = true;
    }

    pub fn unmute(&mut self) {
        self.muted = false;
    }

    pub fn effective_volume(&self) -> f32 {
        if self.muted {
            0.0
        } else {
            self.volume
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct AudioMixer {
    pub master_volume: f32,
    pub muted: bool,
    channels: HashMap<String, AudioChannel>,
    tracks: HashMap<u32, AudioTrack>,
    next_track_id: u32,
}

impl AudioMixer {
    pub fn new() -> Self {
        let mut mixer = Self {
            master_volume: 1.0,
            muted: false,
            channels: HashMap::new(),
            tracks: HashMap::new(),
            next_track_id: 0,
        };
        mixer.add_channel("music".to_string());
        mixer.add_channel("sfx".to_string());
        mixer.add_channel("voice".to_string());
        mixer
    }

    pub fn add_channel(&mut self, name: String) -> &mut AudioChannel {
        self.channels
            .entry(name.clone())
            .or_insert_with(|| AudioChannel::new(name))
    }

    pub fn get_channel(&self, name: &str) -> Option<&AudioChannel> {
        self.channels.get(name)
    }

    pub fn get_channel_mut(&mut self, name: &str) -> Option<&mut AudioChannel> {
        self.channels.get_mut(name)
    }

    pub fn set_channel_volume(&mut self, name: &str, volume: f32) {
        if let Some(channel) = self.channels.get_mut(name) {
            channel.volume = volume.clamp(0.0, 2.0);
        }
    }

    pub fn mute_channel(&mut self, name: &str) {
        if let Some(channel) = self.channels.get_mut(name) {
            channel.mute();
        }
    }

    pub fn unmute_channel(&mut self, name: &str) {
        if let Some(channel) = self.channels.get_mut(name) {
            channel.unmute();
        }
    }

    pub fn play(&mut self, path: String, channel: &str) -> u32 {
        self.play_with_settings(path, channel, AudioSettings::default())
    }

    pub fn play_with_settings(
        &mut self,
        path: String,
        channel: &str,
        settings: AudioSettings,
    ) -> u32 {
        let track_id = self.next_track_id;
        self.next_track_id += 1;

        let track = AudioTrack::new(path).with_settings(settings);
        self.tracks.insert(track_id, track);

        if let Some(ch) = self.channels.get_mut(channel) {
            ch.tracks.push(track_id);
        }

        track_id
    }

    pub fn stop(&mut self, track_id: u32) {
        self.tracks.remove(&track_id);
        for channel in self.channels.values_mut() {
            channel.tracks.retain(|&id| id != track_id);
        }
    }

    pub fn stop_with_fade(&mut self, track_id: u32, fade_duration: f32) {
        if let Some(track) = self.tracks.get_mut(&track_id) {
            track.start_fade_out(fade_duration);
        }
    }

    pub fn pause(&mut self, track_id: u32) {
        if let Some(track) = self.tracks.get_mut(&track_id) {
            track.settings.paused = true;
        }
    }

    pub fn resume(&mut self, track_id: u32) {
        if let Some(track) = self.tracks.get_mut(&track_id) {
            track.settings.paused = false;
        }
    }

    pub fn get_track(&self, track_id: u32) -> Option<&AudioTrack> {
        self.tracks.get(&track_id)
    }

    pub fn get_track_mut(&mut self, track_id: u32) -> Option<&mut AudioTrack> {
        self.tracks.get_mut(&track_id)
    }

    pub fn update(&mut self, delta_secs: f32) {
        let mut completed = Vec::new();
        for (&id, track) in self.tracks.iter_mut() {
            track.update(delta_secs);
            if let Some(Fade::Out(settings)) = &track.current_fade {
                if settings.is_complete() {
                    completed.push(id);
                }
            }
        }
        for id in completed {
            self.stop(id);
        }
    }

    pub fn effective_volume(&self, track_id: u32, channel_name: &str) -> f32 {
        if self.muted {
            return 0.0;
        }

        let channel_volume = self
            .channels
            .get(channel_name)
            .map_or(1.0, |c| c.effective_volume());
        let track_volume = self
            .tracks
            .get(&track_id)
            .map_or(1.0, |t| t.effective_volume());

        self.master_volume * channel_volume * track_volume
    }
}

#[derive(Debug, Clone)]
pub struct AudioQueue {
    pub tracks: Vec<String>,
    pub current_index: usize,
    pub loop_queue: bool,
    pub shuffle: bool,
}

impl Default for AudioQueue {
    fn default() -> Self {
        Self {
            tracks: Vec::new(),
            current_index: 0,
            loop_queue: false,
            shuffle: false,
        }
    }
}

impl AudioQueue {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add(&mut self, path: String) {
        self.tracks.push(path);
    }

    pub fn add_all(&mut self, paths: Vec<String>) {
        self.tracks.extend(paths);
    }

    pub fn current(&self) -> Option<&String> {
        self.tracks.get(self.current_index)
    }

    pub fn next(&mut self) -> Option<&String> {
        if self.tracks.is_empty() {
            return None;
        }

        self.current_index += 1;
        if self.current_index >= self.tracks.len() {
            if self.loop_queue {
                self.current_index = 0;
            } else {
                return None;
            }
        }
        self.current()
    }

    pub fn previous(&mut self) -> Option<&String> {
        if self.tracks.is_empty() {
            return None;
        }

        if self.current_index == 0 {
            if self.loop_queue {
                self.current_index = self.tracks.len() - 1;
            } else {
                return None;
            }
        } else {
            self.current_index -= 1;
        }
        self.current()
    }

    pub fn clear(&mut self) {
        self.tracks.clear();
        self.current_index = 0;
    }

    pub fn len(&self) -> usize {
        self.tracks.len()
    }

    pub fn is_empty(&self) -> bool {
        self.tracks.is_empty()
    }
}

#[derive(Debug, Clone, Copy)]
pub struct SpatialAudio {
    pub max_distance: f32,
    pub reference_distance: f32,
    pub rolloff_factor: f32,
    pub cone_inner_angle: f32,
    pub cone_outer_angle: f32,
    pub cone_outer_gain: f32,
}

impl Default for SpatialAudio {
    fn default() -> Self {
        Self {
            max_distance: 100.0,
            reference_distance: 1.0,
            rolloff_factor: 1.0,
            cone_inner_angle: 360.0,
            cone_outer_angle: 360.0,
            cone_outer_gain: 0.0,
        }
    }
}

impl SpatialAudio {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_max_distance(mut self, distance: f32) -> Self {
        self.max_distance = distance.max(0.0);
        self
    }

    pub fn with_reference_distance(mut self, distance: f32) -> Self {
        self.reference_distance = distance.max(0.0);
        self
    }

    pub fn with_rolloff(mut self, factor: f32) -> Self {
        self.rolloff_factor = factor.max(0.0);
        self
    }

    pub fn with_cone(mut self, inner: f32, outer: f32, outer_gain: f32) -> Self {
        self.cone_inner_angle = inner.clamp(0.0, 360.0);
        self.cone_outer_angle = outer.clamp(0.0, 360.0);
        self.cone_outer_gain = outer_gain.clamp(0.0, 1.0);
        self
    }

    pub fn calculate_attenuation(&self, distance: f32) -> f32 {
        if distance <= self.reference_distance {
            1.0
        } else if distance >= self.max_distance {
            0.0
        } else {
            let d = distance.clamp(self.reference_distance, self.max_distance);
            self.reference_distance
                / (self.reference_distance
                    + self.rolloff_factor * (d - self.reference_distance))
        }
    }
}
