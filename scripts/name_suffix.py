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
Script used to name azure resources given the environment variables
$SUFFIX and $ENVIRONMENT
"""
import os
import re
import argparse


def _last_n_characters(string: str, n: int) -> str:
    return string[-n:]


def _remove_non_alpha_numeric_chars(string: str) -> str:
    return re.sub("[^a-zA-Z0-9]+", "", string)


def naming_suffix():
    """
    Construct a naming suffix that satisfies the naming requirements for a resource
    group. Any hyphens, underscores or spaces in $SUFFIX and $ENVIRONMENT will be
    deleted
    """

    def transform(string: str) -> str:
        for excluded_character in (" ", "-", "_"):
            string = string.replace(excluded_character, "")

        return string

    suffix = f"{transform(os.environ['SUFFIX'])}-{transform(os.environ['ENVIRONMENT'])}"

    if len(suffix) == 0:
        raise RuntimeError(
            "Cannot create a suffix with no chars. At least one of $SUFFIX and "
            "$ENVIRONMENT must be set to a non-empty string"
        )

    return _last_n_characters(suffix, n=90)


def truncated_naming_suffix():
    """
    Construct a naming suffix from both the base suffix and environment
    variables with the following requirements:

        1. Cannot start with a non-letter, due to key vault naming requirements
        azure.github.io/PSRule.Rules.Azure/en/rules/Azure.KeyVault.Name/

        2. Cannot be longer than 17 characters, given a "<abc>strg" suffix
           for storage accounts. And the storage account naming requirements:
           learn.microsoft.com/en-us/azure/storage/common/storage-account-overview

        3. Must not contain any non-alpha numeric characters or upper case letters
    """
    suffix = _remove_non_alpha_numeric_chars(naming_suffix())

    if suffix[0].isdigit():
        suffix = f"a{suffix}"

    return _last_n_characters(suffix.lower(), n=17)


def test_naming() -> None:

    test_data = {
        ("flowehr", "dev"): ("flowehr-dev", "flowehrdev"),
        ("a", "infra-test"): ("a-infratest", "ainfratest"),
        ("a b", "prod"): ("ab-prod", "abprod"),
        ("a-long-suffix", "a-long-env-name"): (
            "alongsuffix-alongenvname",
            "uffixalongenvname",
        ),
        ("1asuffix", "dev"): ("1asuffix-dev", "a1asuffixdev"),
    }

    for (suffix, environment), (expected, expected_t) in test_data.items():
        os.environ["SUFFIX"] = suffix
        os.environ["ENVIRONMENT"] = environment
        assert naming_suffix() == expected
        assert truncated_naming_suffix() == expected_t


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-t",
        "--truncated",
        action="store_true",
        help="Print the truncated naming suffix suitable for storage accounts etc.",
    )
    args = parser.parse_args()

    if args.truncated:
        print(truncated_naming_suffix())
    else:
        print(naming_suffix())
