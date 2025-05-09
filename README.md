<div align="center">
    <img src="textures/base/pack/logo.png" width="32%">
    <h1>Luanti (formerly Minetest)</h1>
    <img src="https://github.com/luanti-org/luanti/workflows/build/badge.svg" alt="Build Status">
    <a href="https://hosted.weblate.org/engage/minetest/?utm_source=widget"><img src="https://hosted.weblate.org/widgets/minetest/-/svg-badge.svg" alt="Translation status"></a>
    <a href="https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html"><img src="https://img.shields.io/badge/license-LGPLv2.1%2B-blue.svg" alt="License"></a>
</div>
<br>

# Sandboxy

A free open-source voxel game engine with easy modding capabilities.

## About

Sandboxy is an open source voxel game engine. Build anything you can imagine with simple building blocks in a vast world. Create your own games using the powerful Lua API. Join multiplayer servers or host your own server to play with friends.

## Installing

### Windows

- Download the latest Windows build from https://www.sandboxy.org/downloads
- Extract the downloaded archive
- Run the sandboxy.exe executable

### Linux

#### Debian and Ubuntu

```
sudo apt install sandboxy
```

#### Fedora

```
sudo dnf install sandboxy
```

#### Other distributions

Check your distribution's package manager or build from source.

## Building from Source

See [Compiling](doc/compiling/README.md) for detailed instructions.

## Configuration

- Default location: `user/sandboxy.conf`
- This file is created by closing Sandboxy for the first time
- A specific file can be specified on the command line: `--config <path-to-file>`

### Default Paths

| Platform | Binary | User Data | Share |
|----------|---------|------------|--------|
| Linux    | /usr/bin | ~/.local/share/sandboxy | /usr/share/sandboxy |
| macOS    | sandboxy.app/Contents/MacOS | ~/Library/Application Support/sandboxy | sandboxy.app/Contents/Resources |
| Windows  | sandboxy.exe | %APPDATA%/sandboxy | . |

## License

LGPL-2.1-or-later, see [LICENSE.txt](LICENSE.txt) for details.

## Links

- [Website](https://www.sandboxy.org)
- [Documentation](https://docs.sandboxy.org)
- [GitHub](https://github.com/sandboxyorg/sandboxy)
- [Forum](https://forum.sandboxy.org)
