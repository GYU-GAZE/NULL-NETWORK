"""Run the production EditorPlugin workflow in an isolated project copy."""
import argparse
import pathlib
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
parser.add_argument("--workspace", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--headless", action="store_true")
parser.add_argument("--capture", help="Optional native Editor screenshot path")
args = parser.parse_args()
source = pathlib.Path(__file__).resolve().parents[2]
workspace = pathlib.Path(args.workspace).resolve()
workspace.mkdir(parents=True, exist_ok=True)
shutil.copytree(source, workspace, dirs_exist_ok=True,
                ignore=shutil.ignore_patterns(".git", ".godot", "__pycache__", "Godot_v*", "godot.zip", "*.log"))
project = workspace / "project.godot"
settings = project.read_text(encoding="utf-8")
engine = str(pathlib.Path(args.godot).resolve())
output = pathlib.Path(args.output).resolve()
output.parent.mkdir(parents=True, exist_ok=True)
# Import before enabling the smoke plugin. A fresh project has no font/texture
# cache and the test must not create scenes while the initial scan loads addons.
try:
    with output.with_suffix(".import.log").open("wb") as log:
        imported = subprocess.run([engine, "--headless", "--editor", "--import", "--path", str(workspace)],
                                  stdout=log, stderr=subprocess.STDOUT, timeout=90)
except subprocess.TimeoutExpired:
    print("Editor import timed out; see", output.with_suffix(".import.log"))
    sys.exit(1)
if imported.returncode:
    print("Editor import failed; see", output.with_suffix(".import.log"))
    sys.exit(1)
settings = settings.replace(
    'enabled=PackedStringArray("res://addons/website_authoring/plugin.cfg")',
    'enabled=PackedStringArray("res://addons/website_authoring/plugin.cfg", '
    '"res://tests/browser/editor_smoke/plugin.cfg")')
project.write_text(settings, encoding="utf-8")
command = [engine, "--editor", "--path", str(workspace)]
if args.headless:
    command.append("--headless")
if args.capture:
    command.extend(["--", "--editor-capture=" + str(pathlib.Path(args.capture).resolve())])
try:
    with output.open("wb") as log:
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=90)
except subprocess.TimeoutExpired:
    print("Editor smoke timed out; see", output)
    sys.exit(1)
content = output.read_text(encoding="utf-8", errors="replace")
if result.returncode or "WEBSITE_AUTHORING_EDITOR_SMOKE: PASS" not in content:
    print(content)
    sys.exit(1)
print("WEBSITE_AUTHORING_EDITOR_SMOKE: PASS")
