from setuptools import setup, Extension
import os
import platform

version = {}
with open("sqlite_rot13/version.py") as fp:
    exec(fp.read(), version)

VERSION = version['__version__']

system = platform.system()
machine = platform.machine()

print(system, machine)

if system == 'Darwin':
  if machine not in ['x86_64', 'arm64']:
    raise Exception("unsupported platform")  
elif system == 'Linux':
  if machine not in ['x86_64']:
    raise Exception("unsupported platform")
elif system == 'Windows':
  if machine not in ['x86_64']:
    raise Exception("unsupported platform")
else: 
  raise Exception("unsupported platform")

setup(
    name="sqlite-rot13",
    description="",
    long_description="",
    long_description_content_type="text/markdown",
    author="Author Name",
    url="https://github.com/user/sqlite-rot13",
    license="MIT License, Apache License, Version 2.0",
    version=VERSION,
    packages=["sqlite_rot13"],
    package_data={"sqlite_rot13": ['*.so', '*.dylib', '*.dll']},
    install_requires=[],
    # Adding an Extension makes `pip wheel` believe that this isn't a 
    # pure-python package. The noop.c was added since the windows build
    # didn't seem to respect optional=True
    ext_modules=[Extension("noop", ["noop.c"], optional=True)],
    extras_require={"test": ["pytest"]},
    python_requires=">=3.7",
)