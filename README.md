# EnvGym - Multi-Language Development Environment Platform

EnvGym is an integrated development environment platform that supports multiple programming languages and development tools, designed to provide a consistent development experience for AI-assisted coding and research. The platform operates through a three-stage pipeline: **EnvBoot**, **EnvGym**, and **EnvBench**.

![EnvGym Overview](https://github.com/user-attachments/assets/6664c32c-5e32-4712-b5f9-71b37e457be3)

## System Architecture

EnvGym operates through three distinct stages:

### 1. EnvBoot - Hardware Resource Management
- **Hardware Requirement Analysis**: Automatically analyzes codebase requirements
- **Resource Reservation**: Allocates appropriate hardware resources (CPU, GPU, RAM, OS)
- **SSH Access Provisioning**: Provides secure access to allocated resources
- **Environment Initialization**: Sets up base development environment

### 2. EnvGym - Environment Building & Iteration
- **Repository Analysis**: Scans and analyzes target repositories
- **Dockerfile Generation**: Creates and modifies environment configurations
- **Hardware-Aware Planning**: Optimizes configurations for available hardware
- **Iterative Improvement**: Continuous refinement through build-test cycles
- **Status Tracking**: Monitors and reports environment setup progress

### 3. EnvBench - Benchmarking & Validation
- **Environment Testing**: Comprehensive testing of built environments
- **Performance Benchmarking**: Evaluates environment performance and compatibility
- **Dependency Validation**: Ensures all required dependencies are properly installed
- **Report Generation**: Detailed reports on environment quality and readiness

## Features

- 🤖 **AI-Powered Agents**: Advanced AI agents for code generation, analysis, and automation
- 🐍 **Python Ecosystem**: Complete Python development environment with agent-squad integration
- ☕ **Java Support**: Enterprise-level development environment with Maven/Gradle support
- 🦀 **Rust Integration**: System programming and high-performance applications
- 🐹 **Go Development**: Cloud-native and microservices development
- 🔧 **Multiple Tools**: Integrated development tools including Aider and more
- 🐳 **Containerized**: Docker support for easy deployment and environment isolation
- 📊 **Research-Ready**: Pre-configured with multiple research repositories and datasets
- 🔄 **Iterative Optimization**: Continuous environment improvement through automated testing
- 📈 **Performance Monitoring**: Real-time performance tracking and optimization

## Quick Start

### Prerequisites

- **Conda/Miniconda**: For Python environment management
- **Git**: For repository management
- **Docker**: For containerized deployment and environment testing
- **SSH Access**: For remote development environments

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
- Initialize the EnvGym system

3. **Activate the environment and start using**:

```bash
conda activate envgym

# Test the setup
cd data/exli
python ../../Agent/agent.py
```

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
│   ├── alibaba_fastjson2/   # Java JSON processing library
│   ├── exli/               # Example research repository
│   └── ...                 # Other research repositories
├── requirements.txt         # Python dependencies
├── setup.sh                 # One-click setup script
└── README.md               # This file
```

## Usage Examples

### Environment Building with EnvGym

```bash
# Navigate to a repository
cd data/alibaba_fastjson2

# Run environment analysis and building
python ../../Agent/agent.py --mode=envgym

# This will:
# 1. Analyze the repository structure
# 2. Generate appropriate Dockerfile
# 3. Build and test the environment
# 4. Provide benchmarking results
```

### Running AI Agents

```bash
# Activate the environment
conda activate envgym

# Run the main agent
cd data/exli
python ../../Agent/agent.py
```

### Docker Environment Testing

```bash
# Test Dockerfile configurations
cd data/alibaba_fastjson2
./simple_dockerfile_test.sh

# This will compare different Dockerfile configurations
# and provide detailed analysis reports
```

### Python Development

```bash
cd python
pip install -e .
python -m pytest tests/
```

## Research Integration

EnvGym is designed to support various research workflows:

1. **Automated Environment Setup**: Automatically configure development environments for research projects
2. **Multi-Language Support**: Work seamlessly across different programming languages
3. **Performance Benchmarking**: Evaluate and optimize environment performance
4. **Dependency Management**: Automated dependency resolution and conflict handling
5. **Containerized Development**: Isolated development environments for reproducible research

### Supported Research Areas

- **Machine Learning**: TensorFlow, PyTorch, scikit-learn environments
- **Data Science**: Jupyter, pandas, numpy, matplotlib setups
- **System Programming**: Rust, C++, Go development environments
- **Web Development**: Node.js, Python web frameworks
- **Mobile Development**: React Native, Flutter environments

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
- **Environment Testing**: Automated environment validation and benchmarking

## Troubleshooting

### Common Issues

1. **Conda environment creation fails**:
   - Ensure conda is properly installed and in your PATH
   - Try updating conda: `conda update conda`

2. **API key errors**:
   - Verify your Forge API key is correctly set in the `.env` file
   - Check that the key has sufficient permissions

3. **Docker build failures**:
   - Ensure Docker is running and accessible
   - Check available disk space for image building
   - Verify network connectivity for pulling base images

4. **Permission errors on scripts**:
   - Make scripts executable: `chmod +x setup.sh`
   - Ensure you have write permissions in the project directory

5. **Environment testing failures**:
   - Check Docker daemon status
   - Verify base image availability
   - Review Dockerfile syntax and dependencies

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

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
- Docker and containerization technologies
- The research community for providing diverse codebases for testing and validation
