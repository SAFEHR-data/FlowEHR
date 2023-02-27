#! /usr/bin/env python3
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
# limitations under the License.

"""
Print the address space of the core FlowEHR vnet given the envrionment variable:
$USE_RANDOM_ADDRESS_SPACE
"""
import os
import random


def should_use_random() -> bool:
    env_var = os.environ.get("USE_RANDOM_ADDRESS_SPACE", default="0")
    assert env_var in ("0", "1")
    return bool(int(env_var))


if __name__ == "__main__":

    # The random seed needs to be set based on the naming suffix so re-applies use the
    # same address space. $PYTHONHASHSEED must also be defined
    assert os.environ["PYTHONHASHSEED"] == "0"
    random.seed(os.environ["NAMING_SUFFIX"])

    if should_use_random():
        a, b = random.randint(0, 255), random.randint(0, 255)
    else:
        a, b = 0, 0

    print(f"10.{a}.{b}.0/24")
