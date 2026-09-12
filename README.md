# ARTEMIS on WSL2

A practical setup guide for running Google's [ARTEMIS](https://github.com/google/artemis) with an Android Emulator from Ubuntu on WSL2.

This repository is a companion setup repository. It does **not** mirror or redistribute the upstream ARTEMIS source tree.

## Working environment

This setup was verified with:

- Windows + WSL2
- Ubuntu 26.04 LTS
- x86_64
- QEMU 10.2.1
- KVM exposed through `/dev/kvm`
- Android Emulator 37.1.11
- Android SDK Platform-Tools 37.0.1
- Android 14 (API 34), Google APIs, `x86_64`
- Pixel 8 AVD (`Pixel_8_API_34`)

## What was verified

```text
WSL2                  yes
Ubuntu 26.04 LTS      yes
/dev/kvm              present
KVM permissions       working
QEMU                  installed
Android SDK           installed
Android Emulator      installed
KVM acceleration      usable
Pixel 8 AVD            created
Android emulator      boots successfully
ADB                    detects the running emulator
ARTEMIS workflow      reaches the running Android target
```

## Architecture

The setup is intentionally split into two layers:

```text
Windows
  |
  +-- WSL2 / Ubuntu
  |     |
  |     +-- KVM + QEMU
  |     +-- Android SDK
  |     +-- Android Emulator
  |            |
  |            +-- Pixel_8_API_34
  |            +-- ADB
  |
  +-- ARTEMIS source checkout
         |
         +-- Web UI / CLI
         +-- MCP server
         +-- AI assistant integration
```

The Android SDK and emulator state stay outside the ARTEMIS source tree. This keeps the large, machine-specific emulator files out of Git while allowing the setup itself to be reproduced.

## Quick setup

### 1. Install QEMU/KVM support

On newer Ubuntu releases, `qemu-kvm` may be presented as a virtual package rather than an installable package name. Use an explicit QEMU provider:

```bash
sudo apt update
sudo apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients
sudo adduser $USER kvm
```

Start a new WSL session so the supplementary group is refreshed.

Verify:

```bash
groups
ls -l /dev/kvm
qemu-system-x86_64 --version
```

### 2. Configure the Android SDK

```bash
mkdir -p "$HOME/Android/Sdk"
```

Add the SDK paths to `~/.bashrc`:

```bash
cat >> ~/.bashrc <<'EOF'
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
EOF

source ~/.bashrc
```

Install the current Linux Android command-line tools from the [Android developer tools](https://developer.android.com/tools) page. The final layout should include:

```text
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager
```

### 3. Install the emulator and system image

```bash
sdkmanager --install \
  "emulator" \
  "platform-tools" \
  "system-images;android-34;google_apis;x86_64"
```

Current Android tooling may warn that `sdkmanager` is deprecated in favor of the newer Android CLI. The warning does not itself indicate a failed installation.

Verify:

```bash
sdkmanager --list_installed | grep -E 'emulator|platform-tools|system-images;android-34'
```

### 4. Verify KVM acceleration

Do this before creating the AVD:

```bash
emulator -accel-check
```

The important result is that KVM is reported as installed and usable.

### 5. Create the AVD

```bash
avdmanager create avd \
  -n Pixel_8_API_34 \
  -k "system-images;android-34;google_apis;x86_64"
```

On the tested setup, explicitly passing `--device pixel_8` caused a missing `devices.xml` error even though the Pixel 8 device definition was available. Omitting the device argument worked.

Verify:

```bash
avdmanager list avd
```

### 6. Boot Android

```bash
emulator -avd Pixel_8_API_34
```

Or use the helper in this repository:

```bash
bash scripts/start-emulator.sh
```

The helper uses `Pixel_8_API_34` by default and accepts another AVD through `ARTEMIS_AVD_NAME`.

### 7. Verify ADB

From another WSL terminal:

```bash
adb devices
```

The running emulator should appear as a connected device.

### 8. Verify everything together

Run:

```bash
bash scripts/verify-wsl2.sh
```

This checks WSL, `/dev/kvm`, `kvm` group membership, Android command-line tools, emulator acceleration, configured AVDs, and connected ADB devices.

## Running ARTEMIS

The actual ARTEMIS project is maintained upstream by Google. Clone and run the upstream project separately:

```bash
git clone https://github.com/google/artemis.git
cd artemis
./start.sh
```

Use the upstream repository's current documentation for Python dependencies, model/API configuration, MCP installation, and other ARTEMIS-specific setup. Keeping those instructions tied to the upstream project avoids hard-coding an obsolete ARTEMIS interface into this setup repository.

See [`docs/artemis-runtime.md`](docs/artemis-runtime.md) for the boundary between the Android emulator environment and the ARTEMIS runtime.

## Troubleshooting

### `qemu-kvm` has no installation candidate

`qemu-kvm` may be exposed as a virtual package. Install the explicit provider instead:

```bash
sudo apt install -y qemu-system-x86
```

### KVM permission error

If the emulator reports:

```text
This user doesn't have permissions to use KVM (/dev/kvm).
```

check:

```bash
groups
ls -l /dev/kvm
```

Make sure the current user belongs to `kvm`:

```bash
sudo adduser $USER kvm
```

Then exit the WSL session and open a new one. Adding the group does not change the supplementary groups of an already-running shell.

Retest:

```bash
emulator -accel-check
```

### `devices.xml` error during AVD creation

If `avdmanager` reports a missing `devices.xml` under the Android 34 system-image directory, remove any partially created AVD and recreate it without `--device`:

```bash
avdmanager delete avd -n Pixel_8_API_34
avdmanager create avd \
  -n Pixel_8_API_34 \
  -k "system-images;android-34;google_apis;x86_64"
```

### Snapshot warnings on first boot

A fresh AVD may report that a `default_boot` snapshot could not be loaded. This is not necessarily fatal. Let the emulator perform a fresh boot and verify that Android reaches the UI and that ADB reports the emulator as connected.

## Repository layout

```text
.
├── README.md
├── .gitignore
├── docs/
│   ├── artemis-runtime.md
│   └── wsl2-android-emulator.md
└── scripts/
    ├── start-emulator.sh
    └── verify-wsl2.sh
```

## Security and repository hygiene

Do not commit:

- API keys, access tokens, or `.env` files containing secrets
- Android signing keys
- shell history
- emulator userdata, disk images, or snapshots
- the Android SDK directory
- local logs containing credentials or private data
- machine-specific absolute paths where `$HOME` is sufficient

The `.gitignore` in this repository is intentionally set to exclude common Android, Python, IDE, environment, and runtime artifacts.

## Upstream

Google's ARTEMIS project:

<https://github.com/google/artemis>

This repository is an independent setup and notes project. It is not an official Google repository.
