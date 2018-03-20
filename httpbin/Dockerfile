FROM python:3.6

RUN pip install gunicorn httpbin

# Note that gunicorn gives access to headers whereas nginx does not
ENV GUNICORN_CMD_ARGS="--bind=0.0.0.0:8000 --workers=3 --capture-output --error-logfile - --access-logfile - --access-logformat '%(h)s %(t)s %(r)s %(s)s Content-Type: %({Content-Type}i)s'"

CMD ["gunicorn", "httpbin:app"]
