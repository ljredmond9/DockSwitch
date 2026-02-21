use super::*;
use std::fs;
use std::process::Command;

pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    println!("Checking for updates...");

    // Get latest release tag from GitHub API
    let output = Command::new("curl")
        .args([
            "-fsSL",
            &format!(
                "https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
            ),
        ])
        .output()?;

    if !output.status.success() {
        return Err("Failed to check GitHub for latest release.".into());
    }

    let body = String::from_utf8_lossy(&output.stdout);

    // Parse tag_name from JSON (avoid adding serde dependency)
    let tag = body
        .split("\"tag_name\"")
        .nth(1)
        .and_then(|s| s.split('"').nth(1))
        .ok_or("Failed to parse release tag from GitHub API response.")?;

    let latest_version = tag.trim_start_matches('v');

    if latest_version == VERSION {
        println!("Already up to date (v{VERSION}).");
        return Ok(());
    }

    println!("Updating v{VERSION} → v{latest_version}...");

    let tmp_dir = std::env::temp_dir().join("dockswitch-update");
    fs::create_dir_all(&tmp_dir)?;

    let daemon_tmp = tmp_dir.join("dockswitchd");
    let cli_tmp = tmp_dir.join("dockswitch");

    // Download both binaries
    let base_url = format!("https://github.com/{GITHUB_REPO}/releases/download/{tag}");

    println!("Downloading daemon...");
    let status = Command::new("curl")
        .args([
            "-fSL",
            "--progress-bar",
            "-o",
            daemon_tmp.to_str().unwrap(),
            &format!("{base_url}/dockswitchd-macos-universal"),
        ])
        .status()?;
    if !status.success() {
        return Err("Failed to download daemon binary.".into());
    }

    println!("Downloading CLI...");
    let status = Command::new("curl")
        .args([
            "-fSL",
            "--progress-bar",
            "-o",
            cli_tmp.to_str().unwrap(),
            &format!("{base_url}/dockswitch-macos-universal"),
        ])
        .status()?;
    if !status.success() {
        return Err("Failed to download CLI binary.".into());
    }

    // Stop daemon if running
    let was_running = is_daemon_loaded();
    if was_running {
        println!("Stopping daemon...");
        stop::run()?;
    }

    // Replace binaries (atomic rename from same filesystem won't work cross-device,
    // so copy then remove temp files)
    let daemon_dest = daemon_binary_path();
    let cli_dest = cli_binary_path();

    fs::copy(&daemon_tmp, &daemon_dest)?;
    fs::copy(&cli_tmp, &cli_dest)?;

    // chmod +x
    Command::new("chmod")
        .args(["+x", daemon_dest.to_str().unwrap()])
        .status()?;
    Command::new("chmod")
        .args(["+x", cli_dest.to_str().unwrap()])
        .status()?;

    // Clean up temp files
    let _ = fs::remove_dir_all(&tmp_dir);

    // Restart daemon if it was running
    if was_running {
        println!("Restarting daemon...");
        start::run()?;
    }

    println!("Updated to v{latest_version}.");

    Ok(())
}
