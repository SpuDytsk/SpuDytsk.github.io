FROM ubuntu:22.04

RUN apt-get update \
  && rm -rf /var/cache/apk/* \
  && apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      git \
      make \
      bash \
  && useradd --uid 1000 --create-home boro

COPY --chown=boro:boro requirements.txt .

USER boro

RUN echo "[safe] directory = *" >> ~/.gitconfig

ENV PATH="/home/boro/.local/bin:${PATH}"

RUN pip3 install -r requirements.txt --ignore-installed  --user

WORKDIR /opt/elecard/docs

ENTRYPOINT [ "cat" ]
