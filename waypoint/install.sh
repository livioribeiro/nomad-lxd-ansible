waypoint install \
    -accept-tos \
    -platform=nomad \
    -nomad-host=http://nomad.service.consul:4646 \
    -nomad-dc=apps \
    -nomad-runner-csi-volume-provider=dev.rocketduck.csi.nfs \
    -nomad-csi-volume-provider=dev.rocketduck.csi.nfs \
    -nomad-csi-plugin-id=nfs \
    -nomad-csi-fs=ext4