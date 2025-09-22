

services:
app:
image: ghcr.io/your/app:latest
networks:
- proxy_net

networks:
proxy_net:
external: true