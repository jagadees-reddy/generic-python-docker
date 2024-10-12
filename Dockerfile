# Dockerfile
FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

# Step 1: Create a non-root user and group with specific UID and GID
RUN rm -rf /app && \
    groupadd -g 10001 app && \
    useradd -m -u 10001 -g 10001 -d /app app

# Step 2: Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Step 3: Configure Git for the root user to avoid permission issues
RUN git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name" && \
    git config --global --add safe.directory "*"

# Step 4: Upgrade pip and install required packages
RUN pip install --upgrade pip
RUN pip install coverage pytest

# Step 5: Copy requirements and install them
COPY requirements/ ${HOME}/requirements/
RUN pip install -r ${HOME}/requirements/requirements.txt
RUN pip install -r ${HOME}/requirements/test_requirements.txt

# Step 6: Copy the application code
COPY python_application/ ${HOME}/${APP_NAME}/python_application/
COPY setup.py ${HOME}/${APP_NAME}/
COPY README.md ${HOME}/${APP_NAME}/

# Step 7: Create necessary directories in the /harness path and set permissions
RUN mkdir -p /harness/generic-python-docker/tests /harness/generic-python-docker/test-results && \
    chown -R app:app /harness && \
    chmod -R 777 /harness

# Step 8: Copy the tests to the correct directory
COPY tests/ /harness/generic-python-docker/tests/

# Step 9: Set environment variables and working directory
ENV PYTHONPATH="${PYTHONPATH}:${HOME}/${APP_NAME}"
ENV PATH $PATH:${HOME}/${APP_NAME}/bin

WORKDIR ${HOME}

# Step 10: Install the application in editable mode
RUN pip install -e ${HOME}/${APP_NAME}

# Step 11: Clean up any __pycache__ and .pyc files
RUN find ${HOME} -name "__pycache__" -exec rm -rf {} + || true
RUN find ${HOME} -name "*.pyc" -exec rm -f {} + || true

# Step 12: Confirm write access to /harness/generic-python-docker/test-results as app user
RUN touch /harness/generic-python-docker/test-results/permission_check.txt && \
    chown app:app /harness/generic-python-docker/test-results/permission_check.txt && \
    ls -ld /harness/generic-python-docker/test-results && \
    ls -l /harness/generic-python-docker/test-results/

# Step 13: Switch to non-root user for final runtime
USER app

# Step 14: Set entrypoint to run pytest with appropriate options
ENTRYPOINT ["pytest", "--rootdir=/harness/generic-python-docker", "/harness/generic-python-docker/tests", "--junitxml=/harness/generic-python-docker/test-results/results.xml"]
