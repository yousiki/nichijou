{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) bash fetchurl lib stdenvNoCC;

  version = "3.3.23";

  sources = {
    aarch64-darwin = {
      asset = "aliyun-cli-macosx-3.3.23-arm64.tgz";
      hash = "sha256-uWBC7k5n2c/DQE7jZRbdflbyCvP+EW8gtILAfsSupfk=";
    };

    x86_64-darwin = {
      asset = "aliyun-cli-macosx-3.3.23-amd64.tgz";
      hash = "sha256-Vt1x0UA8xuwqX9iAg67m2ARM4hK5q3+EHCnVU/Lt2o4=";
    };

    x86_64-linux = {
      asset = "aliyun-cli-linux-3.3.23-amd64.tgz";
      hash = "sha256-s5XTMQkvGV9TQlrtgH4XM0aZa8GpgR+uzVUm7IC1fCY=";
    };

    aarch64-linux = {
      asset = "aliyun-cli-linux-3.3.23-arm64.tgz";
      hash = "sha256-azniAZiPB4/daKIgiSu5D5HlNe3hXb+toxx+q0UDaRY=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "aliyun-cli is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/aliyun/aliyun-cli/releases/download/v${version}/${source.asset}";
      inherit (source) hash;
    };

    sourceRoot = ".";

    dontBuild = true;

    installPhase = ''
            runHook preInstall

            install -D -m755 aliyun "$out/libexec/aliyun-cli/aliyun"

            mkdir -p "$out/bin"
            cat > "$out/bin/aliyun" <<'EOF'
      #!${lib.getExe bash}
      set -euo pipefail

      real_binary="@real_binary@"
      positionals=()
      skip_next=0
      end_of_options=0

      flag_takes_value() {
        case "$1" in
          --profile|-p|--mode|--access-key-id|--access-key-secret|--sts-token|--sts-region|\
          --ram-role-name|--ram-role-arn|--role-session-name|--external-id|--source-profile|\
          --private-key|--key-pair-name|--region|--RegionId|--language|--read-timeout|\
          --connect-timeout|--retry-count|--config-path|--expired-seconds|--process-command|\
          --oidc-provider-arn|--oidc-token-file|--cloud-sso-sign-in-url|--cloud-sso-access-config|\
          --cloud-sso-account-id|--oauth-site-type|--endpoint-type|--endpoint|--external-account-type|\
          --auto-plugin-install|--auto-plugin-install-enable-pre|--bearer-token|--bearer-token-header-key|\
          --version|--header|--body|--body-file|--accept|--roa|--pager|--waiter|--cli-query|\
          --output|--method|--user-agent)
            return 0
            ;;
          *)
            return 1
            ;;
        esac
      }

      for arg in "$@"; do
        if [ "$skip_next" -eq 1 ]; then
          skip_next=0
          continue
        fi

        if [ "$end_of_options" -eq 0 ]; then
          case "$arg" in
            --)
              end_of_options=1
              continue
              ;;
            --*=*|--*:*)
              continue
              ;;
            --*)
              if flag_takes_value "$arg"; then
                skip_next=1
              fi
              continue
              ;;
            -p)
              skip_next=1
              continue
              ;;
            -*)
              continue
              ;;
          esac
        fi

        positionals+=("$arg")
        if [ "''${#positionals[@]}" -ge 2 ]; then
          break
        fi
      done

      if [ "''${#positionals[@]}" -ge 2 ]; then
        operation="''${positionals[1]}"
        case "$operation" in
          GET|POST|PUT|DELETE|HEAD|PATCH|OPTIONS)
            ;;
          *[A-Z]*)
            suggestion=""
            previous=""
            for ((i = 0; i < ''${#operation}; i++)); do
              char="''${operation:i:1}"
              if [ "$i" -gt 0 ] && [ "$previous" != "-" ] && [[ "$char" == [A-Z] ]]; then
                suggestion+="-"
              fi
              suggestion+="''${char,,}"
              previous="$char"
            done
            printf "ERROR: legacy uppercase API operation '%s' is disabled by this Nix package. Use the plugin-style kebab-case subcommand '%s' instead.\n" "$operation" "$suggestion" >&2
            exit 2
            ;;
        esac
      fi

      exec "$real_binary" "$@"
      EOF
            substituteInPlace "$out/bin/aliyun" \
              --replace-fail "@real_binary@" "$out/libexec/aliyun-cli/aliyun"
            chmod 755 "$out/bin/aliyun"

            runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      test -x "$out/bin/aliyun"
      test -x "$out/libexec/aliyun-cli/aliyun"

      set +e
      output=$("$out/bin/aliyun" resource-manager ListResources 2>&1)
      status=$?
      set -e
      test "$status" -eq 2
      echo "$output" | grep -F "uppercase API operation 'ListResources' is disabled"
      echo "$output" | grep -F "list-resources"

      set +e
      output=$("$out/bin/aliyun" resource-manager Foo-Bar 2>&1)
      status=$?
      set -e
      test "$status" -eq 2
      echo "$output" | grep -F "uppercase API operation 'Foo-Bar' is disabled"
      echo "$output" | grep -F "foo-bar"

      runHook postInstallCheck
    '';

    meta = {
      description = "Tool to manage and use Alibaba Cloud resources through a command line interface";
      homepage = "https://github.com/aliyun/aliyun-cli";
      changelog = "https://github.com/aliyun/aliyun-cli/releases/tag/v${version}";
      license = lib.licenses.asl20;
      mainProgram = "aliyun";
      platforms = builtins.attrNames sources;
    };
  }
