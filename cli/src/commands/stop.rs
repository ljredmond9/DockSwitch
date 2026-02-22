use super::{is_daemon_loaded, launchd_plist_path};
use anyhow::{bail, Result};
use std::process::Command;

pub fn run() -> Result<()> {
    let plist = launchd_plist_path();

    if !is_daemon_loaded() {
        println!("Daemon is not running.");
        return Ok(());
    }

    let status = Command::new("launchctl")
        .args(["unload", plist.to_str().unwrap()])
        .status()?;

    if status.success() {
        println!("dockswitch daemon stopped.");
    } else {
        bail!("Failed to stop daemon.");
    }

    Ok(())
}
