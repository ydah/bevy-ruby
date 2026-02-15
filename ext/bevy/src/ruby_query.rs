use bevy_ruby::QueryBuilder;
use magnus::{function, method, prelude::*, Error, RArray, RModule, Ruby};
use std::cell::RefCell;

#[magnus::wrap(class = "Bevy::QueryBuilder", free_immediately, size)]
pub struct RubyQueryBuilder {
    inner: RefCell<QueryBuilder>,
}

impl RubyQueryBuilder {
    fn new() -> Self {
        Self {
            inner: RefCell::new(QueryBuilder::new()),
        }
    }

    fn fetch(&self, component_name: String) -> Self {
        let builder = self.inner.borrow().clone().fetch(&component_name);
        Self {
            inner: RefCell::new(builder),
        }
    }

    fn fetch_components(&self) -> RArray {
        let ruby = Ruby::get().unwrap();
        let components = self.inner.borrow();
        let fetch = components.fetch_components();
        let array = ruby.ary_new_capa(fetch.len());
        for name in fetch {
            let _ = array.push(name.clone());
        }
        array
    }

    fn with_filter(&self, component_name: String) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().clone().fetch(&component_name)),
        }
    }

    fn without_filter(&self, _component_name: String) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().clone()),
        }
    }

    #[allow(dead_code)]
    pub fn inner(&self) -> QueryBuilder {
        self.inner.borrow().clone()
    }
}

unsafe impl Send for RubyQueryBuilder {}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let class = module.define_class("QueryBuilder", ruby.class_object())?;
    class.define_singleton_method("new", function!(RubyQueryBuilder::new, 0))?;
    class.define_method("fetch", method!(RubyQueryBuilder::fetch, 1))?;
    class.define_method("fetch_components", method!(RubyQueryBuilder::fetch_components, 0))?;
    class.define_method("with", method!(RubyQueryBuilder::with_filter, 1))?;
    class.define_method("without", method!(RubyQueryBuilder::without_filter, 1))?;

    Ok(())
}
