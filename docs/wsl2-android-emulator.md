# ARTEMIS + Android Emulator on WSL2

This document records the setup path used to get a Linux Android Emulator running under WSL2 for an ARTEMIS workflow.

It focuses on the emulator environment rather than reproducing Google's ARTEMIS source tree.

## Environment

The working environment was:

```text
Host:        Windows
Virtualized: WSL2
Linux:       Ubuntu 26.04 LTS (resolute)
Architecture: x86_64
QEMU:        10.2.1
Emulator:    37.1.11
Platform tools: 37.0.1
Android:     14 / API 34
Image:       Google APIs x86_64
AVD:         Pixel_8_API_34
```

## 1. Confirm WSL2 and KVM

Check the environment:

```bash
uname -a
lsb_release -a
systemd-detect-virt
ls -l /dev/kvm
```

Expected characteristics are a Microsoft WSL2 kernel, Ubuntu, `wsl` from `systemd-detect-virt`, and a `/dev/kvm` character device.

A useful permission check is:

```bash
ls -l /dev/kvm
```

The device should be owned by the `kvm` group and have group read/write permissions.

## 2. Install QEMU/KVM packages

The original setup instructions used:

```bash
sudo apt-get install -y qemu-kvm libvirt-daemon-system
```

On the tested Ubuntu release, `qemu-kvm` was a virtual package and `apt` required an explicit provider. The working command was:

```bash
sudo apt update
sudo apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients
sudo adduser $USER kvm
```

After adding the user to `kvm`, restart the WSL session. Merely adding the group does not change the supplementary groups of an already-running shell.

Verify:

```bash
groups
qemu-system-x86_64 --version
ls -l /dev/kvm
```

## 3. Configure the Android SDK

The SDK was installed under the user's home directory:

```bash
mkdir -p "$HOME/Android/Sdk"
```

The following environment variables were added to `~/.bashrc`:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
```

Reload the shell configuration:

```bash
source ~/.bashrc
```

Check:

```bash
echo "$ANDROID_HOME"
```

## 4. Install command-line tools

Download the current Linux command-line tools from Android Developers:

<https://developer.android.com/tools>

The extracted directory should have this structure:

```text
$ANDROID_HOME/
└── cmdline-tools/
    └── latest/
        └── bin/
            ├── avdmanager
            └── sdkmanager
```

Then verify:

```bash
which sdkmanager
which avdmanager
```

## 5. Install the emulator and Android 14 image

The tested image was:

```text
system-images;android-34;google_apis;x86_64
```

Install the required components:

```bash
sdkmanager --install \
  "emulator" \
  "platform-tools" \
  "system-images;android-34;google_apis;x86_64"
```

Verify:

```bash
sdkmanager --list_installed | grep -E 'emulator|platform-tools|system-images;android-34'
```

Current Android tooling may print a message saying that `sdkmanager` is deprecated in favor of the Android CLI. That is a tooling warning; the installation can still complete successfully.

## 6. Test KVM through the Android Emulator

Before creating an AVD, test the emulator's acceleration path:

```bash
emulator -accel-check
```

The successful result used in this setup was:

```text
KVM (version 12) is installed and usable.
```

The exact KVM version can vary. The important part is that KVM is reported as usable.

## 7. Create the AVD

The initial command included an explicit Pixel 8 device:

```bash
avdmanager create avd \
  -n Pixel_8_API_34 \
  -k "system-images;android-34;google_apis;x86_64" \
  --device "pixel_8"
```

On the tested setup, `avdmanager` complained about a missing `devices.xml` inside the system-image directory. The Pixel 8 device definition was nevertheless present in the device catalogue.

After removing the partially created AVD:

```bash
avdmanager delete avd -n Pixel_8_API_34
```

the AVD was successfully created without explicitly selecting the device profile:

```bash
avdmanager create avd \
  -n Pixel_8_API_34 \
  -k "system-images;android-34;google_apis;x86_64"
```

Check it:

```bash
avdmanager list avd
```

Expected characteristics:

```text
Name: Pixel_8_API_34
Target: Google APIs
Based on: Android 14.0
Tag/ABI: google_apis/x86_64
```

## 8. Boot the emulator

Start it normally first:

```bash
emulator -avd Pixel_8_API_34
```

The first boot may take longer than subsequent boots.

The tested emulator successfully reached the Android UI. Snapshot-related warnings such as failure to load `default_boot` were observed during startup but did not prevent a successful boot.

## 9. Verify ADB

With the emulator running, open another WSL terminal and run:

```bash
adb devices
```

The running emulator should appear as a device. This is the final practical check that Android tooling can communicate with the emulator.

## 10. ARTEMIS workflow

Once the emulator is booted and visible to ADB, it can serve as the Android target for the ARTEMIS workflow. The exact ARTEMIS commands/configuration should be taken from the version of the upstream project being used:

<https://github.com/google/artemis>

Keep the ARTEMIS source checkout, Python environment, and any project-specific configuration separate from the Android SDK and emulator state.

## Troubleshooting summary

| Symptom | Cause | Fix |
| --- | --- | --- |
| `qemu-kvm` has no installation candidate | `qemu-kvm` is exposed as a virtual package | Install `qemu-system-x86` explicitly |
| Emulator says user cannot use KVM | Current shell has not picked up `kvm` membership | Add user to `kvm`, then restart WSL |
| `/dev/kvm` exists but acceleration fails | Permission/group issue | Check `groups` and `/dev/kvm` ownership |
| `devices.xml` error during AVD creation | Missing metadata in the system-image directory | Remove partial AVD and create without `--device` |
| `default_boot` snapshot warning | No usable boot snapshot | Allow a fresh boot; verify Android UI and ADB |
| `emulator` not found | SDK emulator path is missing | Add `$ANDROID_HOME/emulator` to `PATH` |

## Reproducibility notes

Avoid hard-coding a personal home directory in scripts or documentation. Prefer:

```bash
$HOME/Android/Sdk
```

Do not commit the SDK directory, AVD directory, emulator userdata, or generated logs containing local information.

This document describes one verified setup. Android Emulator, SDK command-line tools, Ubuntu packages, and ARTEMIS itself evolve independently, so package versions and exact warnings may differ on a future installation.
