# Running ARTEMIS with the WSL2 emulator

This repository documents the Android side of an ARTEMIS setup. The actual ARTEMIS application remains the upstream Google project.

## 1. Keep the upstream project separate

Clone Google's repository in a location of your choice:

```bash
git clone https://github.com/google/artemis.git
cd artemis
```

Use the upstream project's own setup instructions for its Python environment and dependencies. Do not copy the upstream source tree into this documentation repository.

## 2. Start the Android emulator

From WSL2, make sure the Android emulator is running:

```bash
emulator -avd Pixel_8_API_34
```

Or use the helper in this repository:

```bash
bash scripts/start-emulator.sh
```

The helper defaults to `Pixel_8_API_34`. To use another AVD:

```bash
ARTEMIS_AVD_NAME=My_AVD bash scripts/start-emulator.sh
```

## 3. Verify ADB

In another WSL terminal:

```bash
adb devices
```

The emulator should appear as a connected device. If ADB reports `offline`, allow the emulator to finish booting and run the command again.

## 4. Verify the complete Android environment

Run the repository's diagnostic script:

```bash
bash scripts/verify-wsl2.sh
```

It checks WSL, `/dev/kvm`, KVM group membership, Android command-line tools, emulator acceleration, AVDs, and connected ADB devices.

## 5. Start ARTEMIS

Follow the upstream ARTEMIS README for the current startup command. At the time this guide was written, the upstream quick start uses the project startup script on Linux/macOS:

```bash
./start.sh
```

The upstream project provides a local web console and also supports direct CLI and MCP-based workflows. Keep those commands tied to the exact upstream revision you are using because the ARTEMIS interface evolves independently of this repository.

## 6. MCP clients

ARTEMIS provides an MCP server for AI coding assistants. Configure the client according to the upstream documentation rather than hard-coding one machine's paths in this repository.

Common clients documented upstream include Codex, Antigravity, Claude Code, and Windsurf.

## 7. Practical separation of responsibilities

Think of the setup as three separate layers:

```text
Windows / WSL2
    |
    +-- Android Emulator + KVM
    |       |
    |       +-- Pixel_8_API_34
    |       +-- ADB
    |
    +-- ARTEMIS checkout
            |
            +-- Web console / CLI
            +-- MCP server
            +-- AI assistant integration
```

The Android emulator does not need to live inside the ARTEMIS source directory, and the ARTEMIS Python environment does not need to manage the Android SDK installation.

## References

- Upstream ARTEMIS: https://github.com/google/artemis
- Android developer tools: https://developer.android.com/tools
