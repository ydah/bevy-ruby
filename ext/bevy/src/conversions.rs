use bevy_ruby::types::{DynamicValue, RubyColor, RubyQuat, RubyTransform, RubyVec2, RubyVec3};
use magnus::{prelude::*, Error, RHash, Ruby, TryConvert, Value};

pub fn ruby_hash_to_dynamic_value(ruby: &Ruby, hash: &RHash) -> Result<std::collections::HashMap<String, DynamicValue>, Error> {
    let mut result = std::collections::HashMap::new();

    hash.foreach(|key: Value, value: Value| {
        let key_str = String::try_convert(key)?;
        let dynamic_value = value_to_dynamic(ruby, value)?;
        result.insert(key_str, dynamic_value);
        Ok(magnus::r_hash::ForEach::Continue)
    })?;

    Ok(result)
}

pub fn value_to_dynamic(_ruby: &Ruby, value: Value) -> Result<DynamicValue, Error> {
    if value.is_nil() {
        return Ok(DynamicValue::Nil);
    }

    if let Ok(b) = bool::try_convert(value) {
        return Ok(DynamicValue::Boolean(b));
    }

    if let Ok(i) = i64::try_convert(value) {
        return Ok(DynamicValue::Integer(i));
    }

    if let Ok(f) = f64::try_convert(value) {
        return Ok(DynamicValue::Float(f));
    }

    if let Ok(s) = String::try_convert(value) {
        return Ok(DynamicValue::String(s));
    }

    Ok(DynamicValue::Nil)
}

pub fn dynamic_to_value(ruby: &Ruby, value: &DynamicValue) -> Result<Value, Error> {
    match value {
        DynamicValue::Nil => Ok(ruby.qnil().as_value()),
        DynamicValue::Boolean(b) => Ok(if *b { ruby.qtrue().as_value() } else { ruby.qfalse().as_value() }),
        DynamicValue::Integer(i) => Ok(ruby.into_value(*i)),
        DynamicValue::Float(f) => Ok(ruby.into_value(*f)),
        DynamicValue::String(s) => Ok(ruby.into_value(s.clone())),
        DynamicValue::Symbol(s) => Ok(ruby.into_value(s.clone())),
        DynamicValue::Array(arr) => {
            let array = ruby.ary_new_capa(arr.len());
            for item in arr {
                array.push(dynamic_to_value(ruby, item)?)?;
            }
            Ok(array.as_value())
        }
        DynamicValue::Hash(h) => {
            let hash = ruby.hash_new();
            for (k, v) in h {
                hash.aset(k.clone(), dynamic_to_value(ruby, v)?)?;
            }
            Ok(hash.as_value())
        }
    }
}

pub fn vec2_from_hash(ruby: &Ruby, hash: &RHash) -> Result<RubyVec2, Error> {
    let x: f64 = get_hash_value_or_default(ruby, hash, "x", 0.0)?;
    let y: f64 = get_hash_value_or_default(ruby, hash, "y", 0.0)?;
    Ok(RubyVec2::new(x as f32, y as f32))
}

pub fn vec3_from_hash(ruby: &Ruby, hash: &RHash) -> Result<RubyVec3, Error> {
    let x: f64 = get_hash_value_or_default(ruby, hash, "x", 0.0)?;
    let y: f64 = get_hash_value_or_default(ruby, hash, "y", 0.0)?;
    let z: f64 = get_hash_value_or_default(ruby, hash, "z", 0.0)?;
    Ok(RubyVec3::new(x as f32, y as f32, z as f32))
}

pub fn quat_from_hash(ruby: &Ruby, hash: &RHash) -> Result<RubyQuat, Error> {
    let x: Option<f64> = get_hash_value(ruby, hash, "x")?;
    let y: Option<f64> = get_hash_value(ruby, hash, "y")?;
    let z: Option<f64> = get_hash_value(ruby, hash, "z")?;

    if x.is_some() || y.is_some() || z.is_some() {
        Ok(RubyQuat::from_euler(
            x.unwrap_or(0.0) as f32,
            y.unwrap_or(0.0) as f32,
            z.unwrap_or(0.0) as f32,
        ))
    } else {
        Ok(RubyQuat::identity())
    }
}

pub fn color_from_hash(ruby: &Ruby, hash: &RHash) -> Result<RubyColor, Error> {
    let r: f64 = get_hash_value_or_default(ruby, hash, "r", 1.0)?;
    let g: f64 = get_hash_value_or_default(ruby, hash, "g", 1.0)?;
    let b: f64 = get_hash_value_or_default(ruby, hash, "b", 1.0)?;
    let a: f64 = get_hash_value_or_default(ruby, hash, "a", 1.0)?;
    Ok(RubyColor::rgba(r as f32, g as f32, b as f32, a as f32))
}

pub fn transform_from_hash(ruby: &Ruby, hash: &RHash) -> Result<RubyTransform, Error> {
    let tx: f64 = get_hash_value_or_default(ruby, hash, "x", 0.0)?;
    let ty: f64 = get_hash_value_or_default(ruby, hash, "y", 0.0)?;
    let tz: f64 = get_hash_value_or_default(ruby, hash, "z", 0.0)?;

    let translation = RubyVec3::new(tx as f32, ty as f32, tz as f32);

    let rotation: f64 = get_hash_value_or_default(ruby, hash, "rotation", 0.0)?;
    let quat = RubyQuat::from_rotation_z(rotation as f32);

    let sx: f64 = get_hash_value_or_default(ruby, hash, "scale_x", 1.0)?;
    let sy: f64 = get_hash_value_or_default(ruby, hash, "scale_y", 1.0)?;
    let sz: f64 = get_hash_value_or_default(ruby, hash, "scale_z", 1.0)?;
    let scale = RubyVec3::new(sx as f32, sy as f32, sz as f32);

    Ok(RubyTransform::from_translation_rotation_scale(translation, quat, scale))
}

fn get_hash_value<T: TryConvert>(ruby: &Ruby, hash: &RHash, key: &str) -> Result<Option<T>, Error> {
    let sym = ruby.to_symbol(key);
    match hash.get(sym) {
        Some(val) => {
            if val.is_nil() {
                Ok(None)
            } else {
                Ok(Some(TryConvert::try_convert(val)?))
            }
        }
        None => Ok(None),
    }
}

fn get_hash_value_or_default<T: TryConvert>(ruby: &Ruby, hash: &RHash, key: &str, default: T) -> Result<T, Error> {
    get_hash_value(ruby, hash, key).map(|opt| opt.unwrap_or(default))
}
