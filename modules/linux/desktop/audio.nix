# modules/linux/desktop/audio.nix — 桌面音频（PipeWire + WirePlumber + Intel SOF 固件）
#
# 桌面专属：server 不需要音频，故从 modules/linux/base.nix 上移至此。
{ pkgs, ... }:
{
  # ==================== 音频：PipeWire + WirePlumber ====================
  # 服务映射（随 services.pipewire 自动启用，并以 user 服务默认启动）：
  #   enable       → pipewire.service + wireplumber.service（wireplumber 随 pipewire 拉起）
  #   pulse.enable → pipewire-pulse.service（PulseAudio 兼容）
  #   alsa.enable  → pipewire-alsa（ALSA 集成）
  #   jack.enable  → pipewire-jack（JACK 集成）
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Intel SOF / ALSA 固件与 UCM 配置（NUC8 等 Intel 音频需要）
  environment.systemPackages = with pkgs; [
    sof-firmware
    alsa-ucm-conf
    alsa-firmware
  ];
}
