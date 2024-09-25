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

# Upgrade pip and install coverage and Pytest
RUN pip install --upgrade pip
RUN pip install coverage Pytest  # Ensure Pytest is installed here with a capital P

# Copy requirements and install them
COPY generic-python-docker/requirements/ ${HOME}/requirements/
RUN pip install -r ${HOME}/requirements/requirements.txt
RUN pip install -r ${HOME}/requirements/test_requirements.txt

# Explicitly check if Pytest is installed
RUN Pytest --version || echo "Pytest is not installed!"  # Ensure Pytest is installed.

# Copy the application code
COPY generic-python-docker/python_application/ ${HOME}/${APP_NAME}/python_application/
COPY generic-python-docker/setup.py ${HOME}/${APP_NAME}/
COPY generic-python-docker/README.md ${HOME}/${APP_NAME}/

# Create necessary directories in the /harness path
RUN mkdir -p /harness/generic-python-docker/tests
RUN mkdir -p /harness/generic-python-docker/test-results

# Set permissions for the /harness path (important to ensure write access)
RUN chown -R ${USER_ID}:${GROUP_ID} /harness/generic-python-docker
RUN chmod -R 777 /harness/generic-python-docker/tests
RUN chmod -R 777 /harness/generic-python-docker/tests/test_app.py
RUN chmod -R 777 /harness/generic-python-docker/test-results  # Ensure the test-results folder is fully writable

# Copy the tests to the correct directory
COPY generic-python-docker/tests/ /harness/generic-python-docker/tests/

# Verify the directory structure and ensure paths are created correctly
RUN ls -R /harness

# Set environment variables and working directory
ENV PYTHONPATH="${PYTHONPATH}:${HOME}/${APP_NAME}"
ENV PATH $PATH:${HOME}/${APP_NAME}/bin

WORKDIR ${HOME}

# Install the application in editable mode
RUN pip install -e ${HOME}/${APP_NAME}

# Clean up any __pycache__ and .pyc files
RUN find ${HOME} -name "__pycache__" -exec rm -rf {} + || true
RUN find ${HOME} -name "*.pyc" -exec rm -f {} + || true

# Set ownership and switch to the non-root user
USER ${USER_ID}

# Adjust the entrypoint to run Pytest with the correct options
ENTRYPOINT ["Pytest", "--rootdir=/harness/generic-python-docker", "/harness/generic-python-docker/tests", "--junitxml=/harness/generic-python-docker/test-results/results.xml"]

# Ensure the results file is generated and exists
RUN ls -R /harness/generic-python-docker/test-results
