# cacheck
Check certificates expiration date\
By recursive search of files "*.cert.pem" inside specific directory\
With mattermost notification, optionally\
For example
```
./cacheck.bash -p /path/to/certificates -v
```
Crontab string example
```
0 7 * * 1 bash -c '/root/CA/cacheck.bash -p "/root/CA" -m "http://192.168.192.168:8080/hooks/g1p2123ybssfqcsdf7fsfffbc"' >> /var/log/cacheck.bash.log 2>&1
```
