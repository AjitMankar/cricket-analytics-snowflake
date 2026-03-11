# Import python packages
import streamlit as st
import plotly.express as px

from snowflake.snowpark.context import get_active_session

# Write directly to the app

# Get the current credentials
session = get_active_session()

st.title("🏏 Cricket Data Warehouse Dashboard")

# -----------------------------
# Load Data
# -----------------------------

teams = session.sql("""
SELECT *
FROM DW.TEAMS
""").to_pandas()

matches = session.sql("""
SELECT *
FROM DW.MATCH_INFO
""").to_pandas()

innings = session.sql("""
SELECT *
FROM DW.MATCH_INNINGS
""").to_pandas()

# Flatten player-team relationship
players = session.sql("""
SELECT 
    p.PLAYER_ID,
    p.PLAYER_NAME,
    f.value::NUMBER AS TEAM_ID
FROM DW.PLAYERS p,
LATERAL FLATTEN(input => p.TEAMS) f
""").to_pandas()

# Join with teams to get team names
player_team = session.sql("""
SELECT
    p.PLAYER_NAME,
    f.value::NUMBER AS TEAM_ID,
    t.TEAM_NAME
FROM DW.PLAYERS p,
LATERAL FLATTEN(input => p.TEAMS) f
JOIN DW.TEAMS t
ON f.value::NUMBER = t.TEAM_ID
""").to_pandas()


# -----------------------------
# Sidebar Navigation
# -----------------------------

dashboard = st.sidebar.selectbox(
    "Select Dashboard",
    ["Teams Overview", "Players", "Matches", "Innings"]
)

# -----------------------------
# Teams Overview
# -----------------------------

if dashboard == "Teams Overview":

    st.subheader("Teams")

    st.dataframe(teams)

    team_counts = player_team.groupby("TEAM_NAME").size().reset_index(name="PLAYER_COUNT")

    fig = px.bar(
        team_counts,
        x="TEAM_NAME",
        y="PLAYER_COUNT",
        title="Players per Team"
    )

    st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Players Dashboard
# -----------------------------

elif dashboard == "Players":

    st.subheader("Players by Team")

    team = st.selectbox("Select Team", player_team["TEAM_NAME"].unique())

    filtered = player_team[player_team["TEAM_NAME"] == team]

    st.dataframe(filtered)

    fig = px.histogram(
        filtered,
        x="PLAYER_NAME",
        title=f"Players in {team}"
    )

    st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Match Summary
# -----------------------------

elif dashboard == "Matches":

    st.subheader("Match Information")

    st.dataframe(matches)

    if "VENUE" in matches.columns:

        venue_stats = matches.groupby("VENUE").size().reset_index(name="MATCHES")

        fig = px.pie(
            venue_stats,
            names="VENUE",
            values="MATCHES",
            title="Matches by Venue"
        )

        st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Innings Analysis
# -----------------------------

elif dashboard == "Innings":

    st.subheader("Innings Runs Analysis")

    if "TEAM_ID" in innings.columns and "RUNS" in innings.columns:

        runs = innings.groupby("TEAM_ID")["RUNS"].sum().reset_index()

        fig = px.bar(
            runs,
            x="TEAM_ID",
            y="RUNS",
            title="Total Runs by Team"
        )

        st.plotly_chart(fig, use_container_width=True)

    st.dataframe(innings)
