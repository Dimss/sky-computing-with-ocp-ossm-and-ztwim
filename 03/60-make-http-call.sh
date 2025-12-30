source "$(dirname "$0")/01-define-exports.sh"
# this sleep should ensure that applied
# in previous step PeerAuthentication and DestinationRule CRs
# has been propagated and now enforced by the sidecar
sleep 5
source "$(dirname "$0")/40-make-http-call.sh"

