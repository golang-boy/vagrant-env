docker pull dperson/openvpn-client:latest

scp vagrant@192.168.56.3:/home/vagrant/ovpn-data/clients/engine.ovpn .
docker run -it --cap-add=NET_ADMIN --device /dev/net/tun --name vpn  -v  `pwd`:/vpn -d dperson/openvpn-client