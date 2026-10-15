# S3 request metrics on the session recording bucket
# 1 minute granularity, PutRequests and 4xx/5xx errors
# (vs. less useful daily storage metrics of BucketSizeBytes and NumberOfObjects, which are indirect rather than direct evidence of issues)
# billed per metric - TODO: investigate cost
resource "aws_s3_bucket_metric" "sessions_requests" {
  bucket = data.aws_s3_bucket.sessions.id
  name   = "EntireBucket"
}
