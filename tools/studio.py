#!/usr/bin/env python3
"""Drive Roblox Studio from the command line through its MCP server.

Studio must be open on the place, with `rojo serve` running and connected.

  python3 tools/studio.py test                 play, run the scripted movement tests, print the report, stop
  python3 tools/studio.py quick                the same, but only the short suite: one check per main feature
  python3 tools/studio.py console              recent Studio output
  python3 tools/studio.py lua Client '<code>'  run Luau in the Client or Server datamodel
  python3 tools/studio.py play | stop          start or stop a play session
  python3 tools/studio.py list                 list the MCP tools and their arguments
  python3 tools/studio.py call <tool> '<json>' call any MCP tool

On Windows, type `python` instead of `python3`.
"""
import glob
import json
import os
import queue
import subprocess
import sys
import threading
import time

NOISE = ("Assistant plugin version",)


def find_studio_mcp():
    """Where Roblox Studio keeps its MCP server program on this computer."""
    if sys.platform == "win32":
        # Studio installs each update into a new Versions\version-<hash> folder,
        # so take the newest StudioMCP.exe instead of hard-coding one folder.
        pattern = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox", "Versions", "*", "StudioMCP.exe")
        found = sorted(glob.glob(pattern), key=os.path.getmtime)
        if not found:
            sys.exit("StudioMCP.exe not found under %LOCALAPPDATA%\\Roblox\\Versions. Is Roblox Studio installed?")
        return found[-1]
    return "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"


class Studio:
    def __init__(self):
        self.p = subprocess.Popen([find_studio_mcp()], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL)
        # A background thread reads Studio's replies into a queue, so request() can
        # wait with a timeout. (select() would do this on a Mac, but on Windows it
        # only works on network sockets, not on a program's output pipe.)
        self.lines = queue.Queue()
        threading.Thread(target=self._read_lines, daemon=True).start()
        self.next_id = 0
        if self.request("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                       "clientInfo": {"name": "studio.py", "version": "1"}}, 15) is None:
            sys.exit("Studio MCP did not answer. Is Roblox Studio open?")
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    def _read_lines(self):
        for line in self.p.stdout:
            self.lines.put(line)
        self.lines.put(b"")  # Studio closed its output: tell request() to stop waiting.

    def send(self, message):
        self.p.stdin.write((json.dumps(message) + "\n").encode())
        self.p.stdin.flush()

    def request(self, method, params=None, timeout=60):
        self.next_id += 1
        self.send({"jsonrpc": "2.0", "id": self.next_id, "method": method, "params": params or {}})
        end = time.time() + timeout
        while time.time() < end:
            try:
                line = self.lines.get(timeout=0.5)
            except queue.Empty:
                continue
            if not line:
                break
            try:
                message = json.loads(line)
            except ValueError:
                continue
            if message.get("id") == self.next_id:
                return message
        return None

    def call(self, tool, args=None, timeout=60):
        reply = self.request("tools/call", {"name": tool, "arguments": args or {}}, timeout)
        if reply is None:
            return "no response"
        if "error" in reply:
            return "ERROR " + json.dumps(reply["error"])
        return "\n".join(c.get("text", str(c)) for c in reply.get("result", {}).get("content", []))

    def lua(self, datamodel, code):
        return self.call("execute_luau", {"datamodel_type": datamodel, "code": code})

    def console(self):
        lines = self.call("get_console_output").splitlines()
        return "\n".join(line for line in lines if not any(n in line for n in NOISE))


def run_tests(studio, quick=False):
    studio.call("start_stop_play", {"is_start": False})
    time.sleep(2)
    print(studio.call("start_stop_play", {"is_start": True}).splitlines()[0])
    ready = 'local p = game:GetService("Players").LocalPlayer ' \
            'return p ~= nil and p:FindFirstChild("PlayerGui") ~= nil ' \
            'and p.PlayerGui:FindFirstChild("MovementDebugReadout") ~= nil'
    for _ in range(20):
        time.sleep(1.5)
        if "true" in studio.lua("Client", ready):
            break
    else:
        print("The character never finished loading.")
    time.sleep(1)
    # The value picks the suite: "quick <time>" for the short one, a number for the full one.
    # (It changes every run, so the test script always notices it.)
    trigger = '"quick " .. os.clock()' if quick else 'os.clock()'
    studio.lua("Client", 'game:GetService("Players").LocalPlayer:SetAttribute("RunMovementTests", %s)' % trigger)
    report = ""
    for _ in range(100):  # up to 200 seconds; the full run takes about 90
        time.sleep(2)
        report = studio.lua("Client", 'return game:GetService("Players").LocalPlayer:GetAttribute("MovementTestReport") or "PENDING"')
        if "PENDING" not in report:
            break
    print(report)
    problems = [line for line in studio.console().splitlines()
                if any(word in line.lower() for word in ("error", "warn", "infinite yield", "stack"))]
    print("-- console: " + ("no errors or warnings" if not problems else ""))
    print("\n".join(problems[-15:]))
    studio.call("start_stop_play", {"is_start": False})


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    studio = Studio()
    command = args[0]
    if command == "test":
        run_tests(studio)
    elif command == "quick":
        run_tests(studio, quick=True)
    elif command == "console":
        print(studio.console())
    elif command == "lua":
        print(studio.lua(args[1], args[2]))
    elif command in ("play", "stop"):
        print(studio.call("start_stop_play", {"is_start": command == "play"}))
    elif command == "list":
        reply = studio.request("tools/list") or {}
        for tool in reply.get("result", {}).get("tools", []):
            print("-", tool["name"], json.dumps(tool.get("inputSchema", {}).get("properties", {})))
    elif command == "call":
        print(studio.call(args[1], json.loads(args[2]) if len(args) > 2 else {}))
    else:
        sys.exit(__doc__)
    studio.p.kill()


if __name__ == "__main__":
    main()
