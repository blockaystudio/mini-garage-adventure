#!/usr/bin/env python3
"""Real native processes sharing one isolated wallet; no browser/cloud claim."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "native"


def main():
    engine = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not engine:
        raise RuntimeError("Install the pinned native Godot engine first")
    checks = 0
    workers = []
    with tempfile.TemporaryDirectory(prefix="garage-save-concurrency-") as temporary:
        directory = Path(temporary)
        env = dict(os.environ, XDG_DATA_HOME=temporary, XDG_CACHE_HOME=temporary,
                   XDG_CONFIG_HOME=temporary, GODOT_SILENCE_ROOT_WARNING="1")
        profile = directory / "garage"

        def check(condition, label):
            nonlocal checks
            if not condition:
                raise RuntimeError(label)
            checks += 1
            print("PASS:", label, flush=True)

        def start(mode, label, item=""):
            control = directory / label
            process = subprocess.Popen([engine, "--headless", "--path", str(NATIVE),
                "--script", "res://tests/save_concurrency_worker.gd", "--",
                mode, str(profile), str(control), item], env=env,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            workers.append(process)
            return process, control

        def wait_file(path):
            deadline = time.monotonic() + 20
            while not path.exists():
                if time.monotonic() > deadline:
                    raise RuntimeError(f"Timed out waiting for {path.name}")
                time.sleep(0.01)

        def result(worker):
            process, control = worker
            output, _ = process.communicate(timeout=25)
            if process.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output:
                raise RuntimeError(f"Native worker failed ({process.returncode}): {output}")
            return json.loads(Path(str(control)+".result").read_text())

        def ready(worker):
            wait_file(Path(str(worker[1])+".ready"))
            return json.loads(Path(str(worker[1])+".ready").read_text())

        def go(worker):
            Path(str(worker[1])+".go").write_text("go")

        try:
            check(result(start("seed", "seed"))["success"], "isolated native wallet starts with900GP")
            a = start("buy", "stale-a", "mud")
            b = start("buy", "stale-b", "sand")
            check(ready(a)["pid"] != ready(b)["pid"], "independent native PIDs load the same initial wallet")
            go(a)
            check(result(a)["success"], "first native process commits mud purchase")
            go(b)
            stale = result(b)
            check(not stale["success"] and "Reload" in stale["warning"], "second native process rejects its stale purchase")
            retry = start("buy", "fresh-retry", "sand")
            ready(retry)
            go(retry)
            final = result(retry)
            check(final["success"] and final["gp"] == 0 and {"mud", "sand"}.issubset(final["owned"]),
                  "new native process reloads then buys sand without losing mud")

            # Simultaneous barrier release exercises the check/write race itself.
            for iteration in range(8):
                check(result(start("seed", f"race-seed-{iteration}"))["success"], f"race{iteration} seed")
                a = start("buy", f"race-a-{iteration}", "mud")
                b = start("buy", f"race-b-{iteration}", "sand")
                ready(a)
                ready(b)
                go(a)
                go(b)
                outcomes = [result(a), result(b)]
                check(sum(bool(value["success"]) for value in outcomes) == 1,
                      f"race{iteration} exactly one concurrent snapshot may commit")
                wallet = result(start("read", f"race-read-{iteration}"))
                check((wallet["gp"] == 600 and "mud" in wallet["owned"] and "sand" not in wallet["owned"])
                      or (wallet["gp"] == 300 and "sand" in wallet["owned"] and "mud" not in wallet["owned"]),
                      f"race{iteration} disk contains one complete transaction")

            check(result(start("seed", "crash-seed"))["success"], "crash fixture seed")
            holder = start("hold", "live-lock")
            owner = ready(holder)
            check(bool(owner["owner"]), "native process acquires nonempty writer lock")
            contender = start("buy", "blocked-live", "mud")
            ready(contender)
            go(contender)
            blocked = result(contender)
            check(not blocked["success"] and "Another game instance" in blocked["warning"],
                  "live native writer lock rejects other purchases")
            check(not result(start("reset", "blocked-reset"))["success"], "reset cannot remove a live writer's files")
            holder[0].kill()
            holder[0].communicate(timeout=10)
            survivor = start("buy", "after-crash", "mud")
            ready(survivor)
            go(survivor)
            recovered = result(survivor)
            check(recovered["success"] and recovered["gp"] == 600 and "mud" in recovered["owned"],
                  "after killed writer is reaped, dead native lock recovers safely")
            check(not Path(str(profile)+".lock").exists(), "successful save releases writer lock")
            check(not list(directory.glob("garage.lock.*")), "normal and contested writers leave no candidate locks")
            for iteration in range(3):
                check(result(start("seed", f"reclaim-seed-{iteration}"))["success"], f"reclaim{iteration} seed")
                holder = start("hold", f"reclaim-dead-{iteration}")
                check(bool(ready(holder)["owner"]), f"reclaim{iteration} native writer lock acquired")
                holder[0].kill()
                holder[0].communicate(timeout=10)
                a = start("buy", f"reclaim-a-{iteration}", "mud")
                b = start("buy", f"reclaim-b-{iteration}", "sand")
                ready(a)
                ready(b)
                go(a)
                go(b)
                outcomes = [result(a), result(b)]
                check(sum(bool(value["success"]) for value in outcomes) == 1,
                      f"reclaim{iteration} competing dead-owner reclaimers permit one transaction")
                wallet = result(start("read", f"reclaim-read-{iteration}"))
                check((wallet["gp"] == 600 and "mud" in wallet["owned"] and "sand" not in wallet["owned"])
                      or (wallet["gp"] == 300 and "sand" in wallet["owned"] and "mud" not in wallet["owned"]),
                      f"reclaim{iteration} surviving complete wallet is preserved")
        finally:
            for process in workers:
                if process.poll() is None:
                    process.kill()
                    process.communicate(timeout=10)
    print(f"SAVE_CONCURRENCY_RESULT checks={checks} failures=0 (native Linux processes)")


if __name__ == "__main__":
    main()
