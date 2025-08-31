This space is to emulate the deployment stack at Alembic Technologies and learn from it.

IMPORTANT: 'multiPass set local.passphrase' does NOT work on Apple M1 silicon. Better to directly inject client certs to the daemon.
Also, the bridge networking that multipass has configured on QEMU is buggy. Use UTM (also layered on QEMU) for a better virtuaization
of Ubuntu VMs with full control over hst's bridge network for the initiated Apple M-series VMs.

Direct injection of multiPass client certificate to multipass dameon is like so:

sudo cp ~/Library/Application\ Support/multipass-client-certificate/multipass_cert.pem \
  /var/root/Library/Application\ Support/multipassd/authenticated-certs/multipass_client_certs.pem

Then restart multipass dameon:

sudo launchctl kickstart -k system/com.canonical.multipassd

IMPORTANT: When scripting, an interesting thing to figure out is how to capture the IP assigned to each VM spun up by multipass through a dhcp from the host's subnet. There are no built-in ENV VARS that pass this ip.  

test-busybox pod version has to be 1.28 to validate nslookup and other internal pod tests