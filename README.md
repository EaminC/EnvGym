# EnvGym - Multi-Language Development Environment Platform

EnvGym is an integrated development environment platform that supports multiple programming languages and development tools, designed to provide a consistent development experience for AI-assisted coding and research.

![EnvGym Overview](https://github.com/user-attachments/assets/6664c32c-5e32-4712-b5f9-71b37e457be3)

## Features

- 🤖 **AI-Powered Agents**: Advanced AI agents for code generation, analysis, and automation
- 🐍 **Python Ecosystem**: Complete Python development environment with agent-squad integration
- ☕ **Java Support**: Enterprise-level development environment
- 🦀 **Rust Integration**: System programming and high-performance applications
- 🐹 **Go Development**: Cloud-native and microservices development
- 🔧 **Multiple Tools**: Integrated development tools including Aider and more
- 🐳 **Containerized**: Docker support for easy deployment and environment isolation
- 📊 **Research-Ready**: Pre-configured with multiple research repositories and datasets

## Quick Start

### Prerequisites

- **Conda/Miniconda**: For Python environment management
- **Git**: For repository management
- **Docker** (optional): For containerized deployment

### One-Click Setup

1. **Clone the repository**:

```bash
git clone https://github.com/EaminC/EnvGym.git
cd EnvGym
```

2. **Run the setup script**:

```bash
chmod +x setup.sh
./setup.sh
```

The setup script will automatically:

- Create a conda environment with Python 3.10
- Install all Python dependencies
- Create `.env` file and prompt for your Forge API key (only manual input required!)
- Download research repositories

3. **Activate the environment and start using**:

```bash
conda activate envgym

# Test the setup
cd data/exli
python ../../Agent/agent.py
```

That's it! The setup script handles everything automatically except your Forge API key input.

### Manual Installation

If you prefer manual setup:

#### Python Environment

```bash
conda create -n envgym python=3.10
conda activate envgym
pip install -r requirements.txt
```

#### Environment Variables

```bash
cp .env.example .env
# You only need to edit the .env file to add your Forge API key:
# FORGE_API_KEY=your-actual-forge-api-key
```

#### Download Research Data

```bash
cd data
bash down_one.sh
```

## Project Structure

```
EnvGym/
├── Agent/                    # AI Agent System
│   ├── agent/               # Core agent implementations
│   ├── prompt/              # Prompt engineering modules
│   └── tool/                # Development tools
│       ├── aider/           # AI-assisted coding tool
│       ├── codex/           # Code generation and analysis
│       ├── compat/          # Multi-language compatibility
│       ├── dockerrun/       # Docker integration
│       ├── history_manager/ # Development history tracking
│       ├── initial/         # Project initialization
│       └── update/          # Update management
├── python/                  # Python packages and libraries
│   └── src/agent_squad/     # Multi-agent orchestration
├── data/                    # Research repositories and datasets
├── requirements.txt         # Python dependencies
├── setup.sh                 # One-click setup script
└── README.md               # This file
```

## Configuration

### API Keys

The setup script will automatically create the `.env` file and prompt you for your Forge API key. The configuration format is:

```bash
# Forge API Configuration
FORGE_API_KEY=your-forge-api-key-here
```

### Development Tools

The platform includes several integrated development tools:

- **Aider**: AI-powered pair programming assistant
- **Agent Squad**: Multi-agent system orchestration
- **Compatibility Tools**: Support for multiple programming languages
- **Docker Integration**: Containerized development environments

## Usage Examples

### Running AI Agents

```bash
# Activate the environment
conda activate envgym

# Run the main agent
cd data/exli
python ../../Agent/agent.py
```

### Python Development

```bash
cd python
pip install -e .
python -m pytest tests/
```

### Working with Research Repositories

The `data/` directory contains multiple research repositories that are automatically cloned:

- **RelTR**: Relation Transformer for scene graph generation
- **FEMU**: FPGA-based NVMe SSD emulator
- **TabPFN**: Tabular data prediction with transformers
- **RSNN**: Recurrent spiking neural networks
- **And many more...**

Each repository can be used for experimentation and research.

## Research Integration

EnvGym is designed to support various research workflows:

1. **Code Analysis**: Analyze existing codebases with AI assistance
2. **Automated Testing**: Generate and run tests across multiple languages
3. **Performance Optimization**: Identify and optimize performance bottlenecks
4. **Documentation Generation**: Automatically generate documentation
5. **Multi-Language Support**: Work seamlessly across different programming languages

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Troubleshooting

### Common Issues

1. **Conda environment creation fails**:

   - Ensure conda is properly installed and in your PATH
   - Try updating conda: `conda update conda`

2. **API key errors**:

   - Verify your Forge API key is correctly set in the `.env` file
   - Check that the key has sufficient permissions

3. **Permission errors on scripts**:
   - Make scripts executable: `chmod +x setup.sh`
   - Ensure you have write permissions in the project directory

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use EnvGym in your research, please cite:

```bibtex
@software{envgym2024,
  title={EnvGym: Multi-Language Development Environment Platform},
  author={EnvGym Contributors},
  year={2024},
  url={https://github.com/EaminC/EnvGym}
}
```

## Support

- 📧 **Issues**: Please report bugs and feature requests via [GitHub Issues](https://github.com/EaminC/EnvGym/issues)
- 💬 **Discussions**: Join our community discussions for questions and support
- 📚 **Documentation**: Check our [documentation](docs/) for detailed guides

## Acknowledgments

This project builds upon and integrates several open-source tools and research projects. We thank the contributors to:

- Aider and other AI-assisted coding tools
- The various research repositories included in our dataset
- The open-source community for their invaluable contributions
