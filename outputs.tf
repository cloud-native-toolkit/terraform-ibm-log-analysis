output "sync" {
  value = "logdna"
  depends_on = [helm_release.logdna]
}
