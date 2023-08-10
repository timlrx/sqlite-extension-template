import sqlite3
import unittest

EXT_PATH="./dist/debug/rot13"

def connect(path=":memory:"):
  db = sqlite3.connect(path)
  db.enable_load_extension(True)

  db.execute("create temp table base_functions as select name from pragma_function_list")
  db.execute("create temp table base_modules as select name from pragma_module_list")
  db.load_extension(EXT_PATH)
  db.execute("create temp table loaded_functions as select name from pragma_function_list where name not in (select name from base_functions) order by name")
  db.execute("create temp table loaded_modules as select name from pragma_module_list where name not in (select name from base_modules) order by name")
  return db

db = connect()

def explain_query_plan(sql):
  return db.execute("explain query plan " + sql).fetchone()["detail"]

def execute_all(cursor, sql, args=None):
  if args is None: args = []
  results = cursor.execute(sql, args).fetchall()
  return list(map(lambda x: dict(x), results))

FUNCTIONS = [
  'rot13',
  'rot13_version',
]

MODULES = [
  "rot13",
]

class TestCases(unittest.TestCase):
  def test_funcs(self):
    funcs = list(map(lambda a: a[0], db.execute("select name from loaded_functions").fetchall()))
    self.assertEqual(funcs, FUNCTIONS)

  def test_modules(self):
    modules = list(map(lambda a: a[0], db.execute("select name from loaded_modules").fetchall()))
    self.assertEqual(modules, MODULES)

  def test_rot13_version(self):
    self.assertEqual(db.execute("select rot13_version()").fetchone()[0][0], "v")

  def test_rot13(self):
    self.assertEqual(db.execute("select rot13('hello')").fetchone()[0], "uryyb")

class TestCoverage(unittest.TestCase):                                      
  def test_coverage(self):                                                      
    test_methods = [method for method in dir(TestCases) if method.startswith('test_')]
    funcs_with_tests = set([x.replace("test_", "") for x in test_methods])
    for func in FUNCTIONS:
      self.assertTrue(func in funcs_with_tests, f"{func} does not have corresponding test in {funcs_with_tests}")

if __name__ == '__main__':
    unittest.main()