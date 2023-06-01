#set env vars
#set -o allexport; source .env; set +o allexport;


mkdir -p ./superset_home
chown -R 1000:1000 ./superset_home
