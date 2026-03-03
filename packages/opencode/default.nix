{opencode}:
opencode.overrideAttrs (old: {
  preBuild =
    (old.preBuild or "")
    + ''
      mkdir -p .github
      touch .github/TEAM_MEMBERS
    '';
})
