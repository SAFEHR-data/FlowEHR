from setuptools import setup, find_packages

import src

setup(
  name='src',
  version=src.__version__,
  author=src.__author__,
  description='Package with example data pipeline code',
  packages=find_packages(include=['src']),
  entry_points={
  },
  install_requires=[
    'setuptools'
  ]
)
