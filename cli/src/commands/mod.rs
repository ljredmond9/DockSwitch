pub mod logs;
pub mod restart;
pub mod start;
pub mod status;
pub mod stop;
pub mod uninstall;
pub mod update;

use clap::{Parser, Subcommand};
use std::path::PathBuf;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
pub const LAUNCHD_LABEL: &str = "com.dockswitch";
pub const GITHUB_REPO: &str = "ljredmond9/dockswitch";

pub fn home_dir() -> PathBuf {
    PathBuf::from(std::env::var("HOME").expect("HOME not set"))
}

pub fn daemon_binary_path() -> PathBuf {
    home_dir().join(".local/bin/dockswitchd")
}

pub fn cli_binary_path() -> PathBuf {
    home_dir().join(".local/bin/dockswitch")
}

pub fn launchd_plist_path() -> PathBuf {
    home_dir().join("Library/LaunchAgents/com.dockswitch.plist")
}

pub fn config_plist_path() -> PathBuf {
    home_dir().join("Library/Preferences/com.dockswitch.plist")
}

pub fn log_file_path() -> PathBuf {
    home_dir().join("Library/Logs/dockswitch.log")
}

#[derive(Parser)]
#[command(name = "dockswitch", about = "Manage the dockswitch daemon", version = VERSION)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Start the dockswitch daemon
    Start,
    /// Stop the dockswitch daemon
    Stop,
    /// Restart the dockswitch daemon
    Restart,
    /// Show daemon status and configuration
    Status,
    /// Tail the dockswitch log file
    Logs,
    /// Update dockswitch to the latest release
    Update,
    /// Uninstall dockswitch completely
    Uninstall,
}

/// Check if the daemon is currently loaded in launchd.
pub fn is_daemon_loaded() -> bool {
    std::process::Command::new("launchctl")
        .args(["list"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).contains(LAUNCHD_LABEL))
        .unwrap_or(false)
}
