# Release notes — thub-examples

What changed, newest first. This repository isn't on npm and has no versions: each entry is dated, and `## Unreleased` collects what isn't pushed yet. `bin/publish` in the TestHub monorepo pushes it (README §14.1).

## 2026-10-08

The first scripts and configs: every job script and Client config from the TestHub documentation (README §7, §8.6, §8.8, §8.9, and the dashboard's Help page), as files.

### Added

- **Boards** (`ci/`): `nucleo.sh` (STM32 Nucleo-64, `st-flash`), `nrf52.sh` (nRF52840 DK, `nrfutil`), `esp32.sh` (ESP32-DevKitC, `esptool` v5), `arduino.sh` (Arduino Uno R3, `avrdude`), and `flash-all.sh` (five boards on one Client, flashed at once).
- **Flight controllers** (`ci/`): `betaflight.sh` with `bf-cli.py` (DFU flashing, then the bench's settings restored over the CLI), and `ardupilot.sh` with `mav-check.py` (`uploader.py`, then a MAVLink heartbeat and version check). `FC_PORT`, `FC_USB` and `AP_VERSION` adapt them to a bench.
- **Simulators** (`ci/`, `tests/`): `renode.sh` with `tests/renode/self-test.robot` (Robot Framework in Docker, JUnit to `results/`), and `qemu.sh` (a semihosting test image on MPS2-AN385).
- **Helpers** (`ci/`): `serial-expect.py` (wait for a line on a serial port, optionally resetting the board through DTR/RTS), `power.sh` and `run.sh` (smart sockets and PDUs, always switched off at the end), `artifacts.sh`, `publish-junit.sh` (every test case in the PR comment), and `test.sh` with `tests/conftest.py` (what a job's script gets).
- **Client configs** (`config/`): one whole config per setup: `nucleo`, `nrf52840-dk`, `esp32-devkitc`, `arduino-uno`, `betaflight`, `ardupilot`, `bench5` (five boards), `simulators` (SW).
- **Host setup** (`host/`): `install-tools.sh` and `45-stdfu.rules` (STM32 DFU for `dfu-util`).
- **Checks** (`test/examples.test.js`, `node --test`): the scripts parse, the configs are valid for the Client and render their udev rules, and in the monorepo, the README and the Help page show each script exactly as it is here.
