import pandas as pd


def model(dbt, session):

    dbt.config(
        materialized="table"
    )

    # use an existing dbt model
    df = dbt.ref("all_dates").to_pandas()

    # simple flag for weekends
    df["is_weekend"] = df["DATE_DAY"].dt.dayofweek >= 5

    return df