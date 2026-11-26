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
          "description": "read lists and reads objects (roles/storage.objectViewer); write only creates them (roles/storage.objectCreator); read-write also overwrites and deletes them (roles/storage.objectUser). Granted on this bucket only, to the app's Kubernetes service account in the link's environment, np-<application id>-<environment> (Workload Identity; the scopes need IAM.MODE gke). Every scope of the app in that environment gets it, including scopes created later.",
          "editableOn": ["create", "update"],
          "order": 1
        },
        "path_prefix": {
          "type": "string",
          "title": "Path Prefix",
          "default": "",
          "pattern": "^([A-Za-z0-9._-][A-Za-z0-9._/-]{0,511})?$",
          "description": "Limit the access to objects whose name starts with this prefix, e.g. uploads/ (listing works when the request asks for that prefix). Empty: the whole bucket.",
          "editableOn": ["create", "update"],
          "order": 2
        },
        "granted_to": {
          "type": "array",
          "items": { "type": "string" },
          "title": "Granted To",
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Workload Identity principal that got the role: the app's service account in the link's environment (auto-populated)",
          "order": 3
        },
        "role": {
          "type": "string",
          "title": "Role",
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Role granted on the bucket (auto-populated)",
          "order": 4
        }
      }
    },
    "values": {}
  }
}
