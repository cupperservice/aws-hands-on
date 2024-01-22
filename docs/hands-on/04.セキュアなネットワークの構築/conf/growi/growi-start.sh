#!/bin/sh
cd /opt/growi
MONGO_URI=mongodb://<mongodb>:27017/growi \
PASSWORD_SEED="`openssl rand -base64 128 | head -1`" \
npm start
