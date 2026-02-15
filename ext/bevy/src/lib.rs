mod conversions;
mod ruby_app;
mod ruby_color;
mod ruby_component;
mod ruby_entity;
mod ruby_math;
mod ruby_query;
mod ruby_render_app;
mod ruby_system;
mod ruby_world;

use magnus::{Error, Ruby};

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Bevy")?;

    ruby_app::define(ruby, &module)?;
    ruby_color::define(ruby, &module)?;
    ruby_component::define(ruby, &module)?;
    ruby_math::define(ruby, &module)?;
    ruby_query::define(ruby, &module)?;
    ruby_system::define(ruby, &module)?;
    ruby_world::define(ruby, &module)?;
    ruby_entity::define(ruby, &module)?;
    ruby_render_app::define(ruby, &module)?;

    Ok(())
}
