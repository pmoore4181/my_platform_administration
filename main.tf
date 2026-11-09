locals {
  config = yamldecode(file("${path.module}/config/platform_team_values.yaml"))

  repos = {
    for repos in local.config.github_repositories : repos.name => repos
  }

  base_files_skip_repos = ["platform_gitops"]

  base_files_repos = {
    for name, repo in local.repos : name => repo
    if !contains(local.base_files_skip_repos, name)
  }

  members = {
    for members in local.config.github_organization_members : members.username => members
  }
}

# Add all members to Org
resource "github_membership" "members" {
  for_each = local.members

  username = each.key
  role     = try(each.value.role, "member")
}

# Create all Repos
resource "github_repository" "repos" {
  for_each = local.repos

  name        = each.key
  description = try(each.value.description, "")
  visibility  = try(each.value.visibility, "private")

  auto_init          = true  # creates an initial commit so the default branch exists
  archive_on_destroy = true  # archive instead of deleting if removed from config
}

# Create basic required folder structure
resource "github_repository_file" "env_base_kustomization_yaml" {
  for_each = local.base_files_repos
  
  repository          = github_repository.repos[each.key].name
  branch              = github_repository.repos[each.key].default_branch
  file                = "environments/base/kustomization.yaml"
  content             = "# base kustomization.yaml"
  commit_message      = "chore(repos): add environments directory"
  overwrite_on_create = true
}

resource "github_repository_file" "env_sandbox_kustomization_yaml" {
  for_each = local.base_files_repos
  
  repository          = github_repository.repos[each.key].name
  branch              = github_repository.repos[each.key].default_branch
  file                = "environments/sandbox/kustomization.yaml"
  content             = "# sandbox kustomization.yaml"
  commit_message      = "chore(repos): add environments directory"
  overwrite_on_create = true
}