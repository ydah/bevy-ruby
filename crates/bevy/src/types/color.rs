use bevy_color::{Alpha, Color, Srgba};

#[derive(Debug, Clone, Copy)]
pub struct RubyColor {
    inner: Srgba,
}

impl RubyColor {
    pub fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Self {
            inner: Srgba::new(r, g, b, a),
        }
    }

    pub fn rgb(r: f32, g: f32, b: f32) -> Self {
        Self::new(r, g, b, 1.0)
    }

    pub fn rgba(r: f32, g: f32, b: f32, a: f32) -> Self {
        Self::new(r, g, b, a)
    }

    pub fn from_hex(hex: &str) -> Option<Self> {
        Srgba::hex(hex).ok().map(|c| Self { inner: c })
    }

    pub fn white() -> Self {
        Self::new(1.0, 1.0, 1.0, 1.0)
    }

    pub fn black() -> Self {
        Self::new(0.0, 0.0, 0.0, 1.0)
    }

    pub fn red() -> Self {
        Self::new(1.0, 0.0, 0.0, 1.0)
    }

    pub fn green() -> Self {
        Self::new(0.0, 1.0, 0.0, 1.0)
    }

    pub fn blue() -> Self {
        Self::new(0.0, 0.0, 1.0, 1.0)
    }

    pub fn transparent() -> Self {
        Self::new(0.0, 0.0, 0.0, 0.0)
    }

    pub fn r(&self) -> f32 {
        self.inner.red
    }

    pub fn g(&self) -> f32 {
        self.inner.green
    }

    pub fn b(&self) -> f32 {
        self.inner.blue
    }

    pub fn a(&self) -> f32 {
        self.inner.alpha
    }

    pub fn set_r(&mut self, r: f32) {
        self.inner.red = r;
    }

    pub fn set_g(&mut self, g: f32) {
        self.inner.green = g;
    }

    pub fn set_b(&mut self, b: f32) {
        self.inner.blue = b;
    }

    pub fn set_a(&mut self, a: f32) {
        self.inner.alpha = a;
    }

    pub fn with_alpha(&self, alpha: f32) -> Self {
        Self {
            inner: self.inner.with_alpha(alpha),
        }
    }

    pub fn to_bevy(&self) -> Color {
        Color::Srgba(self.inner)
    }

    pub fn to_srgba(&self) -> Srgba {
        self.inner
    }

    pub fn to_array(&self) -> [f32; 4] {
        [self.inner.red, self.inner.green, self.inner.blue, self.inner.alpha]
    }
}

impl From<Srgba> for RubyColor {
    fn from(color: Srgba) -> Self {
        Self { inner: color }
    }
}

impl From<Color> for RubyColor {
    fn from(color: Color) -> Self {
        Self {
            inner: color.to_srgba(),
        }
    }
}
