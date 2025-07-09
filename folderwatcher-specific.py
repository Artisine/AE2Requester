"""

Copies contents of "client" folder into CLIENT folder, defined later.
Copies contents of "server" folder into SERVER folder, defined later.
Watches for changes in the "client" and "server" folders and updates the CLIENT and SERVER folders accordingly.

"""
import argparse
from concurrent.futures import thread
import fnmatch
import logging
import pathlib
import sys
import os
import shutil
import threading
import time
import typing

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, LoggingEventHandler
from rich.console import Console
from rich.logging import RichHandler
from rich.text import Text

TARGET_SERVER_FOLDER_PATH = "C:\\Users\\cheeh\\AppData\\Roaming\\PrismLauncher\\instances\\Optimised CCTweaked AE2\\minecraft\\saves\\Test1_CCT_AE2\\computercraft\\computer\\0\\Docs"
TARGET_CLIENT_FOLDER_PATH = "C:\\Users\\cheeh\\AppData\\Roaming\\PrismLauncher\\instances\\Optimised CCTweaked AE2\\minecraft\\saves\\Test1_CCT_AE2\\computercraft\\computer\\2\\Docs"

print("TARGET_SERVER_FOLDER_PATH:", TARGET_SERVER_FOLDER_PATH)
print("TARGET_CLIENT_FOLDER_PATH:", TARGET_CLIENT_FOLDER_PATH)


# Define the source folders
SOURCE_SERVER_FOLDER_PATH = "./server"
SOURCE_CLIENT_FOLDER_PATH = "./client"
path_source_server = pathlib.Path(SOURCE_SERVER_FOLDER_PATH)
path_source_client = pathlib.Path(SOURCE_CLIENT_FOLDER_PATH)

# Define the target folders
path_target_server = pathlib.Path(TARGET_SERVER_FOLDER_PATH)
path_target_client = pathlib.Path(TARGET_CLIENT_FOLDER_PATH)

# Ensure the target folders exist

path_target_server.mkdir(parents=True, exist_ok=True)
path_target_client.mkdir(parents=True, exist_ok=True)

# --- Begin FolderWatcher Functionality ---
console = Console()
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(console=console)]
)

allowlist_to_copy = [
    "*.lua",
    "*.txt",
    "utils/*.*",
    "*.xml",
]
excluded_folders = [
    "__pycache__",
    ".git",
    ".mypy_cache",
    ".vscode",
    "basalt"
]

filestructs = {}
timers = {}
timers_lock = threading.Lock()
timers_event = threading.Event()
TIMERS_INCREMENT_SECONDS = 0.100
TIMER_DURATION_SECONDS = 0.500

class StructInfoFilestuff:
    def __init__(self, filename: pathlib.Path, source_folder: str, target_folder: str, sourceShort: str|None = None, targetShort: str|None = None):
        self.filename = filename
        self.source_folder = source_folder
        self.target_folder = target_folder
        self.sourceShort = sourceShort
        self.targetShort = targetShort

def timer_thread():
    while not timers_event.is_set():
        with timers_lock:
            expired_keys = []
            for key in list(timers.keys()):
                timers[key] -= TIMERS_INCREMENT_SECONDS
                if timers[key] <= 0:
                    expired_keys.append(key)
        time.sleep(TIMERS_INCREMENT_SECONDS)

def file_modified(file_path: str, filestruct: StructInfoFilestuff):
    with timers_lock:
        timers[file_path] = TIMER_DURATION_SECONDS
        filestructs[file_path] = filestruct
    return 0

def mainThread_timersManager():
    while not timers_event.is_set():
        for file_path in list(timers.keys()):
            if timers[file_path] <= 0:
                fileStructToUse = filestructs[file_path]
                copyFileToTargetFolder(fileStructToUse)
                fileNameToUse = (fileStructToUse.sourceShort + "/" + fileStructToUse.filename.as_posix()) if fileStructToUse.sourceShort else file_path
                print(f"Timer {fileNameToUse} has expired, hence copied file over.")
                with timers_lock:
                    del timers[file_path]
                    del filestructs[file_path]
            if not timers:
                break
        time.sleep(TIMERS_INCREMENT_SECONDS)
    return 0

