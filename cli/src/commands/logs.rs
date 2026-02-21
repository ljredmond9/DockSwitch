use super::log_file_path;
use std::os::unix::process::CommandExt;
use std::process::Command;

pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    let log_path = log_file_path();

    if !log_path.exists() {
        return Err(format!("Log file not found at {}", log_path.display()).into());
    }

    // exec replaces the current process with tail -f
    let err = Command::new("tail")
        .args(["-f", log_path.to_str().unwrap()])
        .exec();

    // exec only returns on error
    Err(format!("Failed to exec tail: {err}").into())
}
