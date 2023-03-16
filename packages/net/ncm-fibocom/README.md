# OpenWrt scripts to configure connection Fibocom L860-GL
Intel XMM 7650 LTE-A Pro modem

# How-to configure cellular connection
The config stored in /etc/config/network. Example configuration:
```
config interface 'xmm0'
  option proto 'intel_ncm'
  option device '/dev/ttyACM0'
  option apn 'internet'	
```