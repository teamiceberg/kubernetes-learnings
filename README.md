This space is to emulate the deployment stack at Alembic Technologies and learn from it.

MultiPass set local.passphrase does NOT work on Mac OS. Better to directly inject client certs to the daemon.

MultiPass client certificate injection directly to multipass dameon is like so:

sudo cp ~/Library/Application\ Support/multipass-client-certificate/multipass_cert.pem \
  /var/root/Library/Application\ Support/multipassd/authenticated-certs/multipass_client_certs.pem

Then restart multipass dameon:

sudo launchctl kickstart -k system/com.canonical.multipassd
