FROM bitwalker/alpine-elixir:1.8.0 as build

COPY . .

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

#Extract Release archive to /rel for copying in next stage
RUN APP_NAME="kaffelistener" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

#================
#Deployment Stage
#================
FROM bitwalker/alpine-erlang:21

#Copy and extract .tar.gz Release file from the previous stage
COPY --from=build /export/ .

ENV MIX_ENV=prod

#Change user
USER default

#Set default entrypoint and command
ENTRYPOINT ["/opt/app/bin/kaffelistener"]
CMD ["foreground"]