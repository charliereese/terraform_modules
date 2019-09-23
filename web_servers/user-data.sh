#!/bin/bash

# Set DB environment variables in docker container and
# start rails container
sudo docker container run -p 3000:3000 --name ${application_name} --restart always -d \
-e DB_HOST=${db_address} \
-e DB_USERNAME=${db_username} \
-e RAILS_ENV='production' \
$DOCKERHUB_USERNAME/${application_name}:latest

# Run outstanding DB migrations
docker container exec ${application_name} RAILS_ENV=production rake db:migrate