# Dockerfile
FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

# Remove /app if it exists, then create a non-root user and group
RUN rm -rf /app && \
    groupadd -g 10001 app && \
    useradd -m -u 10001 -g 10001 -d /app app

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure Git for the root user to avoid permission issues when running commands
RUN git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name" && \
    git config --global --add safe.directory "*"

# Upgrade pip and install coverage and pytest
RUN pip install --upgrade pip
RUN pip install coverage pytest

# Copy requirements and install them
COPY requirements/ ${HOME}/requirements/
RUN pip install -r ${HOME}/requirements/requirements.txt
RUN pip install -r ${HOME}/requirements/test_requirements.txt

# Copy the application code
COPY python_application/ ${HOME}/${APP_NAME}/python_application/
COPY setup.py ${HOME}/${APP_NAME}/
COPY README.md ${HOME}/${APP_NAME}/

# Create necessary directories in the /harness path and apply permissions for the app user
RUN mkdir -p /harness/generic-python-docker/tests /harness/generic-python-docker/test-results && \
    chown -R app:app /harness/generic-python-docker && \
    chmod -R 777 /harness/generic-python-docker

# Copy the tests to the correct directory
COPY tests/ /harness/generic-python-docker/tests/

# Set environment variables and working directory
ENV PYTHONPATH="${PYTHONPATH}:${HOME}/${APP_NAME}"
ENV PATH $PATH:${HOME}/${APP_NAME}/bin

WORKDIR ${HOME}

# Install the application in editable mode
RUN pip install -e ${HOME}/${APP_NAME}

# Clean up any __pycache__ and .pyc files
RUN find ${HOME} -name "__pycache__" -exec rm -rf {} + || true
RUN find ${HOME} -name "*.pyc" -exec rm -f {} + || true

# Test write access to /harness/generic-python-docker/test-results as app user before switching to app user
RUN touch /harness/generic-python-docker/test-results/test_permission_file.txt && \
    chown app:app /harness/generic-python-docker/test-results/test_permission_file.txt

# Switch to non-root user for final runtime
USER app

# Set entrypoint to run pytest with appropriate options
ENTRYPOINT ["pytest", "--rootdir=/harness/generic-python-docker", "/harness/generic-python-docker/tests", "--junitxml=/harness/generic-python-docker/test-results/results.xml"]
