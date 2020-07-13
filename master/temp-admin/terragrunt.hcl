include {
  path = find_in_parent_folders()
}
dependencies {
  paths = [
    "../organization"
  ]
}
remote_state {
  backend = "local"
  config = {
  }
}
