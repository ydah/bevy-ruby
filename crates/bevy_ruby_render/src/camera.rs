use bevy_ecs::bundle::Bundle;
use bevy_ecs::component::Component;
use bevy_math::{Vec2, Vec3};
use bevy_render::camera::{Camera, OrthographicProjection, Projection};
use bevy_transform::components::{GlobalTransform, Transform};

#[derive(Debug, Clone)]
pub struct CameraConfig {
    pub position: Vec3,
    pub look_at: Option<Vec3>,
    pub clear_color: Option<[f32; 4]>,
    pub is_active: bool,
    pub viewport: Option<ViewportConfig>,
}

#[derive(Debug, Clone)]
pub struct ViewportConfig {
    pub physical_position: [u32; 2],
    pub physical_size: [u32; 2],
}

impl Default for CameraConfig {
    fn default() -> Self {
        Self {
            position: Vec3::new(0.0, 0.0, 1000.0),
            look_at: None,
            clear_color: None,
            is_active: true,
            viewport: None,
        }
    }
}

impl CameraConfig {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_position(mut self, x: f32, y: f32, z: f32) -> Self {
        self.position = Vec3::new(x, y, z);
        self
    }

    pub fn with_look_at(mut self, x: f32, y: f32, z: f32) -> Self {
        self.look_at = Some(Vec3::new(x, y, z));
        self
    }

    pub fn with_clear_color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.clear_color = Some([r, g, b, a]);
        self
    }

    pub fn active(mut self, active: bool) -> Self {
        self.is_active = active;
        self
    }

    pub fn with_viewport(mut self, x: u32, y: u32, width: u32, height: u32) -> Self {
        self.viewport = Some(ViewportConfig {
            physical_position: [x, y],
            physical_size: [width, height],
        });
        self
    }
}

#[derive(Bundle)]
pub struct Camera2dBundle {
    pub camera: Camera,
    pub projection: Projection,
    pub transform: Transform,
    pub global_transform: GlobalTransform,
}

impl Camera2dBundle {
    pub fn new(config: &CameraConfig) -> Self {
        let mut transform = Transform::from_translation(config.position);

        if let Some(target) = config.look_at {
            transform.look_at(target, Vec3::Y);
        }

        Self {
            camera: Camera {
                is_active: config.is_active,
                ..Default::default()
            },
            projection: Projection::Orthographic(OrthographicProjection::default_2d()),
            transform,
            global_transform: GlobalTransform::default(),
        }
    }

    pub fn default_2d() -> Self {
        Self::new(&CameraConfig::default())
    }
}

impl Default for Camera2dBundle {
    fn default() -> Self {
        Self::default_2d()
    }
}

#[derive(Bundle)]
pub struct Camera3dBundle {
    pub camera: Camera,
    pub projection: Projection,
    pub transform: Transform,
    pub global_transform: GlobalTransform,
}

impl Camera3dBundle {
    pub fn new(config: &CameraConfig) -> Self {
        let mut transform = Transform::from_translation(config.position);

        if let Some(target) = config.look_at {
            transform.look_at(target, Vec3::Y);
        }

        Self {
            camera: Camera {
                is_active: config.is_active,
                ..Default::default()
            },
            projection: Projection::default(),
            transform,
            global_transform: GlobalTransform::default(),
        }
    }

    pub fn default_3d() -> Self {
        Self::new(&CameraConfig::new().with_position(0.0, 5.0, 10.0).with_look_at(0.0, 0.0, 0.0))
    }
}

impl Default for Camera3dBundle {
    fn default() -> Self {
        Self::default_3d()
    }
}

pub struct CameraController {
    pub speed: f32,
    pub sensitivity: f32,
}

impl Default for CameraController {
    fn default() -> Self {
        Self {
            speed: 10.0,
            sensitivity: 0.1,
        }
    }
}

impl CameraController {
    pub fn new(speed: f32, sensitivity: f32) -> Self {
        Self { speed, sensitivity }
    }
}

#[derive(Component, Debug, Clone)]
pub struct SmoothFollow {
    pub target: Option<Vec3>,
    pub offset: Vec3,
    pub smoothness: f32,
    pub enabled: bool,
}

impl Default for SmoothFollow {
    fn default() -> Self {
        Self {
            target: None,
            offset: Vec3::ZERO,
            smoothness: 5.0,
            enabled: true,
        }
    }
}

