#!/bin/bash

DEVICE_ID=${1:-chrome}

if ! systemctl is-active --quiet postgresql; then
    echo "Starting PostgreSQL..."
    sudo systemctl start postgresql
else
    echo "PostgreSQL is already running."
fi

echo "Starting Backend..."
(cd backend && npm install && npm start) &
BACKEND_PID=$!

echo "Starting Flutter App on: $DEVICE_ID..."
(cd mobile/flutter_app && flutter run -v -d "$DEVICE_ID") &
FLUTTER_PID=$!

cleanup()
{
  echo -e "\nShutting down Qrono... 👋"
  kill $BACKEND_PID
  kill $FLUTTER_PID
  sleep 1
  exit
}

trap cleanup SIGINT

wait $FLUTTER_PID
echo "[LOG] Flutter session has ended. Cleaning up backend..."
cleanup

