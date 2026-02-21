mod commands;

use clap::Parser;
use commands::{Cli, Commands};

fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Commands::Start => commands::start::run(),
        Commands::Stop => commands::stop::run(),
        Commands::Restart => commands::restart::run(),
        Commands::Status => commands::status::run(),
        Commands::Logs => commands::logs::run(),
        Commands::Update => commands::update::run(),
        Commands::Uninstall => commands::uninstall::run(),
    };

    if let Err(e) = result {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}
