This space is to emulate the deployment stack at Alembic Technologies and learn from it.

IMPORTANT: 'multiPass set local.passphrase' does NOT work on Apple M1 silicon. Better to directly inject client certs to the daemon.

Direct injection of multiPass client certificate to multipass dameon is like so:

sudo cp ~/Library/Application\ Support/multipass-client-certificate/multipass_cert.pem \
  /var/root/Library/Application\ Support/multipassd/authenticated-certs/multipass_client_certs.pem

Then restart multipass dameon:

sudo launchctl kickstart -k system/com.canonical.multipassd
