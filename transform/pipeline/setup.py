#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

from setuptools import setup, find_packages

import src

# This is a Python wheel set up file
# See https://peps.python.org/pep-0427/
setup(
    name="src",
    version=src.__version__,
    author=src.__author__,
    description="Package with example data pipeline code",
    packages=find_packages(include=["src"]),
    entry_points={
        # Unlike a pure Databricks job, ADF-Databricks job ignores this,
        # and instead requires an entrypoint.py file
    },
    install_requires=["setuptools"],
)
