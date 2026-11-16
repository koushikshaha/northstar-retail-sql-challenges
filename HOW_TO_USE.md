# Connect PostgreSQL, work in VS Code, and publish to GitHub

## Your database is already prepared

| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `northstar_retail_challenges` |
| Username | `postgres` |
| Schema | `northstar_retail` |
| Password | Enter your PostgreSQL password locally; it is not saved in this project |

The server is PostgreSQL 18.4. Three tables, 650 records, the reporting layer, all 30 answer views, and validation results are already present. There is no need to rerun setup to see them.

## Option A: pgAdmin

1. Open pgAdmin 4. Expand **Servers → PostgreSQL 18** and enter your server password. If no connection is listed, right-click **Servers → Register → Server**; give it a name and use the host, port, username and password above (maintenance database `postgres`).
2. Expand **Databases → northstar_retail_challenges → Schemas → northstar_retail**. Refresh Databases if the new database is not visible.
3. Under **Tables**, find `customers`, `orders`, and `order_items`. Under **Views**, find `q01` through `q30` and the supporting views.
4. Right-click the database and open **Query Tool**. Run:

```sql
SELECT current_database();
SELECT * FROM northstar_retail.q01;
```

5. Select one SQL statement at a time and execute it to inspect that result. Use `q02_worst_losses`, `q18_common_weights`, `q22_annual_regions`, or `q30_source_trace` for the extra tables. The answer report lists all supplementary views.

To recreate the project on another machine, create an empty database and run `all_in_one.sql` once, or files 01–04 in order. Use the same database throughout. Do not rerun `01_setup.sql` against the existing schema: duplicate-object errors mean it is already loaded. After an error inside a transaction, run `ROLLBACK;` before continuing.

Official reference: [pgAdmin server connections](https://www.pgadmin.org/docs/pgadmin4/latest/connecting.html).

## Option B: VS Code terminal

VS Code is an editor; PostgreSQL is the database server. You can connect from VS Code's terminal without installing a database extension.

1. In VS Code choose **File → Open Folder** and select this project folder (the one containing README.md and `.git`).
2. Open **Terminal → New Terminal**. On this Windows computer, connect with:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -h localhost -p 5432 -U postgres -W -d northstar_retail_challenges
```

3. Enter your password when prompted. Password entry does not display characters. At the database prompt, run:

```sql
SELECT * FROM northstar_retail.q01;
SELECT * FROM northstar_retail.q30;
SELECT * FROM northstar_retail.validation_results;
```

4. Exit with `\q`. To rerun the reporting logic and checks from the PowerShell terminal:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -h localhost -p 5432 -U postgres -W -d northstar_retail_challenges -v ON_ERROR_STOP=1 -f 02_reporting_views.sql -f 03_all_30_solutions.sql -f 04_validation.sql
```

5. Refresh saved CSVs after changing the queries:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -h localhost -p 5432 -U postgres -W -d northstar_retail_challenges -f export_results.psql
```

Use the project folder as the terminal's current directory. These commands prompt for the password rather than putting it in a SQL file or connection URL. `run_all.psql` and `export_results.psql` contain psql commands and must run in psql; `all_in_one.sql` and files 01–04 also work in pgAdmin.

Official reference: [PostgreSQL psql](https://www.postgresql.org/docs/18/app-psql.html).

## GitHub and VS Code

GitHub hosts the SQL, README, analysis and CSV files. It does not receive your local database password or make your local database available online.

For the repository prepared with this project, open its folder in VS Code. To update it after editing:

1. Open **Source Control** (`Ctrl+Shift+G`). Inspect the changes.
2. Stage only the intended project files using **+**.
3. Enter a message such as `Improve retention analysis` and choose **Commit**.
4. Choose **Sync Changes** or **Push**. Complete GitHub sign-in if requested.

For a new project that has not yet been published, VS Code offers **Initialize Repository**, then **Publish to GitHub**; choose the repository name and public/private visibility. For this project, use its existing remote instead of publishing a duplicate.

Equivalent terminal commands for future updates:

```sh
git status
git add README.md ANSWERS.md 03_all_30_solutions.sql results/
git commit -m "Update retail analysis"
git push
```

Review the files before committing. `.gitignore` excludes common credential files, local database storage and temporary files. Keep passwords and tokens out of SQL, README, screenshots and commit messages.

Official reference: [VS Code source control quickstart](https://code.visualstudio.com/docs/sourcecontrol/quickstart).

## Common problems

| Message or symptom | What to do |
|---|---|
| `psql` is not recognized | Use the complete Windows executable path shown above. |
| Password authentication failed | Check username and the PostgreSQL server password, not the GitHub password. |
| Connection refused | Check that the PostgreSQL service is running and that the port is 5432. |
| `relation q01 does not exist` | Use `northstar_retail.q01`, or set `search_path` to `northstar_retail, public`. |
| Schema already exists | Setup has already run. Query the existing views or rerun only files 02–04. |
| Current transaction is aborted | Execute `ROLLBACK;`, correct the cause, then rerun the failed transaction. |
| A result is NULL | It may represent an unobserved horizon, zero denominator, or missing promise; inspect the KPI contract. |
| GitHub changes are missing | Saving a file is local; commit and push to upload it. |
