{
  "name": "GCP Cloud Storage Bucket",
  "slug": "gcp-cloud-storage-bucket",
  "type": "dependency",
  "unique": false,
  "assignable_to": "any",
  "use_default_actions": true,
  "available_links": [],
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
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          { "type": "Control", "label": "Storage Class", "scope": "#/properties/storage_class" },
          { "type": "Control", "label": "Object Versioning", "scope": "#/properties/versioning" },
          { "type": "Control", "label": "Delete Even If Not Empty", "scope": "#/properties/force_destroy" },
          { "type": "Control", "label": "Bucket Name", "scope": "#/properties/bucket_name" },
          { "type": "Control", "label": "Bucket URL", "scope": "#/properties/bucket_url" }
        ]
      },
      "properties": {
        "storage_class": {
          "type": "string",
          "title": "Storage Class",
          "default": "STANDARD",
          "enum": ["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"],
          "description": "STANDARD for data read often; NEARLINE, COLDLINE and ARCHIVE cost less to keep and more to read.",
          "editableOn": ["create", "update"],
          "order": 1
        },
        "versioning": {
          "type": "boolean",
          "title": "Object Versioning",
          "default": false,
          "description": "Keep previous versions of overwritten or deleted objects.",
          "editableOn": ["create", "update"],
          "order": 2
        },
        "force_destroy": {
          "type": "boolean",
          "title": "Delete Even If Not Empty",
          "default": false,
          "description": "Off: deleting the service fails while the bucket holds objects. On: the delete removes the objects too.",
          "editableOn": ["create", "update"],
          "order": 3
        },
        "bucket_name": {
          "type": "string",
          "title": "Bucket Name",
          "export": { "type": "environment_variable", "target": "GCS_BUCKET_NAME", "secret": false },
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Globally unique name, derived from the service name (auto-populated, delivered as GCS_BUCKET_NAME)",
          "order": 4
        },
        "bucket_url": {
          "type": "string",
          "title": "Bucket URL",
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "gs://<bucket_name> (auto-populated)",
          "order": 5
        },
        "project_id": {
          "type": "string",
          "title": "Project",
          "export": { "type": "environment_variable", "target": "GCS_PROJECT_ID", "secret": false },
          "visibleOn": ["read"],
          "editableOn": [],
          "order": 6
        },
        "location": {
          "type": "string",
          "title": "Location",
          "visibleOn": ["read"],
          "editableOn": [],
          "order": 7
        }
      }
    },
    "values": {}
  }
}
