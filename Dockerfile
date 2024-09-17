# Dockerfile

FROM python:3.8-slim
LABEL maintainer="Frank Bertsch <frank@mozilla.com>"

ARG APP_NAME=python_application
ENV APP_NAME=${APP_NAME}
ENV HOME="/app"
WORKDIR ${HOME}

ARG USER_ID="10001"
ARG GROUP_ID="app"

RUN groupadd --gid ${USER_ID} ${GROUP_ID} && \
    useradd --create-home --uid ${USER_ID} --gid ${GROUP_ID} --home-dir ${HOME} ${GROUP_ID}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip
RUN pip install coverage

COPY requirements/ ${HOME}/requirements/
RUN pip install -r ${HOME}/requirements/requirements.txt
RUN pip install -r ${HOME}/requirements/test_requirements.txt

COPY python_application/ ${HOME}/${APP_NAME}/python_application/
COPY setup.py ${HOME}/${APP_NAME}/
COPY README.md ${HOME}/${APP_NAME}/
RUN pwd && ls -l 
COPY tests/ ${HOME}/tests/ 

ENV PYTHONPATH="${PYTHONPATH}:${HOME}/${APP_NAME}"
ENV PATH $PATH:${HOME}/${APP_NAME}/bin
WORKDIR ${HOME}

RUN pip install -e ${HOME}/${APP_NAME}

RUN find ${HOME} -name "__pycache__" -exec rm -rf {} + || true
RUN find ${HOME} -name "*.pyc" -exec rm -f {} + || true

RUN chown -R ${USER_ID}:${GROUP_ID} ${HOME}
USER ${USER_ID}

ENTRYPOINT ["entrypoint"]
