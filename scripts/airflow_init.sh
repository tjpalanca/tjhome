airflow initdb

airflow users create \
    --username tjpalanca \
    --firstname TJ \
    --lastname Palanca \
    --role Admin \
    --email mail@tjpalanca.com

airflow webserver --port 8080
