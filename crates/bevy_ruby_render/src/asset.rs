use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::time::SystemTime;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AssetLoadState {
    NotLoaded,
    Loading,
    Loaded,
    Failed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct AssetId(pub u64);

impl AssetId {
    pub fn new(id: u64) -> Self {
        Self(id)
    }
}

#[derive(Debug, Clone)]
pub struct AssetMeta {
    pub id: AssetId,
    pub path: PathBuf,
    pub asset_type: String,
    pub state: AssetLoadState,
    pub last_modified: Option<SystemTime>,
    pub dependencies: Vec<AssetId>,
    pub dependents: Vec<AssetId>,
}

impl AssetMeta {
    pub fn new(id: AssetId, path: PathBuf, asset_type: String) -> Self {
        Self {
            id,
            path,
            asset_type,
            state: AssetLoadState::NotLoaded,
            last_modified: None,
            dependencies: Vec::new(),
            dependents: Vec::new(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct AssetChangeEvent {
    pub id: AssetId,
    pub path: PathBuf,
    pub change_type: AssetChangeType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AssetChangeType {
    Created,
    Modified,
    Deleted,
}

pub struct FileWatcher {
    watched_paths: HashMap<PathBuf, SystemTime>,
    base_paths: Vec<PathBuf>,
    extensions: HashSet<String>,
}

impl FileWatcher {
    pub fn new() -> Self {
        Self {
            watched_paths: HashMap::new(),
            base_paths: Vec::new(),
            extensions: HashSet::new(),
        }
    }

    pub fn add_base_path(&mut self, path: PathBuf) {
        self.base_paths.push(path);
    }

    pub fn add_extension(&mut self, ext: String) {
        self.extensions.insert(ext.to_lowercase());
    }

    pub fn watch(&mut self, path: &Path) -> bool {
        if let Ok(metadata) = std::fs::metadata(path) {
            if let Ok(modified) = metadata.modified() {
                self.watched_paths.insert(path.to_path_buf(), modified);
                return true;
            }
        }
        false
    }

    pub fn unwatch(&mut self, path: &Path) {
        self.watched_paths.remove(path);
    }

    pub fn check_changes(&mut self) -> Vec<(PathBuf, AssetChangeType)> {
        let mut changes = Vec::new();
        let mut to_remove = Vec::new();

        for (path, last_modified) in &self.watched_paths {
            match std::fs::metadata(path) {
                Ok(metadata) => {
                    if let Ok(modified) = metadata.modified() {
                        if modified > *last_modified {
                            changes.push((path.clone(), AssetChangeType::Modified));
                        }
                    }
                }
                Err(_) => {
                    changes.push((path.clone(), AssetChangeType::Deleted));
                    to_remove.push(path.clone());
                }
            }
        }

        for path in to_remove {
            self.watched_paths.remove(&path);
        }

        for (path, change_type) in &changes {
            if *change_type == AssetChangeType::Modified {
                if let Ok(metadata) = std::fs::metadata(path) {
                    if let Ok(modified) = metadata.modified() {
                        self.watched_paths.insert(path.clone(), modified);
                    }
                }
            }
        }

        changes
    }

    pub fn watched_count(&self) -> usize {
        self.watched_paths.len()
    }
}

impl Default for FileWatcher {
    fn default() -> Self {
        Self::new()
    }
}

pub struct AssetRegistry {
    assets: HashMap<AssetId, AssetMeta>,
    path_to_id: HashMap<PathBuf, AssetId>,
    next_id: u64,
    file_watcher: FileWatcher,
    hot_reload_enabled: bool,
}

impl AssetRegistry {
    pub fn new() -> Self {
        Self {
            assets: HashMap::new(),
            path_to_id: HashMap::new(),
            next_id: 0,
            file_watcher: FileWatcher::new(),
            hot_reload_enabled: false,
        }
    }

    pub fn enable_hot_reload(&mut self) {
        self.hot_reload_enabled = true;
    }

    pub fn disable_hot_reload(&mut self) {
        self.hot_reload_enabled = false;
    }

    pub fn is_hot_reload_enabled(&self) -> bool {
        self.hot_reload_enabled
    }

    pub fn register(&mut self, path: PathBuf, asset_type: String) -> AssetId {
        if let Some(&id) = self.path_to_id.get(&path) {
            return id;
        }

        let id = AssetId::new(self.next_id);
        self.next_id += 1;

        let meta = AssetMeta::new(id, path.clone(), asset_type);
        self.assets.insert(id, meta);
        self.path_to_id.insert(path.clone(), id);

        if self.hot_reload_enabled {
            self.file_watcher.watch(&path);
        }

        id
    }

    pub fn unregister(&mut self, id: AssetId) {
        if let Some(meta) = self.assets.remove(&id) {
            self.path_to_id.remove(&meta.path);
            if self.hot_reload_enabled {
                self.file_watcher.unwatch(&meta.path);
            }
        }
    }

    pub fn get(&self, id: AssetId) -> Option<&AssetMeta> {
        self.assets.get(&id)
    }

    pub fn get_mut(&mut self, id: AssetId) -> Option<&mut AssetMeta> {
        self.assets.get_mut(&id)
    }

    pub fn get_by_path(&self, path: &Path) -> Option<&AssetMeta> {
        self.path_to_id
            .get(path)
            .and_then(|id| self.assets.get(id))
    }

    pub fn set_state(&mut self, id: AssetId, state: AssetLoadState) {
        if let Some(meta) = self.assets.get_mut(&id) {
            meta.state = state;
            if state == AssetLoadState::Loaded {
                if let Ok(file_meta) = std::fs::metadata(&meta.path) {
                    meta.last_modified = file_meta.modified().ok();
                }
            }
        }
    }

    pub fn add_dependency(&mut self, asset_id: AssetId, dependency_id: AssetId) {
        if let Some(meta) = self.assets.get_mut(&asset_id) {
            if !meta.dependencies.contains(&dependency_id) {
                meta.dependencies.push(dependency_id);
            }
        }
        if let Some(dep_meta) = self.assets.get_mut(&dependency_id) {
            if !dep_meta.dependents.contains(&asset_id) {
                dep_meta.dependents.push(asset_id);
            }
        }
    }

    pub fn check_for_changes(&mut self) -> Vec<AssetChangeEvent> {
        if !self.hot_reload_enabled {
            return Vec::new();
        }

        let changes = self.file_watcher.check_changes();
        changes
            .into_iter()
            .filter_map(|(path, change_type)| {
                self.path_to_id.get(&path).map(|&id| AssetChangeEvent {
                    id,
                    path,
                    change_type,
                })
            })
            .collect()
    }

    pub fn get_dependents(&self, id: AssetId) -> Vec<AssetId> {
        self.assets
            .get(&id)
            .map_or_else(Vec::new, |meta| meta.dependents.clone())
    }

    pub fn get_reload_list(&self, changed_id: AssetId) -> Vec<AssetId> {
        let mut to_reload = vec![changed_id];
        let mut visited = HashSet::new();
        let mut queue = vec![changed_id];

        while let Some(id) = queue.pop() {
            if visited.contains(&id) {
                continue;
            }
            visited.insert(id);

            for dep_id in self.get_dependents(id) {
                if !visited.contains(&dep_id) {
                    to_reload.push(dep_id);
                    queue.push(dep_id);
                }
            }
        }

        to_reload
    }

    pub fn all_ids(&self) -> Vec<AssetId> {
        self.assets.keys().copied().collect()
    }

    pub fn count(&self) -> usize {
        self.assets.len()
    }
}

impl Default for AssetRegistry {
    fn default() -> Self {
        Self::new()
    }
}

pub struct AssetLoadRequest {
    pub id: AssetId,
    pub path: PathBuf,
    pub asset_type: String,
    pub priority: i32,
}

pub struct AssetLoadQueue {
    requests: Vec<AssetLoadRequest>,
}

impl AssetLoadQueue {
    pub fn new() -> Self {
        Self {
            requests: Vec::new(),
        }
    }

    pub fn enqueue(&mut self, request: AssetLoadRequest) {
        let insert_pos = self
            .requests
            .iter()
            .position(|r| r.priority < request.priority)
            .unwrap_or(self.requests.len());
        self.requests.insert(insert_pos, request);
    }

    pub fn dequeue(&mut self) -> Option<AssetLoadRequest> {
        if self.requests.is_empty() {
            None
        } else {
            Some(self.requests.remove(0))
        }
    }

    pub fn peek(&self) -> Option<&AssetLoadRequest> {
        self.requests.first()
    }

    pub fn is_empty(&self) -> bool {
        self.requests.is_empty()
    }

    pub fn len(&self) -> usize {
        self.requests.len()
    }

    pub fn clear(&mut self) {
        self.requests.clear();
    }
}

impl Default for AssetLoadQueue {
    fn default() -> Self {
        Self::new()
    }
}
