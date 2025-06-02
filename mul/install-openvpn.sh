docker pull kylemanna/openvpn:latest

docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://192.168.56.3:1194