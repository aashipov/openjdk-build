# Windows Instructions

## Requirements

Windows Server 2012+
cygwin with bash git autoconf make cmake zip unzip cpio mc curl
Visual Studio 2022
Bootstrap JDK as `${HOME}/dev/tools/openjdkXXX`

## Installation & Setup

Download installer as unprivileged user:

```sh
curl -L "https://aka.ms/vs/17/release/vs_BuildTools.exe" -o vs_BuildTools_2022.exe && chmod +x vs_BuildTools_2022.exe
```

As administrator:

- launch `vs_BuildTools_2022.exe`
- install `Desktop development with C++`, `Spectre-mitigated libs (Latest)`
- follow [OpenJ9 configuration advice](https://github.com/eclipse-openj9/openj9/blob/master/doc/build-instructions/Build_Instructions_V25.md#windows)
