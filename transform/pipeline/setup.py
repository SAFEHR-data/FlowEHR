from setuptools import setup, find_packages

import src

# This is a Python wheel set up file
# See https://peps.python.org/pep-0427/
setup(
  name='src',
  version=src.__version__,
  author=src.__author__,
  description='Package with example data pipeline code',
  packages=find_packages(include=['src']),
  entry_points={
    # Unlike a pure Databricks job, ADF-Databricks job ignores this,
    # and instead requires an entrypoint.py file
  },
  install_requires=[
    'setuptools'
  ]
)
