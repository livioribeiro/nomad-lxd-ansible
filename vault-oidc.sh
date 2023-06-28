vault write auth/userpass/users/livio \
    password="password" \
    token_ttl="1h"

vault write identity/entity \
    name="livio" \
    disabled=false

ENTITY_ID=$(vault read -field=id identity/entity/name/livio)

vault write identity/group \
    name="admin" \
    member_entity_ids="$ENTITY_ID"

GROUP_ID=$(vault read -field=id identity/group/name/nomad-admin)

USERPASS_ACCESSOR=$(vault auth list -detailed -format json | jq -r '.["userpass/"].accessor')

vault write identity/entity-alias \
    name="livio" \
    canonical_id="$ENTITY_ID" \
    mount_accessor="$USERPASS_ACCESSOR"

vault write identity/oidc/assignment/livio-nomad-admin \
    entity_ids="${ENTITY_ID}" \
    group_ids="${GROUP_ID}"

vault write identity/oidc/key/nomad \
    allowed_client_ids="*" \
    verification_ttl="2h" \
    rotation_period="1h" \
    algorithm="RS256"

vault write identity/oidc/client/nomad \
    redirect_uris="http://localhost:4649/oidc/callback,https://nomad.10.99.0.1.nip.io/ui/settings/tokens" \
    key="nomad" \
    id_token_ttl="30m" \
    access_token_ttl="1h"

CLIENT_ID=$(vault read -field=client_id identity/oidc/client/nomad)

USER_SCOPE_TEMPLATE='{"username": {{identity.entity.name}}}'

vault write identity/oidc/scope/user \
    description="The user scope provides claims using Vault identity entity metadata" \
    template="$(echo ${USER_SCOPE_TEMPLATE} | base64 -)"

GROUPS_SCOPE_TEMPLATE='{"groups": {{identity.entity.groups.names}}}'

vault write identity/oidc/scope/groups \
    description="The groups scope provides the groups claim using Vault group membership" \
    template="$(echo ${GROUPS_SCOPE_TEMPLATE} | base64 -)"

vault write identity/oidc/provider/nomad \
    allowed_client_ids="${CLIENT_ID}" \
    scopes_supported="groups" \
    issuer="https://vault.10.99.0.1.nip.io"

# nomad

ISSUER=$(curl -s $VAULT_ADDR/v1/identity/oidc/provider/nomad/.well-known/openid-configuration | jq -r .issuer)
CLIENT_SECRET=$(vault read -field=client_secret identity/oidc/client/nomad)

cat > /tmp/nomad-policy.hcl <<EOT
namespace "*" {
  policy = "write"
}

node {
  policy = "write"
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

quota {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}

plugin {my_nomad_acl_policy
  policy = "read"
}
EOT

nomad acl policy apply admin /tmp/nomad-policy.hcl

nomad acl role create \
    -name=admin \
    -policy=admin

cat > /tmp/nomad-oidc.json <<EOT
{
  "OIDCDiscoveryURL": "https://vault.10.99.0.1.nip.io/v1/identity/oidc/provider/nomad",
  "OIDCClientID": "DnB8mchQjwVeYLEJWdA3Rg0fsO1MHEZB",
  "OIDCClientSecret": "hvo_secret_iSUIxNZ7FlpSJIzjiCyDHjc5mgwNwrUcpx4rMC6lQQkKq5jncDuTxegdUhtppaAP",
  "BoundAudiences": ["DnB8mchQjwVeYLEJWdA3Rg0fsO1MHEZB"],
  "OIDCScopes": ["groups"],
  "AllowedRedirectURIs": [
    "http://localhost:4649/oidc/callback",
    "http://nomad.10.99.0.1.nip.io/ui/settings/tokens",
    "https://nomad.10.99.0.1.nip.io/ui/settings/tokens"
  ],
  "ListClaimMappings": {
    "groups": "roles"
  }
}
EOT

nomad acl auth-method create \
    -default=true \
    -name=vault \
    -token-locality=global \
    -max-token-ttl="10m" \
    -type=oidc \
    -config @/tmp/nomad-oidc.json

nomad acl binding-rule create \
    -auth-method=vault \
    -bind-type=role \
    -bind-name="admin" \
    -selector="admin in list.roles"






cat > /tmp/sso-oidc.json <<EOT
{
  "OIDCDiscoveryURL": "https://sso.apps.10.99.0.1.nip.io/realms/nomad",
  "OIDCClientID": "nomad",
  "OIDCClientSecret": "oSSrSnrgrnXN8kUyLmlL7FneKHDU3HH4",
  "BoundAudiences": ["nomad"],
  "OIDCScopes": ["groups"],
  "AllowedRedirectURIs": [
    "http://localhost:4649/oidc/callback",
    "http://nomad.10.99.0.1.nip.io/ui/settings/tokens",
    "https://nomad.10.99.0.1.nip.io/ui/settings/tokens"
  ],
  "ListClaimMappings": {
    "groups": "roles"
  }
}
EOT

nomad acl auth-method create \
    -default=false \
    -name=sso \
    -token-locality=global \
    -max-token-ttl="10m" \
    -type=oidc \
    -config @/tmp/sso-oidc.json

nomad acl binding-rule create \
    -auth-method=sso \
    -bind-type=role \
    -bind-name="admin" \
    -selector="admin in list.roles"


# nomad policy operator
cat > /tmp/nomad-policy-operator.hcl <<EOT
namespace "system-*" {
  policy = "read"
}

namespace "*" {
  policy = "write"
}

node {
  policy = "read"
}
EOT

nomad acl policy apply operator /tmp/nomad-policy-operator.hcl

nomad acl role create \
    -name=operator \
    -policy=operator

nomad acl binding-rule create \
    -auth-method=vault \
    -bind-type=role \
    -bind-name="operator" \
    -selector="operator in list.roles"