use super::{is_daemon_loaded, launchd_plist_path};
use std::io;
use std::process::Command;

pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    let plist = launchd_plist_path();

    if !plist.exists() {
        return Err("Launchd plist not found. Run install.sh first.".into());
    }

    if is_daemon_loaded() {
        println!("Daemon is already running.");
        return Ok(());
    }

    let status = Command::new("launchctl")
        .args(["load", plist.to_str().unwrap()])
        .status()
        .map_err(|e: io::Error| -> Box<dyn std::error::Error> { e.into() })?;

    if status.success() {
        println!("dockswitch daemon started.");
    } else {
        return Err("Failed to start daemon.".into());
    }

    Ok(())
}
