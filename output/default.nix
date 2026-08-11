# output/default.nix — Flake outputs 聚合分发入口
inputs:

let
  inherit (inputs.nixpkgs) lib;

  # 当前支持的架构列表
  allSystems = [
    "x86_64-linux"
    "aarch64-darwin"
    "aarch64-linux"
  ];

  # 遍历所有架构执行函数
  forAllSystems = f: lib.genAttrs allSystems (system: f system);
in
{
  # ==================== NixOS 主机构建 ====================
  nixosConfigurations =
    ((import ./X86_64-linux) inputs) //
    # 未来:
    # (import ./Aarch64-linux inputs)   # ARM 主机（如 armbian NAS）
    { };

  # ==================== 未来扩展 ====================
  # darwinConfigurations = import ./aarch64-darwin inputs;
  # homeConfigurations = import ./home-standalone inputs;

  # 辅助：devShells、formatter 等
  devShells = forAllSystems (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      default = pkgs.mkShell {
        packages = with pkgs; [
          nil     # Nix LSP
          nixfmt-rfc-style
        ];
      };
    }
  );

  formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
}
