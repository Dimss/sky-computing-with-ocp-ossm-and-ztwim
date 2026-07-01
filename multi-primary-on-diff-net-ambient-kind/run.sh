./10-create-kind-clusters.sh
./20-create-certs.sh
read -n 1 -s -r -p $'----> run the sudo cloud-provider-kind --enable-default-ingress=false and press any key to continue\n'
./.30-install-istio.sh
./40-create-remote-secrets.sh
./50-install-app.sh
./60-install-gateway.sh
#./80_enable_waypoint.sh
#./70_verify.sh
