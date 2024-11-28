FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y
RUN apt-get install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

ENV HOME=/app

WORKDIR /app

ENV MONIKER="StakeShark"
ENV ARTELA_CHAIN_ID="artela_11822-1"
ENV ARTELA_PORT="30"
ENV GO_VER="1.22.3"
ENV PATH="/usr/local/go/bin:/app/go/bin:${PATH}"
ENV WALLET="wallet"
ENV SEEDS="8d0c626443a970034dc12df960ae1b1012ccd96a@artela-testnet-seed.itrocket.net:30656"
ENV PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,e0c08d7623b2a0dc5d37e01e201055c00fff6b9d@5.189.162.179:45656,5587fc6a4cff834889e5affcb3d8eaad081b9e00@94.16.31.24:3456,9f29f4650810677a60b59a8fd363a58e4265ce50@91.230.110.117:26656,866cdfa0596fc40b14b0817f7ed3497c6a17f397@162.55.65.137:15856,60d4977008644f80bd7ea2961ca1c66894ffbd15@5.189.162.161:26656,4866a0d0ada3995058d36c2c1da1af22c5bc52e6@85.190.246.221:3456,24c6dc1031a364336f557d9179fc1fd4ed20a283@45.92.9.164:3456,a90dc6bfc3caf47344173971dcac67401a6dca43@185.246.87.105:13056,e206ede4368eb16962e7fdeda3a1af5a9e2378e5@37.60.224.47:3456,55e03f7dab4288c3dc3e93257f4e063c862f0561@109.199.124.254:26656,ecb580bc54b7f14618d54ccf263b9b6baff1e2d8@89.58.53.98:26656,f98c45802e0e756f3e5e06e6cd3259e03182b44a@75.119.154.23:26656,2f3b9357487f5bc603b36099e583d4fb22e8a065@156.67.31.31:23456,0f5a4ad942c2bb222362e7cb92f11f0f474a0f6d@45.136.17.29:3456,64af6870f342899bfc475da28ce4bb16b0e62f23@161.97.151.149:3456,a08fd83e62646deb0ea95456fab4d6c3614c80f9@109.199.105.155:30656,844377056c31f227cfb0759c29df9f239c284386@209.145.48.72:45656,5c4ea81ac7b8a7f5202fcbe5fe790a6d6f61fb22@47.251.14.108:26656,8889b28795e8be109a532464e5cc074e113de780@47.251.54.123:26656,0172eec239bb213164472ea5cbd96bf07f27d9f2@47.251.14.47:26656"

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

RUN git clone https://github.com/artela-network/artela && \
cd artela && \
git checkout main && \
make install

RUN artelad config node tcp://localhost:${ARTELA_PORT}657 && \
artelad config keyring-backend os && \
artelad config chain-id artela_11822-1 && \
artelad init "StakeShark" --chain-id artela_11822-1

RUN sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.artelad/config/config.toml && \
sed -i.bak -e "s%:1317%:${ARTELA_PORT}317%g; \
s%:8080%:${ARTELA_PORT}080%g; \
s%:9090%:${ARTELA_PORT}090%g; \
s%:9091%:${ARTELA_PORT}091%g; \
s%:8545%:${ARTELA_PORT}545%g; \
s%:8546%:${ARTELA_PORT}546%g; \
s%:6065%:${ARTELA_PORT}065%g" $HOME/.artelad/config/app.toml && \
sed -i.bak -e "s%:26658%:${ARTELA_PORT}658%g; \
s%:26657%:${ARTELA_PORT}657%g; \
s%:6060%:${ARTELA_PORT}060%g; \
s%:26656%:${ARTELA_PORT}656%g; \
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ARTELA_PORT}656\"%; \
s%:26660%:${ARTELA_PORT}660%g" $HOME/.artelad/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.artelad/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.artelad/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.artelad/config/app.toml && \
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.025art"|g' $HOME/.artelad/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.artelad/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.artelad/config/config.toml

RUN wget -O $HOME/.artelad/config/genesis.json https://server-4.itrocket.net/testnet/artela/genesis.json && \
wget -O $HOME/.artelad/config/addrbook.json  https://server-4.itrocket.net/testnet/artela/addrbook.json


RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
