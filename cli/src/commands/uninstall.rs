use super::*;
use std::fs;
use std::io::{self, Write};

pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    print!("Uninstall DockSwitch? This will remove all binaries, config, and logs. [y/N] ");
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    if !input.trim().eq_ignore_ascii_case("y") {
        println!("Aborted.");
        return Ok(());
    }

    // Stop daemon
    if is_daemon_loaded() {
        println!("Stopping daemon...");
        stop::run()?;
    }

    // Remove files
    let files = [
        daemon_binary_path(),
        cli_binary_path(),
        launchd_plist_path(),
        config_plist_path(),
        log_file_path(),
    ];

    for path in &files {
        if path.exists() {
            fs::remove_file(path)?;
            println!("Removed {}", path.display());
        }
    }

    println!("\nDockSwitch uninstalled.");

    Ok(())
}
