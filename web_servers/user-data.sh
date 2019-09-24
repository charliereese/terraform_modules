#!/bin/bash

<<EOF
export APPLICATION_NAME=${application_name}
export DB_HOST=${db_address}
export DB_USERNAME=${db_username}
export RAILS_ENV=production
EOF

# Set DB environment variables in docker container and
# start rails container

<<EOF
sudo docker container run -p 3000:3000 --name ${application_name} --restart always -d \
-e DB_HOST=${db_address} \
-e DB_USERNAME=${db_username} \
-e RAILS_ENV='production' \
$DOCKERHUB_USERNAME/${application_name}:latest
EOF

# Run outstanding DB migrations
<<EOF
docker container exec ${application_name} RAILS_ENV=production rake db:migrate
EOF