use bevy_color::{Alpha, Color};
use bevy_ecs::component::Component;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BlendMode {
    Opaque,
    Blend,
    AlphaBlend,
    Premultiplied,
    Add,
    Multiply,
}

impl Default for BlendMode {
    fn default() -> Self {
        Self::Blend
    }
}

#[derive(Debug, Clone)]
pub struct MaterialProperties {
    pub base_color: Color,
    pub emissive: Color,
    pub metallic: f32,
    pub roughness: f32,
    pub reflectance: f32,
    pub alpha_mode: BlendMode,
    pub unlit: bool,
    pub double_sided: bool,
}

impl Default for MaterialProperties {
    fn default() -> Self {
        Self {
            base_color: Color::WHITE,
            emissive: Color::BLACK,
            metallic: 0.0,
            roughness: 0.5,
            reflectance: 0.5,
            alpha_mode: BlendMode::Opaque,
            unlit: false,
            double_sided: false,
        }
    }
}

impl MaterialProperties {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.base_color = Color::srgba(r, g, b, a);
        if a < 1.0 {
            self.alpha_mode = BlendMode::Blend;
        }
        self
    }

    pub fn with_emissive(mut self, r: f32, g: f32, b: f32) -> Self {
        self.emissive = Color::srgb(r, g, b);
        self
    }

    pub fn with_metallic(mut self, metallic: f32) -> Self {
        self.metallic = metallic.clamp(0.0, 1.0);
        self
    }

    pub fn with_roughness(mut self, roughness: f32) -> Self {
        self.roughness = roughness.clamp(0.0, 1.0);
        self
    }

    pub fn with_reflectance(mut self, reflectance: f32) -> Self {
        self.reflectance = reflectance.clamp(0.0, 1.0);
        self
    }

    pub fn with_alpha_mode(mut self, mode: BlendMode) -> Self {
        self.alpha_mode = mode;
        self
    }

    pub fn unlit(mut self) -> Self {
        self.unlit = true;
        self
    }

    pub fn double_sided(mut self) -> Self {
        self.double_sided = true;
        self
    }
}

#[derive(Component, Debug, Clone)]
pub struct ColorMaterial {
    pub color: Color,
    pub alpha_mode: BlendMode,
}

impl Default for ColorMaterial {
    fn default() -> Self {
        Self {
            color: Color::WHITE,
            alpha_mode: BlendMode::Blend,
        }
    }
}

impl ColorMaterial {
    pub fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        let color = Color::srgba(r, g, b, a);
        let alpha_mode = if a < 1.0 {
            BlendMode::Blend
        } else {
            BlendMode::Opaque
        };
        Self { color, alpha_mode }
    }

    pub fn from_color(color: Color) -> Self {
        let alpha_mode = if color.alpha() < 1.0 {
            BlendMode::Blend
        } else {
            BlendMode::Opaque
        };
        Self { color, alpha_mode }
    }

    pub fn with_alpha_mode(mut self, mode: BlendMode) -> Self {
        self.alpha_mode = mode;
        self
    }
}

#[derive(Component, Debug, Clone)]
pub struct StandardMaterial {
    pub base_color: Color,
    pub emissive: Color,
    pub metallic: f32,
    pub roughness: f32,
    pub reflectance: f32,
    pub alpha_mode: BlendMode,
    pub unlit: bool,
    pub double_sided: bool,
    pub texture_path: Option<String>,
    pub normal_map_path: Option<String>,
}

impl Default for StandardMaterial {
    fn default() -> Self {
        Self {
            base_color: Color::WHITE,
            emissive: Color::BLACK,
            metallic: 0.0,
            roughness: 0.5,
            reflectance: 0.5,
            alpha_mode: BlendMode::Opaque,
            unlit: false,
            double_sided: false,
            texture_path: None,
            normal_map_path: None,
        }
    }
}

impl StandardMaterial {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_color(r: f32, g: f32, b: f32, a: f32) -> Self {
        let alpha_mode = if a < 1.0 {
            BlendMode::Blend
        } else {
            BlendMode::Opaque
        };
        Self {
            base_color: Color::srgba(r, g, b, a),
            alpha_mode,
            ..Default::default()
        }
    }

    pub fn with_base_color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.base_color = Color::srgba(r, g, b, a);
        if a < 1.0 && self.alpha_mode == BlendMode::Opaque {
            self.alpha_mode = BlendMode::Blend;
        }
        self
    }

    pub fn with_emissive(mut self, r: f32, g: f32, b: f32) -> Self {
        self.emissive = Color::srgb(r, g, b);
        self
    }

    pub fn with_metallic(mut self, metallic: f32) -> Self {
        self.metallic = metallic.clamp(0.0, 1.0);
        self
    }

    pub fn with_roughness(mut self, roughness: f32) -> Self {
        self.roughness = roughness.clamp(0.0, 1.0);
        self
    }

    pub fn with_reflectance(mut self, reflectance: f32) -> Self {
        self.reflectance = reflectance.clamp(0.0, 1.0);
        self
    }

    pub fn with_alpha_mode(mut self, mode: BlendMode) -> Self {
        self.alpha_mode = mode;
        self
    }

    pub fn unlit(mut self) -> Self {
        self.unlit = true;
        self
    }

    pub fn double_sided(mut self) -> Self {
        self.double_sided = true;
        self
    }

    pub fn with_texture(mut self, path: String) -> Self {
        self.texture_path = Some(path);
        self
    }

    pub fn with_normal_map(mut self, path: String) -> Self {
        self.normal_map_path = Some(path);
        self
    }
}

pub struct MaterialBuilder {
    material: StandardMaterial,
}

impl MaterialBuilder {
    pub fn new() -> Self {
        Self {
            material: StandardMaterial::default(),
        }
    }

    pub fn color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.material = self.material.with_base_color(r, g, b, a);
        self
    }

    pub fn emissive(mut self, r: f32, g: f32, b: f32) -> Self {
        self.material = self.material.with_emissive(r, g, b);
        self
    }

    pub fn metallic(mut self, value: f32) -> Self {
        self.material = self.material.with_metallic(value);
        self
    }

    pub fn roughness(mut self, value: f32) -> Self {
        self.material = self.material.with_roughness(value);
        self
    }

    pub fn reflectance(mut self, value: f32) -> Self {
        self.material = self.material.with_reflectance(value);
        self
    }

    pub fn unlit(mut self) -> Self {
        self.material = self.material.unlit();
        self
    }

    pub fn double_sided(mut self) -> Self {
        self.material = self.material.double_sided();
        self
    }

    pub fn texture(mut self, path: String) -> Self {
        self.material = self.material.with_texture(path);
        self
    }

    pub fn normal_map(mut self, path: String) -> Self {
        self.material = self.material.with_normal_map(path);
        self
    }

    pub fn blend_mode(mut self, mode: BlendMode) -> Self {
        self.material = self.material.with_alpha_mode(mode);
        self
    }

    pub fn build(self) -> StandardMaterial {
        self.material
    }
}

impl Default for MaterialBuilder {
    fn default() -> Self {
        Self::new()
    }
}
