# Dockerfile
FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

# Set application variables
ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

# Create a non-root user and group (but don't switch to it)
RUN groupadd -g 10001 app && \
    useradd -m -u 10001 -g 10001 -d /app app

# Install necessary packages and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --upgrade pip coverage pytest

# Copy and install dependencies
COPY requirements/ ${HOME}/requirements/
RUN pip install -r ${HOME}/requirements/requirements.txt
RUN pip install -r ${HOME}/requirements/test_requirements.txt

# Copy the application code and tests
COPY python_application/ ${HOME}/${APP_NAME}/python_application/
COPY setup.py ${HOME}/${APP_NAME}/
COPY README.md ${HOME}/${APP_NAME}/
COPY tests/ /harness/generic-python-docker/tests/

# Set up test-results directory with permissions at build-time
RUN mkdir -p /harness/generic-python-docker/test-results && \
    chmod -R 777 /harness

# Install application in editable mode
RUN pip install -e ${HOME}/${APP_NAME}

# Set entrypoint to run pytest with test reporting
ENTRYPOINT ["pytest", "--rootdir=/harness/generic-python-docker", "/harness/generic-python-docker/tests", "--junitxml=/harness/generic-python-docker/test-results/results.xml"]
