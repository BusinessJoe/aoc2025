{ inputs, pkgs, lib, config, ... }: 

let
  zig = import inputs.zig { 
    pkgs = pkgs; 
    system = "x86_64-linux";
  };
in {
  packages = [ 
    pkgs.git 
    pkgs.git-crypt
    zig."0.15.1"
  ];
  # languages.zig.enable = true;
  enterShell = "zig version"; 

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}

