# Changelog

## [0.4.0](https://github.com/ljredmond9/DockSwitch/compare/v0.3.0...v0.4.0) (2026-02-21)


### Features

* add CLI, rename daemon to dockswitchd ([4b1a737](https://github.com/ljredmond9/DockSwitch/commit/4b1a737af43501d847e8870978819f05063a4ca4))

## [0.3.0](https://github.com/ljredmond9/DockSwitch/compare/v0.2.4...v0.3.0) (2026-02-21)


### Features

* replace blueutil with native IOBluetooth framework ([7e5fe6a](https://github.com/ljredmond9/DockSwitch/commit/7e5fe6a218e3d4578d89b16fcb0f43bd08717905))


### Bug Fixes

* trigger Bluetooth permission prompt on first launch ([defff25](https://github.com/ljredmond9/DockSwitch/commit/defff253ed44b750dc43c994e57d147e6d4f3974))

## [0.2.4](https://github.com/ljredmond9/DockSwitch/compare/v0.2.3...v0.2.4) (2026-02-20)


### Bug Fixes

* Bluetooth entitlement, duplicate events, pairing reliability ([acfe104](https://github.com/ljredmond9/DockSwitch/commit/acfe104a60f1b0363f18cf39b38d392851b2c96a))
* read user input from /dev/tty in installer ([667f55b](https://github.com/ljredmond9/DockSwitch/commit/667f55b92d80b52557c3891d0da597651cef8330))
* wrap installer in main() for curl-pipe-bash compatibility ([f3a3a51](https://github.com/ljredmond9/DockSwitch/commit/f3a3a51e60326f315a3164374914fdfeacfc3b08))

## [0.2.3](https://github.com/ljredmond9/DockSwitch/compare/v0.2.2...v0.2.3) (2026-02-20)


### Bug Fixes

* add x-release-please-version marker so version gets bumped ([34efe0f](https://github.com/ljredmond9/DockSwitch/commit/34efe0f5f1daec63271d1d5e939b1d5821d0140e))

## [0.2.2](https://github.com/ljredmond9/DockSwitch/compare/v0.2.1...v0.2.2) (2026-02-20)


### Bug Fixes

* use swift-actions/setup-swift for consistent Swift 6.2 in CI ([ec34374](https://github.com/ljredmond9/DockSwitch/commit/ec34374d2dd282c9fc8dcbb2304f020da08bbe3d))

## [0.2.1](https://github.com/ljredmond9/DockSwitch/compare/v0.2.0...v0.2.1) (2026-02-20)


### Bug Fixes

* move build job into release-please workflow ([378e2b2](https://github.com/ljredmond9/DockSwitch/commit/378e2b233d077168402e0f270a6fbbfb393266eb))

## [0.2.0](https://github.com/ljredmond9/DockSwitch/compare/v0.1.0...v0.2.0) (2026-02-20)


### Features

* initial release with automated build and install pipeline ([5b6d93e](https://github.com/ljredmond9/DockSwitch/commit/5b6d93ebb007b9a1b01e4d319cc3d1bb52590a5b))


### Bug Fixes

* rename release-please config to match expected default filename ([9ffe34e](https://github.com/ljredmond9/DockSwitch/commit/9ffe34e8fef97efa34314861f07bc0473be1cd9d))
