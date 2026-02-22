use anyhow::Result;

pub fn run() -> Result<()> {
    // Stop (ignore if not running)
    if super::is_daemon_loaded() {
        super::stop::run()?;
    }

    super::start::run()?;

    Ok(())
}
