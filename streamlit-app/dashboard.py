"""streamlit-app: a tiny Streamlit dashboard.

Runs behind --server.baseUrlPath app -- see proxy.py for why: Streamlit's own "/" can't be made to
answer this repo's one-line marker contract, so a small proxy answers "/" itself and forwards
everything else, including this app, to Streamlit listening on 127.0.0.1:8501. Visit /app on the
deployed cell to see this dashboard.
"""

import random
import time

import streamlit as st

from marker import marker

st.set_page_config(page_title="agentcell sample: streamlit-app")

st.title("agentcell sample: streamlit-app")
st.caption(f"marker: {marker()}")

st.write(
    "A tiny dashboard: a slider and a chart of random data regenerated on every rerun, to show "
    "Streamlit's rerun-the-whole-script model doing its usual thing behind the proxy in front of "
    "it."
)

points = st.slider("data points", min_value=5, max_value=200, value=50)
data = [random.random() for _ in range(points)]

col1, col2 = st.columns(2)
col1.metric("points", points)
col2.metric("mean", f"{sum(data) / len(data):.3f}")

st.line_chart(data)

st.caption("server time: " + time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()))
