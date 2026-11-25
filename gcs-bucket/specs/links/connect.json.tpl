{
  "name": "Connect",
  "slug": "connect",
  "unique": false,
  "assignable_to": "any",
  "use_default_actions": true,
  "selectors": {
    "category": "Storage",
    "imported": false,
    "provider": "GCP",
    "sub_category": "Object Storage"
  },
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [],
      "properties": {
        "access_level": {
          "type": "string",
          "title": "Access Level",
          "default": "read-write",
          "enum": ["read", "write", "read-write"],
          "description": "read lists and reads objects (roles/storage.objectViewer); write only creates them (roles/storage.objectCreator); read-write also overwrites and deletes them (roles/storage.objectUser). Granted on this bucket only, to the Kubernetes service account of each scope of the app (Workload Identity; the scopes need IAM.MODE gke).",
          "editableOn": ["create", "update"],
          "order": 1
        },
        "granted_to": {
          "type": "array",
          "items": { "type": "string" },
          "title": "Granted To",
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Workload Identity principals that got the role, one per scope (auto-populated; updating the link picks up scopes created after it)",
          "order": 2
        },
        "role": {
          "type": "string",
          "title": "Role",
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Role granted on the bucket (auto-populated)",
          "order": 3
        }
      }
    },
    "values": {}
  }
}
