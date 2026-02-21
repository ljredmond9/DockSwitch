# Changelog

## [0.6.0](https://github.com/ljredmond9/DockSwitch/compare/v0.5.0...v0.6.0) (2026-02-21)


### Features

* sign release binaries with Developer ID certificate ([#22](https://github.com/ljredmond9/DockSwitch/issues/22)) ([a5e533d](https://github.com/ljredmond9/DockSwitch/commit/a5e533d24be960910f25a477da0d787cf6f749fc))

## [0.5.0](https://github.com/ljredmond9/DockSwitch/compare/v0.4.2...v0.5.0) (2026-02-21)


### Features

* generalize naming ([#19](https://github.com/ljredmond9/DockSwitch/issues/19)) ([16e0a58](https://github.com/ljredmond9/DockSwitch/commit/16e0a5807e1b822eef224bef641f73af930c0c17))

## [0.4.2](https://github.com/ljredmond9/DockSwitch/compare/v0.4.1...v0.4.2) (2026-02-21)


### Bug Fixes

* avoid fromJSON eval when no release PR exists ([#17](https://github.com/ljredmond9/DockSwitch/issues/17)) ([374b16f](https://github.com/ljredmond9/DockSwitch/commit/374b16ffc565e20ac342167ad886a2dacfe5eb5e))

## [0.4.1](https://github.com/ljredmond9/DockSwitch/compare/v0.4.0...v0.4.1) (2026-02-21)


### Bug Fixes

* get pr number correctly ([#14](https://github.com/ljredmond9/DockSwitch/issues/14)) ([10f6e40](https://github.com/ljredmond9/DockSwitch/commit/10f6e4019100b61e1fbc726c78f9b929702f246f))
* parse PR number from release-please JSON output ([#15](https://github.com/ljredmond9/DockSwitch/issues/15)) ([e9addbc](https://github.com/ljredmond9/DockSwitch/commit/e9addbcef1935f99e8dc508f0d73a04d08860efd))
* set git identity for Cargo.lock sync step ([#16](https://github.com/ljredmond9/DockSwitch/issues/16)) ([fb08c4b](https://github.com/ljredmond9/DockSwitch/commit/fb08c4b7c901dfe0590acc6b8a2349326cb0094f))
* update readme to test new workflow ([#12](https://github.com/ljredmond9/DockSwitch/issues/12)) ([d9b0b7f](https://github.com/ljredmond9/DockSwitch/commit/d9b0b7f0a3ce23c1719e9feb83fb24b6c1f00445))

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