impl SmoothFollow {
    pub fn new(smoothness: f32) -> Self {
        Self {
            smoothness,
            ..Default::default()
        }
    }

    pub fn with_offset(mut self, x: f32, y: f32, z: f32) -> Self {
        self.offset = Vec3::new(x, y, z);
        self
    }

    pub fn with_target(mut self, x: f32, y: f32, z: f32) -> Self {
        self.target = Some(Vec3::new(x, y, z));
        self
    }

    pub fn lerp_position(&self, current: Vec3, delta_time: f32) -> Vec3 {
        if let Some(target) = self.target {
            let desired = target + self.offset;
            let t = (self.smoothness * delta_time).min(1.0);
            current.lerp(desired, t)
        } else {
            current
        }
    }
}

#[derive(Component, Debug, Clone)]
pub struct CameraShake {
    pub intensity: f32,
    pub duration: f32,
    pub decay: f32,
    pub remaining_time: f32,
    pub frequency: f32,
    time_elapsed: f32,
}

impl Default for CameraShake {
    fn default() -> Self {
        Self {
            intensity: 0.0,
            duration: 0.0,
            decay: 1.0,
            remaining_time: 0.0,
            frequency: 20.0,
            time_elapsed: 0.0,
        }
    }
}

impl CameraShake {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn trigger(&mut self, intensity: f32, duration: f32) {
        self.intensity = intensity;
        self.duration = duration;
        self.remaining_time = duration;
        self.time_elapsed = 0.0;
    }

    pub fn trigger_with_decay(&mut self, intensity: f32, duration: f32, decay: f32) {
        self.intensity = intensity;
        self.duration = duration;
        self.decay = decay;
        self.remaining_time = duration;
        self.time_elapsed = 0.0;
    }

    pub fn update(&mut self, delta_time: f32) -> Vec2 {
        if self.remaining_time <= 0.0 {
            return Vec2::ZERO;
        }

        self.remaining_time -= delta_time;
        self.time_elapsed += delta_time;

        let progress = 1.0 - (self.remaining_time / self.duration);
        let decay_factor = (1.0 - progress).powf(self.decay);
        let current_intensity = self.intensity * decay_factor;

        let angle = self.time_elapsed * self.frequency * std::f32::consts::TAU;
        let x = angle.sin() * current_intensity;
        let y = (angle * 1.3).cos() * current_intensity;

        Vec2::new(x, y)
    }

    pub fn is_active(&self) -> bool {
        self.remaining_time > 0.0
    }

    pub fn stop(&mut self) {
        self.remaining_time = 0.0;
    }
}

#[derive(Component, Debug, Clone)]
pub struct CameraBounds {
    pub min: Vec2,
    pub max: Vec2,
    pub enabled: bool,
}

impl Default for CameraBounds {
    fn default() -> Self {
        Self {
            min: Vec2::new(f32::MIN, f32::MIN),
            max: Vec2::new(f32::MAX, f32::MAX),
            enabled: false,
        }
    }
}

impl CameraBounds {
    pub fn new(min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> Self {
        Self {
            min: Vec2::new(min_x, min_y),
            max: Vec2::new(max_x, max_y),
            enabled: true,
        }
    }

    pub fn clamp(&self, position: Vec3) -> Vec3 {
        if !self.enabled {
            return position;
        }
        Vec3::new(
            position.x.clamp(self.min.x, self.max.x),
            position.y.clamp(self.min.y, self.max.y),
            position.z,
        )
    }
}

#[derive(Component, Debug, Clone)]
pub struct CameraZoom {
    pub current: f32,
    pub min: f32,
    pub max: f32,
    pub speed: f32,
}

impl Default for CameraZoom {
    fn default() -> Self {
        Self {
            current: 1.0,
            min: 0.1,
            max: 10.0,
            speed: 1.0,
        }
    }
}

impl CameraZoom {
    pub fn new(initial: f32) -> Self {
        Self {
            current: initial,
            ..Default::default()
        }
    }

    pub fn with_limits(mut self, min: f32, max: f32) -> Self {
        self.min = min;
        self.max = max;
        self
    }

    pub fn zoom_in(&mut self, amount: f32) {
        self.current = (self.current - amount * self.speed).clamp(self.min, self.max);
    }

    pub fn zoom_out(&mut self, amount: f32) {
        self.current = (self.current + amount * self.speed).clamp(self.min, self.max);
    }

    pub fn set_zoom(&mut self, value: f32) {
        self.current = value.clamp(self.min, self.max);
    }
}
