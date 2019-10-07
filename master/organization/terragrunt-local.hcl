// should only be used by init.sh for the initial setup
include {
  path = find_in_parent_folders()
}
remote_state {
  backend = "local"
  config = {
  }
}
