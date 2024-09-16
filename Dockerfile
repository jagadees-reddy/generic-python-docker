# Dockerfile

FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

# Create a non-root user
ARG USER_ID="10001"
ARG GROUP_ID="app"

RUN groupadd --gid ${USER_ID} ${GROUP_ID} && \
    useradd --create-home --uid ${USER_ID} --gid ${GROUP_ID} --home-dir ${HOME} ${GROUP_ID}

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip and install coverage
RUN pip install --upgrade pip
RUN pip install coverage

# Copy requirements and install them
COPY requirements/ requirements/
RUN pip install -r requirements/requirements.txt
RUN pip install -r requirements/test_requirements.txt

# Copy the application code
COPY python_application/ ${HOME}/${APP_NAME}/python_application/
COPY setup.py ${HOME}/${APP_NAME}/

# Copy the README file
COPY README.md ${HOME}/${APP_NAME}/

# Copy the tests outside the application directory to avoid conflicts
COPY tests/ ${HOME}/tests/

ENV PATH $PATH:${HOME}/${APP_NAME}/bin
WORKDIR ${HOME}/${APP_NAME}

# Install the application
RUN pip install -e .

# Change ownership and switch to the non-root user
RUN chown -R ${USER_ID}:${GROUP_ID} ${HOME}
USER ${USER_ID}

ENTRYPOINT ["entrypoint"]
