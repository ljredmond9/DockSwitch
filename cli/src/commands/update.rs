use super::*;
use anyhow::{anyhow, bail, Result};
use std::fs;
use std::path::Path;
use std::process::Command;

/// Extract the tag name from a GitHub releases API JSON response body.
/// Returns `None` if the field is not found.
fn parse_release_tag(body: &str) -> Option<&str> {
    body.split("\"tag_name\"")
        .nth(1)
        .and_then(|s| s.split('"').nth(1))
}

fn download_release_binary(name: &str, dest: &Path, tag: &str) -> Result<()> {
    let url = format!("https://github.com/{GITHUB_REPO}/releases/download/{tag}/{name}");

    println!("Downloading {name}...");

    let status = Command::new("curl")
        .args(["-fSL", "--progress-bar", "-o", dest.to_str().unwrap(), &url])
        .status()?;

    if status.success() {
        Ok(())
    } else {
        bail!("Failed to download {name}.");
    }
}

pub fn run() -> Result<()> {
    println!("Checking for updates...");

    // Get latest release tag from GitHub API
    let output = Command::new("curl")
        .args([
            "-fsSL",
            &format!("https://api.github.com/repos/{GITHUB_REPO}/releases/latest"),
        ])
        .output()?;

    if !output.status.success() {
        bail!("Failed to check GitHub for latest release.");
    }

    let body = String::from_utf8_lossy(&output.stdout);

    let tag = parse_release_tag(&body)
        .ok_or_else(|| anyhow!("Failed to parse release tag from GitHub API response."))?;

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

    download_release_binary("dockswitchd-macos-universal", &daemon_tmp, tag)?;
    download_release_binary("dockswitch-macos-universal", &cli_tmp, tag)?;

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

#[cfg(test)]
mod tests {
    use super::parse_release_tag;

    #[test]
    fn test_parses_tag_from_github_response() {
        let body = r#"{"tag_name":"v1.2.3","name":"Release 1.2.3"}"#;
        assert_eq!(parse_release_tag(body), Some("v1.2.3"));
    }

    #[test]
    fn test_returns_none_for_missing_field() {
        let body = r#"{"name":"no tag here"}"#;
        assert_eq!(parse_release_tag(body), None);
    }

    #[test]
    fn test_returns_none_for_empty_body() {
        assert_eq!(parse_release_tag(""), None);
    }
}
