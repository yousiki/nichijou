import importlib.util
import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "sync-cloudflare-warp-excludes.py"

spec = importlib.util.spec_from_file_location("sync_cloudflare_warp_excludes", SCRIPT)
syncer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(syncer)


def entry_set(entries):
    return {(entry.entry_type, entry.value, entry.description) for entry in entries}


class EntryGenerationTests(unittest.TestCase):
    def test_github_domains_are_flattened_and_static_fallbacks_are_added(self):
        meta = {
            "domains": {
                "website": ["GitHub.com", "*.GitHub.com"],
                "raw": ["raw.githubusercontent.com"],
                "nested": {"assets": ["*.githubassets.com"]},
            },
            "web": ["192.30.252.0/22"],
            "api": ["140.82.112.0/20"],
            "git": ["192.30.255.112/32"],
            "packages": ["140.82.121.33/32"],
            "actions": ["10.0.0.0/8"],
        }

        entries = syncer.build_github_entries(meta, include_ips=False)

        self.assertIn(
            ("host", "github.com", "managed:github:static:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "*.github.com", "managed:github:static:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "raw.githubusercontent.com", "managed:github:meta:host"),
            entry_set(entries),
        )
        self.assertNotIn(
            ("address", "192.30.252.0/22", "managed:github:meta:cidr"),
            entry_set(entries),
        )

    def test_github_ip_expansion_uses_selected_meta_categories_only(self):
        meta = {
            "domains": [],
            "web": ["192.30.252.0/22"],
            "api": ["140.82.112.0/20"],
            "git": ["192.30.255.112/32"],
            "packages": ["140.82.121.33"],
            "actions": ["10.0.0.0/8"],
        }

        entries = syncer.build_github_entries(meta, include_ips=True)

        self.assertIn(
            ("address", "192.30.252.0/22", "managed:github:meta:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("address", "140.82.121.33/32", "managed:github:meta:cidr"),
            entry_set(entries),
        )
        self.assertNotIn(
            ("address", "10.0.0.0/8", "managed:github:meta:cidr"),
            entry_set(entries),
        )

    def test_tailscale_entries_include_reserved_ranges_control_hosts_and_derp_hosts(self):
        derp_map = {
            "Regions": {
                "1": {
                    "Nodes": [
                        {
                            "Name": "1a",
                            "HostName": "derp1.tailscale.com",
                            "IPv4": "203.0.113.1",
                        }
                    ]
                },
                "2": {
                    "Nodes": [
                        {
                            "Name": "2a",
                            "HostName": "derp2.tailscale.com",
                            "IPv6": "2001:db8::1",
                        }
                    ]
                },
            }
        }

        entries = syncer.build_tailscale_entries(derp_map, include_derp_ips=False)

        self.assertIn(
            ("address", "100.64.0.0/10", "managed:tailscale:reserved:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("address", "fd7a:115c:a1e0::/48", "managed:tailscale:reserved:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "controlplane.tailscale.com", "managed:tailscale:firewall:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "*.ts.net", "managed:tailscale:firewall:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "derp1.tailscale.com", "managed:tailscale:derpmap:host"),
            entry_set(entries),
        )
        self.assertNotIn(
            ("address", "203.0.113.1/32", "managed:tailscale:derpmap:cidr"),
            entry_set(entries),
        )

    def test_tailscale_derp_ip_expansion_is_explicit(self):
        derp_map = {
            "Regions": {
                "1": {
                    "Nodes": [
                        {
                            "HostName": "derp1.tailscale.com",
                            "IPv4": "203.0.113.1",
                            "IPv6": "2001:db8::1",
                        }
                    ]
                }
            }
        }

        entries = syncer.build_tailscale_entries(derp_map, include_derp_ips=True)

        self.assertIn(
            ("address", "203.0.113.1/32", "managed:tailscale:derpmap:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("address", "2001:db8::1/128", "managed:tailscale:derpmap:cidr"),
            entry_set(entries),
        )


class PlanningTests(unittest.TestCase):
    def test_calculate_plan_preserves_unmanaged_entries_and_removes_only_managed_stale_entries(self):
        remote = [
            {"address": "10.0.0.0/8", "description": "manual private range"},
            {"host": "old.example.com", "description": "managed:github:meta:host"},
            {"host": "github.com", "description": "managed:github:old:host"},
        ]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
            syncer.SplitTunnelEntry(
                "address",
                "100.64.0.0/10",
                "managed:tailscale:reserved:cidr",
            ),
        ]

        plan = syncer.calculate_plan(remote, desired)

        self.assertEqual(plan.unmanaged, [{"address": "10.0.0.0/8", "description": "manual private range"}])
        self.assertEqual(
            [entry.to_api() for entry in plan.add],
            [{"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"}],
        )
        self.assertEqual(
            [entry.to_api() for entry in plan.update],
            [{"host": "github.com", "description": "managed:github:static:host"}],
        )
        self.assertEqual(
            [entry.to_api() for entry in plan.remove],
            [{"host": "old.example.com", "description": "managed:github:meta:host"}],
        )
        self.assertEqual(
            plan.merged,
            [
                {"address": "10.0.0.0/8", "description": "manual private range"},
                {"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"},
                {"host": "github.com", "description": "managed:github:static:host"},
            ],
        )

    def test_entry_from_payload_rejects_entries_with_both_host_and_address(self):
        with self.assertRaisesRegex(syncer.SyncError, "exactly one"):
            syncer.entry_from_payload(
                {
                    "host": "github.com",
                    "address": "192.0.2.0/24",
                    "description": "managed:github:meta:host",
                }
            )


class ClientAndCliTests(unittest.TestCase):
    def test_default_profile_endpoint_path(self):
        client = syncer.CloudflareClient("token", "account", None)

        self.assertEqual(
            client.exclude_path(),
            "/accounts/account/devices/policy/exclude",
        )

    def test_custom_profile_endpoint_path(self):
        client = syncer.CloudflareClient("token", "account", "policy")

        self.assertEqual(
            client.exclude_path(),
            "/accounts/account/devices/policy/policy/exclude",
        )

    def test_restore_without_apply_is_parsed_as_dry_run_restore(self):
        args = syncer.parse_args(["--restore", "backup.json"])

        self.assertEqual(args.restore, pathlib.Path("backup.json"))
        self.assertFalse(args.apply)

    def test_provider_filter_accepts_github_and_tailscale(self):
        args = syncer.parse_args(["--provider", "github", "--include-github-ips"])

        self.assertEqual(args.provider, "github")
        self.assertTrue(args.include_github_ips)


if __name__ == "__main__":
    unittest.main()
