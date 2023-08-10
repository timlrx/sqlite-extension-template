import os
import sqlite3

from sqlite_rot13.version import __version_info__, __version__ 

ENTRYPOINT_NO_READ = "sqlite3_lines_no_read_init"

def loadable_path():
  loadable_path = os.path.join(os.path.dirname(__file__), "rot13")
  return os.path.normpath(loadable_path)

def load(connection: sqlite3.Connection)  -> None:
  connection.load_extension(loadable_path())
