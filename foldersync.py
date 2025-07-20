import os
import pathlib
import shutil
import json
import fnmatch
import logging
import threading
import time
import watchdog
import rich
# import tqdm
from pathlib import Path
from typing import List, Union, Dict, Optional


from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from rich.console import Console
from rich.logging import RichHandler

# --- Configuration Loader ---
def load_config(config_path="projectconfig.json"):
    with open(config_path, "r") as f:
        config = json.load(f)
    return config

# --- Path Resolver ---
def resolve_paths(config):
    # Map logical names to absolute paths
    base_dir = pathlib.Path(__file__).parent.resolve()
    
    
    source_folders: Dict[str, pathlib.Path] = {
        name: (base_dir / name).resolve()
        for name in config["filesync"]["source_folders"]
    }
    logging.info(f"Resolved source folders: {source_folders}")
    shared_folder: pathlib.Path = (base_dir / config["filesync"]["shared_folder"]).resolve()
    logging.info(f"Resolved shared folder: {shared_folder}")
    # Destination folders may be absolute or relative
    destination_folders: Dict[str, pathlib.Path | None] = {}
    for name, dest in config["filesync"]["destination_folders"].items():
        if dest:
            destination_folders[name] = pathlib.Path(dest).resolve()
            # logging.info(f"Resolved destination folder '{name}': {destination_folders[name]}")
        else:
            destination_folders[name] = None  # To be filled in or handled
            # logging.info(f"No destination folder specified for '{name}', will handle later")
    logging.info(f"Resolved destination folders: {destination_folders}")
    return source_folders, shared_folder, destination_folders


def add_files_to_gitignore(folderName: str|Path, files: List[str]):
    """
    Add specified files to .gitignore in the given folder.
    If .gitignore does not exist, it will be created.
    """
    gitignore_path = Path(__file__).parent / ".gitignore"
    try:
        existing = set()
        if gitignore_path.exists():
            with gitignore_path.open("r") as f:
                existing = set(line.strip() for line in f)
        with gitignore_path.open("a") as f:
            for file in files:
                if file not in existing:
                    f.write("\n")
                    f.write(f"{folderName}/{file}")
                    logging.info(f"Added '{folderName}/{file}' to .gitignore")
                else:
                    logging.info(f"'{folderName}/{file}' already exists in .gitignore, skipping.")
    except Exception as e:
        logging.error(f"Error writing to .gitignore: {e}")
    #
#
def remove_files_from_gitignore(files: List[str]):
    """
    Remove specified files from .gitignore in the given folder.
    If .gitignore does not exist, it will be created.
    """
    gitignore_path = Path(".gitignore")
    try:
        if gitignore_path.exists():
            with gitignore_path.open("r") as f:
                lines = f.readlines()
            #
            with gitignore_path.open("w") as f:
                for line in lines:
                    if line.strip() not in files:
                        f.write(line)
                    else:
                        logging.info(f"Removed '{line.strip()}' from .gitignore")
        else:
            logging.warning(".gitignore does not exist, nothing to remove.")
    except Exception as e:
        logging.error(f"Error writing to .gitignore: {e}")
        logging.exception("Exception occurred")
    #
#


