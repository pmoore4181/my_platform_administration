locals {
  config = yamldecode(file("${path.module}/config/platform_team_values.yaml"))

  repos = {
    for repos in local.config.github_repositories : repos.name => repos
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