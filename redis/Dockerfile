FROM redis:6.0.6-alpine
RUN sysctl vm.overcommit_memory=1
RUN sysctl -w net.core.somaxconn=512
