#!/bin/bash

exec sudo docker run --rm -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest

