pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    // Stop (ignore if not running)
    if super::is_daemon_loaded() {
        super::stop::run()?;
    }

    super::start::run()?;

    Ok(())
}
