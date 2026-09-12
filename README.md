# ARTEMIS on WSL2

A practical setup guide for running Google's [ARTEMIS](https://github.com/google/artemis) with an Android Emulator from Ubuntu on WSL2.

This repository records a working setup tested with:

- Windows + WSL2
- Ubuntu 26.04 LTS
- QEMU 10.2.1
- KVM exposed through `/dev/kvm`
- Android Emulator 37.1.11
- Android SDK Platform-Tools 37.0.1
- Android 14 (API 34), Google APIs, `x86_64`
- Pixel 8 AVD

The goal is not to mirror the upstream ARTEMIS repository. It is a companion setup record for getting the Android emulator side working reliably in a WSL2 environment.

## What was verified

The important checks all passed:

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
```

The final emulator booted into Android and was usable from the local ARTEMIS workflow.

## Quick setup

### 1. Install QEMU/KVM support

On newer Ubuntu releases, `qemu-kvm` may be presented as a virtual package rather than a package you can install directly. Use an explicit provider instead:

```bash
sudo apt update
sudo apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients
sudo adduser $USER kvm
```

Then start a new WSL session so the group membership is refreshed.

Verify:

```bash
groups
ls -l /dev/kvm
qemu-system-x86_64 --version
```

### 2. Install the Android command-line tools

Create the SDK directory and configure the environment:

```bash
mkdir -p "$HOME/Android/Sdk"

cat >> ~/.bashrc <<'EOF'
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
EOF

source ~/.bashrc
```

Download the Linux command-line tools from the official Android developer site:

<https://developer.android.com/tools>

Extract them so the final layout is:

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

The `sdkmanager` command may print a deprecation warning in current Android tooling. That warning does not mean the package installation failed.

Verify:

```bash
sdkmanager --list_installed | grep -E 'emulator|platform-tools|system-images;android-34'
```

### 4. Verify KVM acceleration before creating the AVD

```bash
emulator -accel-check
```

A working Linux setup should report that KVM is installed and usable.

### 5. Create the Pixel 8 AVD

```bash
avdmanager create avd \
  -n Pixel_8_API_34 \
  -k "system-images;android-34;google_apis;x86_64"
```

You can check the result with:

```bash
avdmanager list avd
```

### 6. Start the emulator

```bash
emulator -avd Pixel_8_API_34
```

Then, from another terminal:

```bash
adb devices
```

You should see the emulator listed as a connected device.

## Troubleshooting

### `qemu-kvm` has no installation candidate

On this Ubuntu setup, `apt` reported that `qemu-kvm` was a virtual package provided by `qemu-system-x86` (or an HWE variant). Installing an explicit provider resolved it:

```bash
sudo apt install -y qemu-system-x86
```

### KVM permission error

If this appears:

```text
This user doesn't have permissions to use KVM (/dev/kvm).
```

make sure the user belongs to `kvm`:

```bash
sudo adduser $USER kvm
groups
```

A fully refreshed WSL session is required before the new group membership appears in `groups`.

Then retest:

```bash
emulator -accel-check
```

### `devices.xml` error while creating the AVD

On the tested installation, the Android 14 system image did not contain the expected `devices.xml` file, and `avdmanager` reported:

```text
Could not load devices from .../system-images/android-34/google_apis/x86_64/devices.xml
```

The Pixel 8 definition itself was still available, and creating the AVD without the explicit `--device` argument worked:

```bash
avdmanager create avd \
  -n Pixel_8_API_34 \
  -k "system-images;android-34;google_apis;x86_64"
```

If a partially created AVD is left behind, delete it and recreate it:

```bash
avdmanager delete avd -n Pixel_8_API_34
```

### Emulator starts but shows snapshot warnings

Messages about a missing `default_boot` snapshot are not necessarily fatal. A fresh AVD can boot without a usable snapshot. The important check is whether Android eventually reaches the UI and ADB sees the device.

## Detailed notes

See [`docs/wsl2-android-emulator.md`](docs/wsl2-android-emulator.md) for the complete tested sequence, verification commands, and the reasoning behind the setup choices.

## Upstream project

ARTEMIS is developed by Google:

<https://github.com/google/artemis>

This repository is an independent setup/notes repository and is not an official Google project.

## Security notes

Do not commit any of the following to this repository:

- API keys or access tokens
- Android signing keys
- local shell history
- `.env` files containing secrets
- emulator state, userdata images, or large SDK artifacts
- machine-specific credentials

The commands in this repository use `$HOME` rather than a personal local path so they can be reused on another machine.
