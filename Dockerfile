# Dockerfile
FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

ARG USER_ID="10001"
ARG GROUP_ID="app"

# Create a non-root user
RUN groupadd --gid ${USER_ID} ${GROUP_ID} && \
    useradd --create-home --uid ${USER_ID} --gid ${GROUP_ID} --home-dir ${HOME} ${GROUP_ID}

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

# Create necessary directories in the /harness path and apply permissions
RUN mkdir -p /harness/generic-python-docker/tests \
    /harness/generic-python-docker/test-results && \
    chmod -R 777 /harness/generic-python-docker && \
    chown -R ${USER_ID}:${GROUP_ID} /harness/generic-python-docker

# Apply permissions specifically to /harness/generic-python-docker/test-results
RUN mkdir -p /harness/generic-python-docker/test-results && \
    chown -R 10001:app /harness/generic-python-docker/test-results

# Copy the tests to the correct directory
COPY tests/ /harness/generic-python-docker/tests/

# Final permissions check to ensure correct settings
RUN chmod -R 777 /harness/generic-python-docker/test-results && \
    chown -R ${USER_ID}:${GROUP_ID} /harness/generic-python-docker/test-results && \
    ls -ld /harness/generic-python-docker/test-results

# Set environment variables and working directory
ENV PYTHONPATH="${PYTHONPATH}:${HOME}/${APP_NAME}"
ENV PATH $PATH:${HOME}/${APP_NAME}/bin

WORKDIR ${HOME}

# Install the application in editable mode
RUN pip install -e ${HOME}/${APP_NAME}

# Clean up any __pycache__ and .pyc files
RUN find ${HOME} -name "__pycache__" -exec rm -rf {} + || true
RUN find ${HOME} -name "*.pyc" -exec rm -f {} + || true

# Adjust the entrypoint to run pytest with the correct options
ENTRYPOINT ["pytest", "--rootdir=/harness/generic-python-docker", "/harness/generic-python-docker/tests", "--junitxml=/harness/generic-python-docker/test-results/results.xml"]
