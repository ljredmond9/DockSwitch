use super::*;
use std::process::Command;

pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    println!("DockSwitch Status");
    println!("─────────────────");

    // CLI version
    println!("CLI version:    {VERSION}");

    // Daemon version
    let daemon_path = daemon_binary_path();
    if daemon_path.exists() {
        let output = Command::new(&daemon_path).arg("--version").output();
        match output {
            Ok(o) if o.status.success() => {
                let ver = String::from_utf8_lossy(&o.stdout);
                println!("Daemon version: {}", ver.trim());
            }
            _ => println!("Daemon version: (unable to query)"),
        }
    } else {
        println!("Daemon binary:  not found");
    }

    // Running state
    let loaded = is_daemon_loaded();
    if loaded {
        println!("Status:         running");

        // Try to get PID
        let output = Command::new("launchctl")
            .args(["list", LAUNCHD_LABEL])
            .output();
        if let Ok(o) = output {
            let text = String::from_utf8_lossy(&o.stdout);
            for line in text.lines() {
                if line.contains("PID") {
                    if let Some(pid) = line.split('=').nth(1).or_else(|| line.split_whitespace().last()) {
                        println!("PID:            {}", pid.trim().trim_matches(';'));
                    }
                }
            }
        }
    } else {
        println!("Status:         stopped");
    }

    // Config summary
    let config_path = config_plist_path();
    if config_path.exists() {
        println!("Config:         {}", config_path.display());
    } else {
        println!("Config:         not found");
    }

    // Log file
    let log_path = log_file_path();
    if log_path.exists() {
        println!("Log file:       {}", log_path.display());
    } else {
        println!("Log file:       not found");
    }

    Ok(())
}
