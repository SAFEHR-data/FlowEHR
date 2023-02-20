module "platform" {
  for_each = toset(["app1", "app2"])
  source   = "./platform"
  app_id   = each.key
}
