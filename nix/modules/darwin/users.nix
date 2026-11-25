{ username, ... }:
{
  users.users.${username}.home = "/Users/${username}";

  system.primaryUser = username;
}
