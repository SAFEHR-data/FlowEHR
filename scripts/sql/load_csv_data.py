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

import pandas
from sqlalchemy import create_engine
import os
import pyodbc

server = os.environ.get("SERVER")
database = os.environ.get("DATABASE")
client_id = os.environ.get("CLIENT_ID")
client_secret = os.environ.get("CLIENT_SECRET")
path_to_csv = os.environ.get("PATH_TO_CSV")
table_name = os.environ.get("TABLE_NAME")


def create_con_str(db: str) -> str:
    driver = "{ODBC Driver 18 for SQL Server}"
    return f"DRIVER={driver};SERVER={server};DATABASE={db};ENCRYPT=yes;Authentication=ActiveDirectoryServicePrincipal;UID={client_id};PWD={client_secret}"  # noqa: E501


con_str = create_con_str(database)
engine = create_engine("mssql+pyodbc:///?odbc_connect={}".format(con_str))

df = pandas.read_csv(path_to_csv)

# drop table if exists
cnxn = pyodbc.connect(con_str)
cursor = cnxn.cursor()

query = f"""
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[{table_name}]') AND type in (N'U'))
DROP TABLE [dbo].[{table_name}]
"""  # noqa: E501

cursor.execute(query)
cnxn.commit()

# save file to SQL
df.to_sql(table_name, schema="dbo", con=engine)

# uncomment below to query some new rows
# cnxn = pyodbc.connect(create_con_str(database))
# cursor = cnxn.cursor()
# cursor.execute("SELECT top 10 * from dbo." + table_name)
# row = cursor.fetchone()
# while row:
#     print(row[0])
#     row = cursor.fetchone()
