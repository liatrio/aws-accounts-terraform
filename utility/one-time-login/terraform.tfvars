terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }
  remote_state {
    backend = "local"
  }
}
