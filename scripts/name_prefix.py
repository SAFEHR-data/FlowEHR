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
$PREFIX and $ENVIRONMENT
"""
import os
import re
import argparse


def _remove_whitespace(string: str) -> str:
    return string.replace(" ", "")


def _replace_hyphens_with_underscores(string: str) -> str:
    return string.replace("-", "_")


def _last_n_characters(string: str, n: int) -> str:
    return string[-n:]


def _remove_non_alpha_numeric_chars(string: str) -> str:
    return re.sub("[^a-zA-Z0-9]+", "", string)


def naming_prefix():
    """
    Construct a naming prefix that satisfies the naming requirements for a resource
    group. Any hyphens in $PREFIX and $ENVIRONMENT to separate "blocks"
    """

    def transform(string: str) -> str:
        return _replace_hyphens_with_underscores(_remove_whitespace(string))

    prefix = f"{transform(os.environ['PREFIX'])}-{transform(os.environ['ENVIRONMENT'])}"

    if len(prefix) == 0:
        raise RuntimeError(
            "Cannot create a prefix with no chars. At least one of $PREFIX and "
            "$ENVIRONMENT must be set to a non-empty string"
        )

    return _last_n_characters(prefix, n=90)


def truncated_naming_prefix():
    """
    Construct a naming prefix from both the base prefix and environment
    variables with the following requirements:

        1. Cannot start with a non-letter, due to key vault naming requirements
        azure.github.io/PSRule.Rules.Azure/en/rules/Azure.KeyVault.Name/

        2. Cannot be longer than 20 characters, given a conventional "strg" suffix
           for storage accounts. And the storage account naming requirements:
           learn.microsoft.com/en-us/azure/storage/common/storage-account-overview

        3. Must not contain any non-alpha numeric characters or upper case letters
    """
    prefix = _remove_non_alpha_numeric_chars(naming_prefix())

    if prefix[0].isdigit():
        prefix = f"a{prefix}"

    return _last_n_characters(prefix.lower(), n=20)


def test_naming() -> None:

    test_data = {
        ("flowehr", "dev"): ("flowehr-dev", "flowehrdev"),
        ("a", "infra-test"): ("a-infra_test", "ainfratest"),
        ("a b", "prod"): ("ab-prod", "abprod"),
        ("a-long-prefix", "a-long-env-name"): (
            "a_long_prefix-a_long_env_name",
            "ngprefixalongenvname",
        ),
        ("1aprefix", "dev"): ("1aprefix-dev", "a1aprefixdev"),
    }

    for (prefix, environment), (expected, expected_t) in test_data.items():
        os.environ["PREFIX"] = prefix
        os.environ["ENVIRONMENT"] = environment
        assert naming_prefix() == expected
        assert truncated_naming_prefix() == expected_t


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-t",
        "--truncated",
        action="store_true",
        help="Print the truncated naming prefix suitable for storage accounts etc.",
    )
    args = parser.parse_args()

    if args.truncated:
        print(truncated_naming_prefix())
    else:
        print(naming_prefix())
