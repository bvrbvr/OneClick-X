FROM alpine:3.21.3

RUN apk add --no-cache openssl wget unzip

RUN wget https://github.com/XTLS/Xray-core/releases/download/v25.3.6/Xray-linux-64.zip -O /tmp/Xray-linux-64.zip && \
    mkdir -p /opt/xray && \
    unzip /tmp/Xray-linux-64.zip -d /opt/xray && \
    chmod +x /opt/xray/xray && \
    rm /tmp/Xray-linux-64.zip

COPY ./config.json /opt/xray/config.json
COPY ./fake_sites.txt /opt/xray/fake_sites.txt

RUN /opt/xray/xray uuid > /opt/xray/xray-creds.txt && \
    openssl rand -hex 8 >> /opt/xray/xray-creds.txt && \
    openssl rand -hex 32 >> /opt/xray/xray-creds.txt && \
    shuf -n 1 /opt/xray/fake_sites.txt >> /opt/xray/xray-creds.txt && \
    echo >> /opt/xray/xray-creds.txt && \
    /opt/xray/xray x25519 >> /opt/xray/xray-creds.txt

ARG CLIENT_EMAIL="shadowuser@shadowserver"
RUN echo "Client e-mail: $CLIENT_EMAIL" >> /opt/xray/xray-creds.txt && \
    sed -i "s/XRAY_UUID/$(head -n 1 /opt/xray/xray-creds.txt)/g" /opt/xray/config.json && \
    sed -i "s/CLIENT_EMAIL/$CLIENT_EMAIL/g" /opt/xray/config.json && \
    sed -i "s/SHORT_ID/$(head -2 /opt/xray/xray-creds.txt | tail -1)/g" /opt/xray/config.json && \
    sed -i "s/SHADOWSOCKS_PWD/$(head -3 /opt/xray/xray-creds.txt | tail -1)/g" /opt/xray/config.json && \
    sed -i "s/FAKE_DOMAIN/$(head -4 /opt/xray/xray-creds.txt | tail -1)/g" /opt/xray/config.json && \
    sed -i "s/PRIV_KEY/$(grep "Private key" /opt/xray/xray-creds.txt | cut -d " " -f 3)/g" /opt/xray/config.json

RUN echo "vless://$(head -n 1 /opt/xray/xray-creds.txt)@127.0.0.1:443?security=reality&sni=$(head -4 /opt/xray/xray-creds.txt | tail -1)&fp=chrome&pbk=$(grep "Public key" /opt/xray/xray-creds.txt | cut -d " " -f 3)&sid=$(head -2 /opt/xray/xray-creds.txt | tail -1)&type=tcp&flow=xtls-rprx-vision&encryption=none#$(echo $CLIENT_EMAIL | cut -d "@" -f 1)" > /opt/xray/vless-connection-string.txt

EXPOSE 23/tcp 23/udp 443/tcp

VOLUME ["/opt/xray"]

ENTRYPOINT ["/opt/xray/xray", "run", "-c", "/opt/xray/config.json"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /opt/xray/xray ping || exit 1
