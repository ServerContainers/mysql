#!/bin/sh
sh -c 'sleep 1; echo exit' | telnet localhost 3306 2>/dev/null | grep mysql
exit $?
