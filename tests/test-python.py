import unittest
import sqlite3
import sqlite_rot13

class TestSqliteVectorPython(unittest.TestCase):
  def test_path(self):
    self.assertEqual(type(sqlite_rot13.loadable_path()), str)
  
  def test_load(self):
    db = sqlite3.connect(':memory:')
    db.enable_load_extension(True)
    sqlite_rot13.load(db)

    version, = db.execute('select rot13_version()').fetchone()
    self.assertEqual(version[0], "v")
    
if __name__ == '__main__':
    unittest.main()