def copyFileToTargetFolder(structFileInfo: StructInfoFilestuff, **kwargs):
    source_folder = structFileInfo.source_folder
    target_folder = structFileInfo.target_folder
    sourceShort = structFileInfo.sourceShort
    targetShort = structFileInfo.targetShort
    filename = structFileInfo.filename
    source_file_path = pathlib.Path(source_folder).joinpath(filename).resolve()
    target_path = pathlib.Path(target_folder).joinpath(filename).resolve()
    target_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        # Overwrite confirmation prompt
        # if target_path.exists():
        #     from rich.prompt import Confirm
        #     if not Confirm.ask(f"[yellow]Overwrite existing file {target_path}?[/yellow]", default=True):
        #         print(f"[bold red]Skipping overwrite of {filename.as_posix()} to {target_path}[/]")
        #         return 0
        if kwargs.get("dev_skip", False) != True:
            shutil.copy2(source_file_path, target_path)
        else:
            print(f"[bold red]Skipping copy of {filename.as_posix()} to {target_path}[/]")
        leftText = Text("    Copied:   ", style="bold white on blue", justify="left")
        if sourceShort != None and targetShort != None:
            centerText = Text(justify="center")
            centerText.append(f"{sourceShort}", style="red")
            centerText.append(f"/{filename.as_posix()}", style="")
            centerText.append("  >>  ", style="")
            centerText.append(f"{targetShort}", style="green")
            centerText.append(f"/{filename.as_posix()}", style="")
        else:
            centerText = Text(f"{filename.as_posix()}  >>  {target_path}", style="", justify="center")
        console.print(leftText, end="")
        console.print(centerText, justify="center")
    except Exception as e:
        print(f"Error copying file: {e}")
    return 0

class CustomEventHandler(FileSystemEventHandler):
    def __init__(self, source_folder: str, target_folder: str, sourceShortName: str|None, targetShortName: str|None, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.source_folder = source_folder
        self.target_folder = target_folder
        self.sourceShortName = sourceShortName
        self.targetShortName = targetShortName
    def on_modified(self, event):
        if event.is_directory or self.target_folder == None:
            return
        if any(excluded in pathlib.Path(event.src_path).parts for excluded in excluded_folders):
            return
        for pattern in allowlist_to_copy:
            if not fnmatch.fnmatch(event.src_path, pattern):
                continue
            filename = pathlib.Path(event.src_path).relative_to(self.source_folder)
            fileStruct = StructInfoFilestuff(filename, self.source_folder, self.target_folder, self.sourceShortName, self.targetShortName)
            file_modified(event.src_path, fileStruct)
            break
        return super().on_modified(event)

# Start the watcher for both client and server folders
def start_watchers():
    event_handler_client = CustomEventHandler(
        str(path_source_client.resolve()), str(path_target_client.resolve()), "vscode client", "MC CCT Client"
    )
    event_handler_server = CustomEventHandler(
        str(path_source_server.resolve()), str(path_target_server.resolve()), "vscode server", "MC CCT Server"
    )
    observer_client = Observer()
    observer_server = Observer()
    observer_client.schedule(event_handler_client, str(path_source_client.resolve()), recursive=True)
    observer_server.schedule(event_handler_server, str(path_source_server.resolve()), recursive=True)
    observer_client.start()
    observer_server.start()
    print(f"Monitoring client: {path_source_client.resolve()}")
    print(f"Monitoring server: {path_source_server.resolve()}")
    thread_mainTimerManager = threading.Thread(target=mainThread_timersManager, daemon=True)
    thread_secondaryTimerDecrementer = threading.Thread(target=timer_thread, daemon=True)
    thread_mainTimerManager.start()
    thread_secondaryTimerDecrementer.start()
    try:
        while observer_client.is_alive() and observer_server.is_alive():
            observer_client.join(1)
            observer_server.join(1)
            time.sleep(0.1)
    except KeyboardInterrupt:
        print("Stopping folder watcher...")
        observer_client.stop()
        observer_server.stop()
        timers_event.set()
    finally:
        timers_event.set()
        time.sleep(0.25)
        thread_mainTimerManager.join()
        thread_secondaryTimerDecrementer.join()
        observer_client.stop()
        observer_server.stop()
        observer_client.join()
        observer_server.join()
        print("Folder watcher stopped.")

if __name__ == "__main__":
    start_watchers()

# --- End FolderWatcher Functionality ---



















# End of File