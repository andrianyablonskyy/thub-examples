# thub-examples

Scripts and configs for **TestHub** jobs: what runs on a Client to flash and test a board, a flight controller or a simulator, and the Client config that connects the hardware. These are the examples from the TestHub documentation (README §7 and §8, and the dashboard's Help page), as files you can use.

## Layout

```
ci/        The job's scripts. The documentation calls them ci/<name>.
  serial-expect.py   wait for a line on a board's serial port (every board below uses it)
  nucleo.sh          STM32 Nucleo-64: st-flash through the on-board ST-LINK
  nrf52.sh           nRF52840 DK: nrfutil through the on-board J-Link
  esp32.sh           ESP32-DevKitC: esptool over its USB-UART
  arduino.sh         Arduino Uno R3 (ATmega328P): avrdude through Optiboot
  betaflight.sh      Betaflight flight controller: dfu-util, then restore its settings
  bf-cli.py            Betaflight CLI over USB
  ardupilot.sh       ArduPilot flight controller: uploader.py, then a MAVLink check
  mav-check.py         MAVLink heartbeat and firmware version
  renode.sh          Renode (SW): Robot Framework tests in Docker, JUnit to results/
  qemu.sh            QEMU (SW): a semihosting test image, its exit code is the verdict
  flash-all.sh       five boards on one Client, flashed at once (README §8.6)
  power.sh, run.sh   smart socket / PDU power, and a wrapper that always switches it off (§8.8)
  artifacts.sh       add an entry to the job's artifact list (§7.5)
  publish-junit.sh   upload JUnit results so the PR comment lists every test case (§7.6)
  test.sh            what a job's script gets: downloads, parameters, --env, --meta (§8.1)
tests/
  renode/self-test.robot   the Renode test ci/renode.sh runs
  conftest.py              the job's environment, for pytest
config/    Whole Client configs, one per setup: hw-devices, labels (README §8.6).
  nucleo.json, nrf52840-dk.json, esp32-devkitc.json, arduino-uno.json,
  betaflight.json, ardupilot.json, bench5.json (five boards), simulators.json (SW)
host/      Client host setup, once: install-tools.sh, 45-stdfu.rules (STM32 DFU)
test/      Checks these files (node --test); in the TestHub monorepo, also that the
           documentation shows them as they are here.
RELEASE.md What changed, by date (README §14.1 of the monorepo).
```

## Using them

**In a job, as they are.** Clone this repository in the job's command and run a script. The firmware comes with `--download-file`:

```bash
thub run --type hw --label board:nucleo-f401re --download-file "$FW_URL" \
  --command 'git clone -q --depth 1 https://github.com/andrianyablonskyy/thub-examples.git t &&
             sh t/ci/nucleo.sh "$THUB_DOWNLOAD_1"' \
  --wait
```

**In your test repository.** Copy `ci/` (and `tests/renode/` for Renode) into it, and change what's specific to your bench. Each script finds the helpers next to itself, so they keep working wherever `ci/` is.

**The Client.** Start from the matching file in `config/`:

```bash
cp config/nucleo.json ~/.config/thub/nucleo.json   # set coordinatorUrl, joinKey, and the devpath of your USB port
thub-client register --name nucleo --type hw
```

Find a USB port's `devpath` and the device's vendor/product ID on the runner card → **USB devices**, or with `lsusb -tvv`. The examples use `3.2.4`, and the IDs common for each board; yours may differ.

**The host.** Run `host/install-tools.sh` once on each Client host, as the user the Client runs as.

## Things to adjust

- **Bench-specific values** are at the top of each script, or come from the environment (`FC_PORT`, `FC_USB`, `AP_VERSION`), which a job sets with `--env`.
- **`ci/ardupilot.sh`** needs ArduPilot's `Tools/scripts/uploader.py` copied next to it. It isn't included here: it's ArduPilot's, under its own license.
- **`ci/betaflight.sh`** restores the bench's settings from `ci/bench1-diff.txt`: the output of `diff all` in the Betaflight CLI, saved once per bench.
- **A serial port is either captured or used.** A port under `hw-devices.uarts` is held by the Client for the whole job, so the job can't open it. That's why the board configs list the board's own serial port under `usbs`, as a tty.

## Checks

```bash
node --test         # sh -n / Python syntax, configs valid for the Client, udev rules render
```

In the TestHub monorepo (`packages/client-examples`), the root `npm test` runs these too, and checks that the README and the Help page show every script exactly as it is here.

## License

MIT, see [LICENSE](LICENSE).
