
# Cricket Analytics Data Pipeline & Dashboard

Snowflake • AWS S3 • Snowpipe • SQL • Streamlit

---

# Project Overview

This project demonstrates a modern **cloud data pipeline and analytics dashboard** built using **Snowflake, AWS S3, and Streamlit**.

The pipeline ingests **raw JSON cricket match data from AWS S3**, processes it through multiple layers (**RAW → STAGING → DATA WAREHOUSE**), and exposes insights through a **Streamlit analytics dashboard**.

The project showcases real-world **Data Engineering and Analytics patterns** including:

* Cloud data ingestion
* Semi-structured data processing
* Snowflake data warehousing
* Task orchestration
* Data transformation using SQL
* Interactive dashboard analytics

---

# Architecture Overview

S3 Raw JSON Files
↓
Snowflake Storage Integration
↓
External Stage
↓
Snowpipe (Auto Ingestion)
↓
RAW Layer Tables
↓
STAGING Layer Transformations
↓
DW Layer Analytical Tables
↓
Streamlit Dashboard

---

# Technology Stack

| Technology      | Purpose                   |
| --------------- | ------------------------- |
| Snowflake       | Cloud Data Warehouse      |
| AWS S3          | Raw data storage          |
| Snowpipe        | Continuous data ingestion |
| Snowflake Tasks | Pipeline orchestration    |
| SQL             | Data transformation       |
| Streamlit       | Interactive dashboard     |
| Plotly          | Data visualization        |

---

# Data Layers

The project follows a **medallion-style architecture** with three layers.

## RAW Layer

The RAW layer stores **unprocessed JSON data exactly as received from S3**.

Characteristics:

* Semi-structured data
* Stored as VARIANT columns
* No transformations applied
* Source of truth

Example table:

```
RAW.MATCH_DATA
```

Structure example:

```
RAW.MATCH_DATA
-------------------------
FILE_NAME
LOAD_TIME
RAW_JSON (VARIANT)
```

---

## STAGING Layer

The STAGING layer extracts fields from JSON and converts them into relational columns.

Operations performed:

* JSON parsing
* Flattening arrays
* Data type casting
* Basic cleansing

Example tables:

```
STAGING.MATCH_INFO
STAGING.PLAYERS
STAGING.MATCH_INNINGS
```

---

## DATA WAREHOUSE (DW) Layer

The DW layer contains **analytics-ready tables** optimized for reporting and dashboards.

Example tables:

```
DW.TEAMS
DW.PLAYERS
DW.MATCH_INFO
DW.MATCH_INNINGS
```

This layer is used directly by **Streamlit dashboards and BI tools**.

---

# Data Ingestion from AWS S3

## Step 1 — Create Storage Integration

Snowflake Storage Integration allows secure access to S3.

Example:

```
CREATE STORAGE INTEGRATION cricket_s3_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'aws-role-arn'
STORAGE_ALLOWED_LOCATIONS = ('s3://cricket-data-bucket/');
```

---

## Step 2 — Create External Stage

External stages point to the S3 location.

```
CREATE STAGE cricket_raw_stage
STORAGE_INTEGRATION = cricket_s3_integration
URL = 's3://cricket-data-bucket/raw/'
FILE_FORMAT = (TYPE = JSON);
```

---

## Step 3 — Load Data Using Snowpipe

Snowpipe automatically loads new files from S3.

```
CREATE PIPE cricket_pipe
AUTO_INGEST = TRUE
AS
COPY INTO RAW.MATCH_DATA
FROM @cricket_raw_stage;
```

Snowpipe continuously monitors the stage and loads new files.

---

# Processing Semi-Structured JSON Data

Snowflake supports JSON data using the **VARIANT data type**.

Example raw record:

```
{
 "match_id":101,
 "teams":["India","Australia"],
 "players":[
    {"name":"Virat Kohli","team_id":1},
    {"name":"Rohit Sharma","team_id":1}
 ]
}
```

To extract nested values we use **JSON path expressions**.

Example:

```
SELECT
RAW_JSON:match_id::NUMBER
FROM RAW.MATCH_DATA;
```

---

# Using LATERAL FLATTEN

Many JSON structures contain **arrays**.
Snowflake uses **LATERAL FLATTEN** to expand arrays into rows.

Example JSON:

```
players:[
 {"name":"Virat Kohli"},
 {"name":"Rohit Sharma"}
]
```

SQL Example:

```
SELECT
f.value:name::STRING AS PLAYER_NAME
FROM RAW.MATCH_DATA,
LATERAL FLATTEN(input => RAW_JSON:players) f;
```

Result:

| PLAYER_NAME  |
| ------------ |
| Virat Kohli  |
| Rohit Sharma |

---

# Player Multi-Team Example

In the DW layer, the `PLAYERS` table stores an array of team IDs.

Example:

```
PLAYER_NAME | TEAM_IDS
--------------------------------
Ben Stokes  | [2,3]
```

To analyze this we flatten the array.

```
SELECT
p.PLAYER_NAME,
f.value::NUMBER AS TEAM_ID
FROM DW.PLAYERS p,
LATERAL FLATTEN(input => p.TEAM_IDS) f;
```

This converts one row into multiple rows.

---

# Task Orchestration

Snowflake **Tasks** automate transformation pipelines.

Tasks run SQL statements on a schedule or based on dependencies.

Example pipeline:

```
RAW → STAGING → DW
```

---

## Task Example

```
CREATE TASK staging_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = '5 MINUTE'
AS
INSERT INTO STAGING.MATCH_INFO
SELECT ...
FROM RAW.MATCH_DATA;
```

---

## Task Dependency

Tasks can depend on other tasks.

```
CREATE TASK dw_task
AFTER staging_task
AS
INSERT INTO DW.MATCH_INFO
SELECT ...
FROM STAGING.MATCH_INFO;
```

This ensures transformations run **in the correct order**.

---

# Streamlit Dashboard

The final analytics layer is visualized using **Streamlit**.

The dashboard includes:

* Teams overview
* Player participation across teams
* Match insights
* Innings performance

Example Streamlit query:

```
SELECT
TEAM_ID,
SUM(RUNS) AS TOTAL_RUNS
FROM DW.MATCH_INNINGS
GROUP BY TEAM_ID;
```

Charts are created using **Plotly** for interactive visualization.

---

# Key SQL Functions Used

The project uses several important Snowflake SQL features:

| Function            | Purpose                    |
| ------------------- | -------------------------- |
| LATERAL FLATTEN     | Expand JSON arrays         |
| VARIANT             | Store semi-structured data |
| COPY INTO           | Load data from stage       |
| STORAGE INTEGRATION | Secure S3 connection       |
| EXTERNAL STAGE      | Reference S3 location      |
| SNOWPIPE            | Continuous ingestion       |
| TASK                | Workflow automation        |
| STREAM              | Change data capture        |
| JSON path           | Extract JSON attributes    |

---

# How to Run the Streamlit Dashboard

Install dependencies:

```
pip install -r requirements.txt
```

Run the dashboard:

```
streamlit run streamlit/app.py
```

---

# Project Structure

```
cricket-analytics-snowflake
│
├── data
├── sql
├── streamlit
├── screenshots
├── requirements.txt
└── README.md
```

---

# Key Learning Outcomes

This project demonstrates:

* End-to-end cloud data pipeline
* Semi-structured JSON processing
* Snowflake ingestion archite
