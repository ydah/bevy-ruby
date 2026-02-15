use bevy_ruby::{DynamicComponent, DynamicValue};
use magnus::{function, method, prelude::*, Error, RHash, RModule, Ruby, Symbol, Value};
use std::cell::RefCell;
use std::collections::HashMap;

#[magnus::wrap(class = "Bevy::Component", free_immediately, size)]
pub struct RubyComponent {
    inner: RefCell<DynamicComponent>,
}

impl RubyComponent {
    pub fn new(type_name: String) -> Self {
        Self {
            inner: RefCell::new(DynamicComponent::new(&type_name)),
        }
    }

    pub fn from_dynamic(component: DynamicComponent) -> Self {
        Self {
            inner: RefCell::new(component),
        }
    }

    pub fn inner(&self) -> DynamicComponent {
        self.inner.borrow().clone()
    }

    fn type_name(&self) -> String {
        self.inner.borrow().type_name().to_string()
    }

    fn get(&self, name: String) -> Result<Value, Error> {
        let ruby = Ruby::get().unwrap();
        let inner = self.inner.borrow();
        match inner.get(&name) {
            Some(value) => dynamic_value_to_ruby(&ruby, value),
            None => Ok(ruby.qnil().as_value()),
        }
    }

    fn set(&self, name: String, value: Value) -> Result<Value, Error> {
        let dynamic_value = ruby_to_dynamic_value(value)?;
        self.inner.borrow_mut().set(&name, dynamic_value);
        Ok(value)
    }

    fn to_h(&self) -> Result<RHash, Error> {
        let ruby = Ruby::get().unwrap();
        let hash = ruby.hash_new();
        let inner = self.inner.borrow();

        for (key, value) in &inner.data {
            let ruby_value = dynamic_value_to_ruby(&ruby, value)?;
            hash.aset(ruby.to_symbol(key), ruby_value)?;
        }

        Ok(hash)
    }

    fn from_hash(type_name: String, hash: RHash) -> Result<Self, Error> {
        let mut component = DynamicComponent::new(&type_name);

        hash.foreach(|key: Value, value: Value| {
            let key_str = if let Ok(sym) = Symbol::try_convert(key) {
                sym.name().map(|s| s.to_string()).unwrap_or_default()
            } else {
                key.to_string()
            };

            if let Ok(dynamic_value) = ruby_to_dynamic_value(value) {
                component.set(&key_str, dynamic_value);
            }
            Ok(magnus::r_hash::ForEach::Continue)
        })?;

        Ok(Self {
            inner: RefCell::new(component),
        })
    }
}

unsafe impl Send for RubyComponent {}

fn dynamic_value_to_ruby(ruby: &Ruby, value: &DynamicValue) -> Result<Value, Error> {
    match value {
        DynamicValue::Nil => Ok(ruby.qnil().as_value()),
        DynamicValue::Boolean(b) => Ok(if *b {
            ruby.qtrue().as_value()
        } else {
            ruby.qfalse().as_value()
        }),
        DynamicValue::Integer(i) => Ok(ruby.integer_from_i64(*i).as_value()),
        DynamicValue::Float(f) => Ok(ruby.float_from_f64(*f).as_value()),
        DynamicValue::String(s) => Ok(ruby.str_new(s).as_value()),
        DynamicValue::Symbol(s) => Ok(ruby.to_symbol(s).as_value()),
        DynamicValue::Array(arr) => {
            let ruby_arr = ruby.ary_new();
            for item in arr {
                ruby_arr.push(dynamic_value_to_ruby(ruby, item)?)?;
            }
            Ok(ruby_arr.as_value())
        }
        DynamicValue::Hash(h) => {
            let ruby_hash = ruby.hash_new();
            for (k, v) in h {
                ruby_hash.aset(ruby.to_symbol(k), dynamic_value_to_ruby(ruby, v)?)?;
            }
            Ok(ruby_hash.as_value())
        }
    }
}

fn ruby_to_dynamic_value(value: Value) -> Result<DynamicValue, Error> {
    let ruby = Ruby::get().unwrap();

    if value.is_nil() {
        return Ok(DynamicValue::Nil);
    }

    if value.is_kind_of(ruby.class_true_class()) || value.is_kind_of(ruby.class_false_class()) {
        if let Ok(b) = bool::try_convert(value) {
            return Ok(DynamicValue::Boolean(b));
        }
    }

    if value.is_kind_of(ruby.class_integer()) {
        if let Ok(i) = i64::try_convert(value) {
            return Ok(DynamicValue::Integer(i));
        }
    }

    if value.is_kind_of(ruby.class_float()) {
        if let Ok(f) = f64::try_convert(value) {
            return Ok(DynamicValue::Float(f));
        }
    }

    if let Ok(sym) = Symbol::try_convert(value) {
        return Ok(DynamicValue::Symbol(
            sym.name().map(|s| s.to_string()).unwrap_or_default(),
        ));
    }

    if value.is_kind_of(ruby.class_string()) {
        if let Ok(s) = String::try_convert(value) {
            return Ok(DynamicValue::String(s));
        }
    }

    if let Ok(arr) = magnus::RArray::try_convert(value) {
        let mut result = Vec::new();
        for item in arr.into_iter() {
            result.push(ruby_to_dynamic_value(item)?);
        }
        return Ok(DynamicValue::Array(result));
    }

    if let Ok(hash) = RHash::try_convert(value) {
        let mut result = HashMap::new();
        hash.foreach(|k: Value, v: Value| {
            let key = if let Ok(sym) = Symbol::try_convert(k) {
                sym.name().map(|s| s.to_string()).unwrap_or_default()
            } else {
                k.to_string()
            };
            if let Ok(dv) = ruby_to_dynamic_value(v) {
                result.insert(key, dv);
            }
            Ok(magnus::r_hash::ForEach::Continue)
        })?;
        return Ok(DynamicValue::Hash(result));
    }

    Err(Error::new(
        ruby.exception_type_error(),
        format!("Cannot convert {:?} to DynamicValue", value),
    ))
}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let class = module.define_class("Component", ruby.class_object())?;
    class.define_singleton_method("new", function!(RubyComponent::new, 1))?;
    class.define_singleton_method("from_hash", function!(RubyComponent::from_hash, 2))?;
    class.define_method("type_name", method!(RubyComponent::type_name, 0))?;
    class.define_method("[]", method!(RubyComponent::get, 1))?;
    class.define_method("[]=", method!(RubyComponent::set, 2))?;
    class.define_method("to_h", method!(RubyComponent::to_h, 0))?;
    Ok(())
}
