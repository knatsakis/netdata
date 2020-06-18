#!/usr/bin/env bash
#
# Entry point script for netdata
#
# Copyright: SPDX-License-Identifier: GPL-3.0-or-later
#
# Author  : Pavlos Emm. Katsoulakis <paul@netdata.cloud>
install -m 0770 -o netdata -g netdata -d /var/lib/netdata/registry
uuidgen --sha1 --namespace @dns --name $HOSTNAME > /var/lib/netdata/registry/netdata.public.unique.id

chmod 0670 /var/lib/netdata/registry/netdata.public.unique.id
chown netdata:netdata /var/lib/netdata/registry/netdata.public.unique.id

/usr/sbin/netdata-claim.sh -token="${CLAIM_TOKEN}" -rooms="${CLAIM_ROOM}" -url="${ACLK_URL}"

chown -R netdata:netdata /etc/netdata/claim.d

if [ ! "${DO_NOT_TRACK:-0}" -eq 0 ] || [ -n "$DO_NOT_TRACK" ]; then
  touch /etc/netdata/.opt-out-from-anonymous-statistics
fi

echo "Netdata entrypoint script starting"
if [ ${RESCRAMBLE+x} ]; then
  echo "Reinstalling all packages to get the latest Polymorphic Linux scramble"
  apk upgrade --update-cache --available
fi

if [ -n "${PGID}" ]; then
  echo "Creating docker group ${PGID}"
  addgroup -g "${PGID}" "docker" || echo >&2 "Could not add group docker with ID ${PGID}, its already there probably"
  echo "Assign netdata user to docker group ${PGID}"
  usermod -a -G "${PGID}" "${DOCKER_USR}" || echo >&2 "Could not add netdata user to group docker with ID ${PGID}"
fi

exec /usr/sbin/netdata -u "${DOCKER_USR}" -D -s /host -p "${NETDATA_PORT}" -W set cloud "cloud base url" ${ACLK_URL} -W set global "errors flood protection period" 0 -W set web "web files group" root -W set web "web files owner" root "$@"

echo "Netdata entrypoint script, completed!"
