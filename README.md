# EnvGym 🤖🏋️🔧

<p align="center">
<img align="center" src="assets/image.png" width="498" />
</p>

<p align="center">
      <a href="https://github.com/EaminC/EnvGym/actions" alt="Build status">
    <img src="https://img.shields.io/github/actions/workflow/status/EaminC/EnvGym/build.yml?branch=main" />
  </a>
    <a href="https://semver.org" alt="Version">
        <img src="https://img.shields.io/github/v/release/EaminC/EnvGym" />
    </a>
    <a href="https://google.github.io/styleguide/javaguide.html" alt="Code style">
        <img src="https://img.shields.io/badge/style-Google-blue" />
    </a>
    <a href="https://dl.acm.org/doi/10.1145/3600006.3613140" alt="SOSP 2023">
        <img src="https://img.shields.io/badge/2025-ICLR-8A2BE2" />
    </a>
    <a href="https://opensource.org/licenses/MIT" alt="License">
        <img src="https://img.shields.io/github/license/EaminC/EnvGym" />
    </a>
</p>

A general multi-agent framework for automated environment construction and reproducibility in research software.

---

## 🌐 Overview

**EnvGym** is a general-purpose multi-agent framework designed to automatically construct **executable environments** for reproducing research prototypes from top-tier academic conferences and journals. It leverages **Large Language Model (LLM)** agents to analyze project instructions, resolve dependencies, configure systems, and validate the final setup.

EnvGym aims to provide a scalable, extensible infrastructure to support reproducibility across a wide range of research artifacts.

---

## 🧠 Key Components

### ⚙️ EnvAgent

An LLM-driven agent that performs the following tasks:

- Parses installation guides and configuration files
- Resolves software and system dependencies
- Executes setup steps in a sandboxed environment
- Verifies environment health via structured feedback

### 📝 EnvEval

A fine-grained, rubric-based evaluation framework used to:

- Automatically assess the success of agent executions
- Verify task completion through rule-based and LLM-based validators
- Support human-in-the-loop expert validation

---

## 🚀 Goals

- Automate the end-to-end setup process for research repositories
- Support robust execution, even in the presence of undocumented or broken configurations
- Provide standard evaluation rubrics for benchmarking agent behavior
- Explore fine-tuning, instruction tuning, and reinforcement learning to enhance agent performance on challenging tasks

---

## 📈 Current Progress

- ✅ Proof-of-concept prototype using off-the-shelf LLM agents
- ✅ Successful installation of handcrafted benchmark repositories
- ⚠️ Ongoing challenges with complex, real-world system-level dependencies
- 🔧 Upcoming focus on improving agent reasoning for debugging and recovery

---

## 🧪 Research Focus

We are actively exploring:

- Robust LLM planning workflows under noisy or partial instructions
- Diagnosing environment setup failures and repairing buggy code
- Augmenting existing ReAct-style frameworks for system-level decision making
- Incorporating feedback from human experts and automated grading mechanisms

---

## 📂 Repository Structure (WIP)

---

## 📄 Citation (Coming Soon)

We will release a preprint and BibTeX citation for academic use shortly.

---

## 🤝 Contributing

We welcome contributions! Please open issues, submit pull requests, or contact us for collaboration.

---

## 📬 Contact

- **Yiming Cheng** – [GitHub](https://github.com/EaminC) | eaminchan@uchicago.edu
- **Binrui Huang** – [GitHub](https://github.com/samloveshoneywater) | binruih@uchicago.edu

---

## 📜 License

MIT License. See [LICENSE](./LICENSE.md) for details.
