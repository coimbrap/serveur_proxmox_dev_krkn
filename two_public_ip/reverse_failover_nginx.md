# Template reverse proxy avec Failover NGINX

```
upstream <nom_service> {
    server <ip_service_ct_principal>:443 fail_timeout=60s max_fails=1;
    server <ip_service_ct_backup>:443 backup;
}
```