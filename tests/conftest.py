# tests/conftest.py — the job's environment, as pytest fixtures read it (README §8.1).
import glob, os

UARTS     = sorted(glob.glob("/dev/thub/dut*-uart"))                # this Client's UARTs, by udev path
FIRMWARE  = os.environ.get("THUB_DOWNLOAD_1")
RESULTS   = "results"                                            # in the clone (src/results), where the tests run
API_TOKEN = os.environ["API_TOKEN"]                              # from --env API_TOKEN
