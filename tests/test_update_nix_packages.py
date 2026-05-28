import importlib.util
import pathlib
import tempfile
import textwrap
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "update-nix-packages.py"

spec = importlib.util.spec_from_file_location("update_nix_packages", SCRIPT)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


def release(tag, assets):
    return {
        "tag_name": tag,
        "draft": False,
        "prerelease": False,
        "assets": [
            {
                "name": name,
                "digest": digest,
                "browser_download_url": f"https://example.invalid/{name}",
            }
            for name, digest in assets.items()
        ],
    }


class UpdateNixPackagesTests(unittest.TestCase):
    def test_sri_from_github_sha256_digest(self):
        digest = "sha256:" + ("00" * 32)

        self.assertEqual(
            updater.sri_from_digest(digest),
            "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        )

    def test_jcode_update_keeps_nix_asset_name_and_updates_hash(self):
        with tempfile.TemporaryDirectory() as tmp:
            package_file = pathlib.Path(tmp) / "jcode.nix"
            package_file.write_text(
                textwrap.dedent(
                    """
                    {
                      version = "0.14.3";

                      sources = {
                        aarch64-darwin = {
                          asset = "jcode-macos-aarch64";
                          hash = "sha256-oldA=";
                        };

                        x86_64-linux = {
                          asset = "jcode-linux-x86_64";
                          hash = "sha256-oldB=";
                        };
                      };
                    }
                    """
                ),
                encoding="utf-8",
            )
            package_spec = {
                "versionPrefix": "v",
                "systems": {
                    "aarch64-darwin": {
                        "nixAsset": "jcode-macos-aarch64",
                        "releaseAsset": "jcode-macos-aarch64.tar.gz",
                    },
                    "x86_64-linux": {
                        "nixAsset": "jcode-linux-x86_64",
                        "releaseAsset": "jcode-linux-x86_64.tar.gz",
                    },
                },
            }
            latest = release(
                "v0.14.4",
                {
                    "jcode-macos-aarch64.tar.gz": "sha256:" + ("01" * 32),
                    "jcode-linux-x86_64.tar.gz": "sha256:" + ("02" * 32),
                },
            )

            plan = updater.plan_update("jcode", package_spec, package_file, latest)

            self.assertTrue(plan.changed)
            self.assertEqual(plan.current_version, "0.14.3")
            self.assertEqual(plan.latest_version, "0.14.4")
            self.assertIn('version = "0.14.4";', plan.new_text)
            self.assertIn('asset = "jcode-macos-aarch64";', plan.new_text)
            self.assertIn(
                'hash = "sha256-AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=";',
                plan.new_text,
            )

    def test_cliproxyapi_update_rewrites_versioned_asset_names(self):
        with tempfile.TemporaryDirectory() as tmp:
            package_file = pathlib.Path(tmp) / "cliproxyapi.nix"
            package_file.write_text(
                textwrap.dedent(
                    """
                    {
                      version = "7.1.24";

                      sources = {
                        aarch64-darwin = {
                          asset = "CLIProxyAPI_7.1.24_darwin_aarch64.tar.gz";
                          hash = "sha256-oldA=";
                        };
                      };
                    }
                    """
                ),
                encoding="utf-8",
            )
            package_spec = {
                "versionPrefix": "v",
                "systems": {
                    "aarch64-darwin": {
                        "nixAsset": "CLIProxyAPI_{version}_darwin_aarch64.tar.gz",
                        "releaseAsset": "CLIProxyAPI_{version}_darwin_aarch64.tar.gz",
                    },
                },
            }
            latest = release(
                "v7.1.25",
                {
                    "CLIProxyAPI_7.1.25_darwin_aarch64.tar.gz": "sha256:"
                    + ("03" * 32),
                },
            )

            plan = updater.plan_update(
                "cliproxyapi", package_spec, package_file, latest
            )

            self.assertTrue(plan.changed)
            self.assertIn('version = "7.1.25";', plan.new_text)
            self.assertIn(
                'asset = "CLIProxyAPI_7.1.25_darwin_aarch64.tar.gz";',
                plan.new_text,
            )
            self.assertIn(
                'hash = "sha256-AwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM=";',
                plan.new_text,
            )

    def test_missing_release_asset_is_reported_with_package_and_system(self):
        with tempfile.TemporaryDirectory() as tmp:
            package_file = pathlib.Path(tmp) / "jcode.nix"
            package_file.write_text(
                textwrap.dedent(
                    """
                    {
                      version = "0.14.3";

                      sources = {
                        aarch64-darwin = {
                          asset = "jcode-macos-aarch64";
                          hash = "sha256-oldA=";
                        };
                      };
                    }
                    """
                ),
                encoding="utf-8",
            )
            package_spec = {
                "versionPrefix": "v",
                "systems": {
                    "aarch64-darwin": {
                        "nixAsset": "jcode-macos-aarch64",
                        "releaseAsset": "jcode-macos-aarch64.tar.gz",
                    },
                },
            }

            with self.assertRaisesRegex(
                updater.UpdateError,
                "jcode.*aarch64-darwin.*jcode-macos-aarch64.tar.gz",
            ):
                updater.plan_update(
                    "jcode",
                    package_spec,
                    package_file,
                    release("v0.14.4", {}),
                )


if __name__ == "__main__":
    unittest.main()
