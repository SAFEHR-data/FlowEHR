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

import pyodbc
import os

server = os.environ.get("SERVER")
database = os.environ.get("DATABASE")
client_id = os.environ.get("CLIENT_ID")
client_secret = os.environ.get("CLIENT_SECRET")
login_to_create = os.environ.get("LOGIN_TO_CREATE")


def create_con_str(db: str) -> str:
    driver = "{ODBC Driver 18 for SQL Server}"
    return f"DRIVER={driver};SERVER={server};DATABASE={db};ENCRYPT=yes;Authentication=ActiveDirectoryServicePrincipal;UID={client_id};PWD={client_secret}"  # noqa: E501


exit()

# connect to master database to create login
cnxn = pyodbc.connect(create_con_str("master"))
cursor = cnxn.cursor()

query = f"""
IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '{login_to_create}') BEGIN
    CREATE LOGIN [{login_to_create}]
    FROM EXTERNAL PROVIDER
END
"""  # noqa: E501
cursor.execute(query)
cnxn.commit()

# connect to target feature database to create user + assign as dbo
cnxn = pyodbc.connect(create_con_str(database))
cursor = cnxn.cursor()

query = f"""
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '{login_to_create}') BEGIN
    CREATE USER [{login_to_create}] FROM EXTERNAL PROVIDER
    EXEC sp_addrolemember 'db_owner', [{login_to_create}]
END
"""  # noqa: E501

cursor.execute(query)
cnxn.commit()
