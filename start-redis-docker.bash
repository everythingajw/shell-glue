#!/bin/bash

exec sudo docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest

