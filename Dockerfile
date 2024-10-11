# Dockerfile
FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

# Set explicit UID and GID values for the non-root user
ARG USER_ID="10001"
ARG GROUP_ID="10001"

# Create a group and a non-root user with the specified UID and GID
RUN groupadd -g ${GROUP_ID} app && \
    useradd -m -u ${USER_ID} -g ${GROUP_ID} -d ${HOME} app

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
RUN mkdir -p /harness/generic-python-docker/tests /harness/generic-python-docker/test-results && \
    chown -R ${USER_ID}:${GROUP_ID} /harness/generic-python-docker && \
    chmod -R 777 /harness/generic-python-docker

# Copy the tests to the correct directory
COPY tests/ /harness/generic-python-docker/tests/

# Final permissions check for test-results
RUN chown -R ${USER_ID}:${GROUP_ID} /harness/generic-python-docker/test-results && \
    chmod -R 777 /harness/generic-python-docker/test-results && \
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
