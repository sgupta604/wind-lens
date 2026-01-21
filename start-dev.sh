#!/bin/bash
cd "$(dirname "$0")"
docker compose build
docker compose run --rm windlens-dev
