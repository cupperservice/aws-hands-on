FROM python:3.11.4-slim-buster
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
wget \
unzip \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

RUN if [ "$TARGETPLATFORM"= "linux/arm64" ]; then ARCHITECTURE=aarch64; else ARCHITECTURE=x86_64; fi \
&& wget -nv "https://awscli.amazonaws.com/awscli-exe-linux-$ARCHITECTURE.zip"-O "/tmp/awscliv2.zip" \
&& unzip /tmp/awscliv2.zip -d /tmp/awscliv2 \
&& /tmp/awscliv2/aws/install \
&& rm -rf /tmp/awscliv2.zip /tmp/awscliv2

RUN pip3 install --no-cache-dir --upgrade \
mkdocs==1.3.0 \
mkdocs-material==8.3.9 \
mkdocs-redirects==v1.0.5 \
pygments \
pymdown-extensions

RUN useradd -m mkdocs
USER mkdocs

CMD ["mkdocs","serve"]