# --- Sync Engine ---
def sync_shared_to_sources(shared_folder: pathlib.Path, source_folders: Dict[str, pathlib.Path], shared_policies: list[dict]):
    # For each policy, copy shared subfolders/files into each source folder
    """
    A shared_policy looks like:
    {
        folder: string,  -- a folder (name) within the shared-folder
        replicate_to_source_folders: string[]  -- list of folder-names to replicate above-mentioned folder into
    }
    """

    for policy in shared_policies:

        policy_folderName: str = policy["folder"]
        policy_replicateToSourceFolders: list[str] = policy["replicate_to_source_folders"]

        shared_subfolder: pathlib.Path = shared_folder / policy_folderName
        if not shared_subfolder.exists():
            logging.warning(f"Shared subfolder {shared_subfolder} does not exist, skipping.")
            continue
        #
        for source_name in policy_replicateToSourceFolders:
            if source_name in source_folders:
                source_path = source_folders[source_name]
                if not source_path.exists():
                    logging.warning(f"Source folder {source_path} does not exist, skipping.")
                    continue
                #
                # Copy the shared subfolder to the source folder
                dest_path = source_path / policy_folderName
                """
                If the destination folder already exists, we want to merge it's contents.
                For now, we will replace it, but keep already existing sub-files/folders. Which is equivalent to a "merge" operation.

                What does "merge" mean in this context?
                It means copying files from the shared subfolder to the source folder, but not deleting any existing files in the source folder.
                If a file exists in both the shared subfolder and the source folder, the one in the source folder will remain unchanged.
                - However, I want that file to be overwritten IF the file in the shared subfolder is newer.
                - If a file exists in the source folder but not in the shared subfolder, it will remain unchanged.

                If a file is to be merged, then it must be added to the .gitignore to reduce noise in the git repository.

                Code to do this, as follows...
                """
                try:
                    merged_files = []
                    if dest_path.exists():
                        logging.info(f"Merging shared subfolder '{shared_subfolder}' into source folder '{dest_path}'")
                        for item in shared_subfolder.iterdir():
                            dest_item = dest_path / item.name
                            if item.is_dir():
                                if dest_item.exists():
                                    # If the destination is a directory, merge contents
                                    shutil.copytree(item, dest_item, dirs_exist_ok=True)
                                else:
                                    shutil.copytree(item, dest_item)
                                # Add directory to .gitignore
                                merged_files.append(str((policy_folderName + "/" + item.name).replace("\\", "/")))
                            else:
                                if not dest_item.exists() or item.stat().st_mtime > dest_item.stat().st_mtime:
                                    # Copy file only if it doesn't exist or is newer
                                    shutil.copy2(item, dest_item)
                                    merged_files.append(str((policy_folderName + "/" + item.name).replace("\\", "/")))
                                else:
                                    # Still add to .gitignore, since it's a shared file
                                    merged_files.append(str((policy_folderName + "/" + item.name).replace("\\", "/")))
                            #
                        #
                    elif dest_path.exists() and dest_path.is_file():
                        logging.warning(f"Destination path '{dest_path}' is a file, not a directory. Skipping merge.")
                    else:
                        logging.info(f"Copying shared subfolder '{shared_subfolder}' to new source folder '{dest_path}'")
                        shutil.copytree(shared_subfolder, dest_path)
                        # Add all files/dirs to .gitignore
                        for item in shared_subfolder.iterdir():
                            merged_files.append(str((policy_folderName + "/" + item.name).replace("\\", "/")))
                    #
                    if merged_files:
                        add_files_to_gitignore(source_name, merged_files)
                except Exception as e:
                    logging.error(f"Error while syncing shared folder '{shared_subfolder}' to source folder '{dest_path}': {e}")
                #
            else:
                logging.warning(f"Source folder '{source_name}' not found in configuration.")
            #
        #
    #
    return

def sync_source_to_destination(source_folder, destination_folder, policy):
    # Copy files from source to destination, respecting excludes
    pass  # To be implemented

# --- Live Watcher ---
class SyncEventHandler(FileSystemEventHandler):
    def __init__(self, sync_callback):
        super().__init__()
        self.sync_callback = sync_callback

    def on_any_event(self, event):
        # Call the sync callback with event info
        self.sync_callback(event)

def start_watchers(folders_to_watch, sync_callback):
    observers = []
    for folder in folders_to_watch:
        observer = Observer()
        handler = SyncEventHandler(sync_callback)
        observer.schedule(handler, str(folder), recursive=True)
        observer.start()
        observers.append(observer)
    return observers

# --- Logging Setup ---
console = Console()
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(console=console)]
)

# --- Main Program ---
def main():
    config = load_config()
    source_folders, shared_folder, destination_folders = resolve_paths(config)
    # Initial sync order: shared -> sources
    sync_shared_to_sources(shared_folder, source_folders, config["filesync"]["shared_sync_policies"])
    for policy in config["filesync"]["sync_policies"]:
        folder = policy["folder"]
        sync_source_to_destination(source_folders[folder], destination_folders[folder], policy)
    # Start live watchers
    def sync_callback(event):
        # Decide what to sync based on event.src_path
        logging.info(f"Detected change: {event.src_path}")
        # Call appropriate sync function(s)
        if event.src_path.startswith(str(shared_folder)):
            # Sync from shared to sources
            sync_shared_to_sources(shared_folder, source_folders, config["filesync"]["shared_sync_policies"])
        else:
            # Sync from sources to destinations
            pass  # To be implemented

    folders_to_watch = [shared_folder] + list(source_folders.values())
    observers = start_watchers(folders_to_watch, sync_callback)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        for observer in observers:
            observer.stop()
        for observer in observers:
            observer.join()
    finally:
        logging.info("Stopping watchers and exiting...")

if __name__ == "__main__":
    main()


print("[End of Program]")
# End of File