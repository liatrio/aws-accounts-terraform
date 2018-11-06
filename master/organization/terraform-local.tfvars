// should only be used by init.sh for the initial setup
terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }
  remote_state {
    backend = "local"
  }
}
