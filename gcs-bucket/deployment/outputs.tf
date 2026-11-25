output "bucket_name" {
  value = google_storage_bucket.this.name
}

output "bucket_url" {
  value = google_storage_bucket.this.url
}

output "project_id" {
  value = google_storage_bucket.this.project
}

output "location" {
  value = google_storage_bucket.this.location
}
