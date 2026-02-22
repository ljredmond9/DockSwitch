use super::log_file_path;
use anyhow::{anyhow, bail, Result};
use std::os::unix::process::CommandExt;
use std::process::Command;

pub fn run() -> Result<()> {
    let log_path = log_file_path();

    if !log_path.exists() {
        bail!("Log file not found at {}", log_path.display());
    }

    // exec replaces the current process with tail -f
    let err = Command::new("tail")
        .args(["-f", log_path.to_str().unwrap()])
        .exec();

    // exec only returns on error
    Err(anyhow!("Failed to exec tail: {err}"))
}
