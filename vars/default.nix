# vars/default.nix — 全局用户数据定义（NixOS 模块）
#
# 🌟 这是用户身份的「唯一定义处」。
# hosts/<hostname>/ 只通过 mySystem.user 指定用哪个用户，不定义用户细节。
#
# 如果未来有多用户，扩展为 attrset map：
#   users.beta.fullName = "Beta";
#   users.other.fullName = "Other";
{ ... }:
{
  myHome = {
    userFullName = "Beta";
    userEmail = "";  # ⚠️ 请替换为真实邮箱（Git commit 签名需要）
  };
}
