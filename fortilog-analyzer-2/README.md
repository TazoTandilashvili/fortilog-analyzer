# FortiLog Analyzer

FortiLog Analyzer is a powerful tool designed to process and analyze logs from FortiGate devices. This project utilizes Vector for log ingestion and ClickHouse for efficient storage and querying of log data.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Documentation](#documentation)
- [License](#license)

## Features

- High-throughput log processing using Vector.
- Efficient log storage and querying with ClickHouse.
- Sample queries provided for common log analysis tasks.

## Installation

To set up the FortiLog Analyzer, follow these steps:

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/fortilog-analyzer.git
   cd fortilog-analyzer
   ```

2. Run the setup scripts to install Vector and ClickHouse:
   ```
   ./src/scripts/setup-vector.sh
   ./src/scripts/setup-clickhouse.sh
   ```

## Configuration

Configuration files for Vector and ClickHouse are located in the `src/config` directory. 

- **Vector Configuration**: Modify `vector.toml` to adjust source definitions, transformations, and sink configurations.
- **ClickHouse Configuration**: Edit `clickhouse.yaml` for user management and database settings.

## Usage

After installation and configuration, you can start processing logs. Refer to the `docs/USAGE.md` for examples and best practices on querying the ClickHouse database.

## Documentation

For detailed documentation, please refer to the following files:

- [SETUP.md](docs/SETUP.md): Instructions for setting up the FortiLog Analyzer.
- [VECTOR_CONFIG.md](docs/VECTOR_CONFIG.md): Configuration options for Vector.
- [CLICKHOUSE_CONFIG.md](docs/CLICKHOUSE_CONFIG.md): Configuration settings for ClickHouse.
- [USAGE.md](docs/USAGE.md): Usage examples for querying the ClickHouse database.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.