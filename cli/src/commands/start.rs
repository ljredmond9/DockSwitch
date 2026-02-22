use super::{is_daemon_loaded, launchd_plist_path};
use anyhow::{bail, Result};
use std::process::Command;

pub fn run() -> Result<()> {
    let plist = launchd_plist_path();

    if !plist.exists() {
        bail!("Launchd plist not found. Run install.sh first.");
    }

    if is_daemon_loaded() {
        println!("Daemon is already running.");
        return Ok(());
    }

    let status = Command::new("launchctl")
        .args(["load", plist.to_str().unwrap()])
        .status()?;

    if status.success() {
        println!("dockswitch daemon started.");
    } else {
        bail!("Failed to start daemon.");
    }

    Ok(())
}
