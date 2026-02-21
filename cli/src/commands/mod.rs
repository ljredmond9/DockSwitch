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
pub const GITHUB_REPO: &str = "ljredmond9/DockSwitch";

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
    home_dir().join("Library/Logs/DockSwitch.log")
}

#[derive(Parser)]
#[command(name = "dockswitch", about = "Manage the DockSwitch daemon", version = VERSION)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Start the DockSwitch daemon
    Start,
    /// Stop the DockSwitch daemon
    Stop,
    /// Restart the DockSwitch daemon
    Restart,
    /// Show daemon status and configuration
    Status,
    /// Tail the DockSwitch log file
    Logs,
    /// Update DockSwitch to the latest release
    Update,
    /// Uninstall DockSwitch completely
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
