import importlib.util
import contextlib
import io
import json
import os
import pathlib
import tempfile
import unittest
import unittest.mock
import urllib.error


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

    def test_github_meta_top_level_shape_must_be_object(self):
        with self.assertRaisesRegex(syncer.SyncError, "GitHub meta response must be an object"):
            syncer.build_github_entries(["not", "an", "object"], include_ips=False)

    def test_github_domains_shape_must_be_supported(self):
        with self.assertRaisesRegex(syncer.SyncError, "unsupported GitHub domains shape"):
            syncer.build_github_entries({"domains": 123}, include_ips=False)

    def test_github_domains_nested_none_shape_must_be_supported(self):
        with self.assertRaisesRegex(syncer.SyncError, "unsupported GitHub domains shape"):
            syncer.build_github_entries({"domains": ["github.com", None]}, include_ips=False)

    def test_github_meta_requires_domains_key(self):
        with self.assertRaisesRegex(syncer.SyncError, "GitHub meta response must contain a domains value"):
            syncer.build_github_entries({}, include_ips=False)

    def test_github_meta_domains_must_not_be_null(self):
        with self.assertRaisesRegex(syncer.SyncError, "GitHub meta response must contain a domains value"):
            syncer.build_github_entries({"domains": None}, include_ips=False)

    def test_github_ip_category_none_value_must_be_list(self):
        with self.assertRaisesRegex(syncer.SyncError, "GitHub meta category 'web' is not a list"):
            syncer.build_github_entries({"domains": [], "web": None}, include_ips=True)

    def test_github_ip_category_falsey_non_list_values_must_be_list(self):
        for value in ("", False):
            with self.subTest(value=value):
                with self.assertRaisesRegex(syncer.SyncError, "GitHub meta category 'api' is not a list"):
                    syncer.build_github_entries({"domains": [], "api": value}, include_ips=True)

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

    def test_tailscale_derp_map_top_level_shape_must_be_object(self):
        with self.assertRaisesRegex(syncer.SyncError, "Tailscale DERP map response must be an object"):
            syncer.build_tailscale_entries(["not", "an", "object"], include_derp_ips=False)

    def test_tailscale_derp_region_shape_must_be_object(self):
        derp_map = {"Regions": {"1": ["not", "an", "object"]}}

        with self.assertRaisesRegex(syncer.SyncError, "Tailscale DERP region value is not an object"):
            syncer.build_tailscale_entries(derp_map, include_derp_ips=False)

    def test_tailscale_derp_node_shape_must_be_object(self):
        derp_map = {"Regions": {"1": {"Nodes": ["not-object"]}}}

        with self.assertRaisesRegex(syncer.SyncError, "Tailscale DERP node value is not an object"):
            syncer.build_tailscale_entries(derp_map, include_derp_ips=False)

    def test_tailscale_derp_region_requires_nodes_key(self):
        derp_map = {"Regions": {"1": {}}}

        with self.assertRaisesRegex(syncer.SyncError, "Tailscale DERP region Nodes value is not a list"):
            syncer.build_tailscale_entries(derp_map, include_derp_ips=False)

    def test_tailscale_derp_region_nodes_must_not_be_null(self):
        derp_map = {"Regions": {"1": {"Nodes": None}}}

        with self.assertRaisesRegex(syncer.SyncError, "Tailscale DERP region Nodes value is not a list"):
            syncer.build_tailscale_entries(derp_map, include_derp_ips=False)


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

    def test_plan_manifest_preserves_current_remote_managed_entries(self):
        remote = [
            {"host": "old.example.com", "description": "managed:github:meta:host"},
            {"host": "github.com", "description": "managed:github:old:host"},
        ]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
        ]

        plan = syncer.calculate_plan(remote, desired)
        manifest = syncer.plan_manifest("account", None, "github", plan, False, False)

        self.assertEqual(
            manifest["current_managed"],
            [
                {"host": "github.com", "description": "managed:github:old:host"},
                {"host": "old.example.com", "description": "managed:github:meta:host"},
            ],
        )

    def test_calculate_plan_rejects_duplicate_remote_managed_keys(self):
        remote = [
            {"host": "github.com", "description": "managed:github:old:host"},
            {"host": "github.com", "description": "managed:github:newer:host"},
        ]

        with self.assertRaisesRegex(syncer.SyncError, "duplicate remote managed entry"):
            syncer.calculate_plan(remote, [])

    def test_provider_scoped_plan_preserves_out_of_scope_managed_entries(self):
        remote = [
            {"host": "old.github.example", "description": "managed:github:meta:host"},
            {"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"},
        ]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
        ]

        plan = syncer.calculate_plan(remote, desired, provider="github")

        self.assertEqual(
            [entry.to_api() for entry in plan.remove],
            [{"host": "old.github.example", "description": "managed:github:meta:host"}],
        )
        self.assertEqual(plan.out_of_scope_managed, [{"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"}])
        self.assertEqual(
            plan.merged,
            [
                {"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"},
                {"host": "github.com", "description": "managed:github:static:host"},
            ],
        )

    def test_all_provider_plan_preserves_unsupported_managed_entries(self):
        remote = [
            {"host": "sso.example.com", "description": "managed:okta:static:host"},
            {"host": "old.github.example", "description": "managed:github:meta:host"},
        ]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
        ]

        plan = syncer.calculate_plan(remote, desired, provider="all")

        self.assertEqual(plan.out_of_scope_managed, [{"host": "sso.example.com", "description": "managed:okta:static:host"}])
        self.assertEqual(
            [entry.to_api() for entry in plan.remove],
            [{"host": "old.github.example", "description": "managed:github:meta:host"}],
        )
        self.assertEqual(
            plan.merged,
            [
                {"host": "sso.example.com", "description": "managed:okta:static:host"},
                {"host": "github.com", "description": "managed:github:static:host"},
            ],
        )

    def test_calculate_plan_rejects_unmanaged_conflict_with_desired_key(self):
        remote = [{"host": "github.com", "description": "manual github host"}]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
        ]

        with self.assertRaisesRegex(syncer.SyncError, "conflicts with preserved entry"):
            syncer.calculate_plan(remote, desired)

    def test_calculate_plan_rejects_out_of_scope_conflict_with_desired_key(self):
        remote = [{"host": "github.com", "description": "managed:tailscale:firewall:host"}]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
        ]

        with self.assertRaisesRegex(syncer.SyncError, "conflicts with preserved entry"):
            syncer.calculate_plan(remote, desired, provider="github")

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

    def test_read_json_reports_malformed_restore_input_as_sync_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text("{")

            with self.assertRaisesRegex(syncer.SyncError, f"invalid JSON in {restore_file}"):
                syncer.read_json(restore_file)

    def test_restore_dry_run_does_not_require_cloudflare_client(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text("[]\n")
            stdout = io.StringIO()

            with unittest.mock.patch.object(syncer, "load_cloudflare_client") as load_client, \
                contextlib.redirect_stdout(stdout):
                result = syncer.run(["--restore", str(restore_file), "--state-dir", tmpdir])

            self.assertEqual(result, 0)
            load_client.assert_not_called()
            self.assertIn("restore not applied", stdout.getvalue())

    def test_restore_dry_run_rejects_malformed_entries_before_loading_client(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text('[{"host":"github.com","address":"192.0.2.0/24","description":"managed:github:meta:host"}]\n')

            with unittest.mock.patch.object(syncer, "load_cloudflare_client") as load_client, \
                self.assertRaisesRegex(syncer.SyncError, "exactly one"):
                syncer.run(["--restore", str(restore_file), "--state-dir", tmpdir])

            load_client.assert_not_called()

    def test_restore_validation_accepts_manual_entry_without_description(self):
        syncer.validate_restore_entries([{"host": "manual.example.com"}], pathlib.Path("restore.json"))

    def test_restore_validation_rejects_entries_with_no_host_or_address(self):
        with self.assertRaisesRegex(syncer.SyncError, "exactly one"):
            syncer.validate_restore_entries([{"description": "manual"}], pathlib.Path("restore.json"))

    def test_restore_validation_rejects_entries_with_both_host_and_address(self):
        with self.assertRaisesRegex(syncer.SyncError, "exactly one"):
            syncer.validate_restore_entries(
                [{"host": "manual.example.com", "address": "192.0.2.0/24"}],
                pathlib.Path("restore.json"),
            )

    def test_write_json_secure_tightens_existing_file_permissions(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = pathlib.Path(tmpdir) / "state.json"
            path.write_text("{}\n")
            os.chmod(path, 0o644)

            syncer.write_json_secure(path, {"ok": True})

            self.assertEqual(os.stat(path).st_mode & 0o777, 0o600)

    def test_provider_filter_accepts_github_and_tailscale(self):
        args = syncer.parse_args(["--provider", "github", "--include-github-ips"])

        self.assertEqual(args.provider, "github")
        self.assertTrue(args.include_github_ips)

    def test_apply_put_failure_prints_restore_command_for_before_backup(self):
        class FailingClient:
            account_id = "account"
            policy_id = None

            def get_excludes(self):
                return [{"host": "github.com", "description": "managed:github:old:host"}]

            def put_excludes(self, entries):
                raise syncer.SyncError("put failed")

        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            )
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=FailingClient()), \
                unittest.mock.patch.object(syncer, "build_desired_entries", return_value=desired), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "put failed"):
                syncer.run(["--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before.json"
            self.assertEqual(json.loads(before_path.read_text()), FailingClient().get_excludes())
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_apply_post_put_get_failure_prints_restore_command(self):
        class FailingGetClient:
            account_id = "account"
            policy_id = None

            def __init__(self):
                self.calls = 0

            def get_excludes(self):
                self.calls += 1
                if self.calls == 1:
                    return [{"host": "github.com", "description": "managed:github:old:host"}]
                raise syncer.SyncError("post-put get failed")

            def put_excludes(self, entries):
                return entries

        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            )
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=FailingGetClient()), \
                unittest.mock.patch.object(syncer, "build_desired_entries", return_value=desired), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "post-put get failed"):
                syncer.run(["--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before.json"
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_apply_verification_failure_prints_restore_command(self):
        class MismatchClient:
            account_id = "account"
            policy_id = None

            def __init__(self):
                self.calls = 0

            def get_excludes(self):
                self.calls += 1
                return [{"host": "github.com", "description": "managed:github:old:host"}]

            def put_excludes(self, entries):
                return entries

        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            )
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=MismatchClient()), \
                unittest.mock.patch.object(syncer, "build_desired_entries", return_value=desired), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "post-apply verification failed"):
                syncer.run(["--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before.json"
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_apply_after_backup_write_failure_prints_restore_command(self):
        class UpdatedClient:
            account_id = "account"
            policy_id = None

            def __init__(self):
                self.calls = 0

            def get_excludes(self):
                self.calls += 1
                if self.calls == 1:
                    return [{"host": "github.com", "description": "managed:github:old:host"}]
                return [{"host": "github.com", "description": "managed:github:static:host"}]

            def put_excludes(self, entries):
                return entries

        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            )
        ]
        real_write_json_secure = syncer.write_json_secure

        def failing_after_write(path, value):
            if str(path).endswith("-after.json"):
                raise OSError("disk full")
            return real_write_json_secure(path, value)

        with tempfile.TemporaryDirectory() as tmpdir:
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=UpdatedClient()), \
                unittest.mock.patch.object(syncer, "build_desired_entries", return_value=desired), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                unittest.mock.patch.object(syncer, "write_json_secure", side_effect=failing_after_write), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaises(syncer.SyncError):
                syncer.run(["--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before.json"
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_apply_put_timeout_prints_restore_command_for_before_backup(self):
        class TimeoutClient(syncer.CloudflareClient):
            def __init__(self):
                super().__init__("token", "account", None)

            def get_excludes(self):
                return [{"host": "github.com", "description": "managed:github:old:host"}]

        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            )
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=TimeoutClient()), \
                unittest.mock.patch.object(syncer, "build_desired_entries", return_value=desired), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                unittest.mock.patch.object(syncer.urllib.request, "urlopen", side_effect=TimeoutError("timed out")), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "Cloudflare PUT"):
                syncer.run(["--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before.json"
            self.assertEqual(json.loads(before_path.read_text()), TimeoutClient().get_excludes())
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_restore_apply_put_failure_prints_restore_command_for_before_backup(self):
        class FailingClient:
            account_id = "account"
            policy_id = None

            def get_excludes(self):
                return [{"host": "github.com", "description": "managed:github:old:host"}]

            def put_excludes(self, entries):
                raise syncer.SyncError("restore put failed")

        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text('[{"host":"github.com","description":"managed:github:static:host"}]\n')
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=FailingClient()), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "restore put failed"):
                syncer.run(["--restore", str(restore_file), "--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before-restore.json"
            output = stdout.getvalue()
            self.assertEqual(json.loads(before_path.read_text()), FailingClient().get_excludes())
            self.assertIn(f"backup before write: {before_path}", output)
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                output,
            )

    def test_restore_apply_post_put_get_failure_prints_restore_command(self):
        class FailingGetClient:
            account_id = "account"
            policy_id = None

            def __init__(self):
                self.calls = 0

            def get_excludes(self):
                self.calls += 1
                if self.calls == 1:
                    return [{"host": "github.com", "description": "managed:github:old:host"}]
                raise syncer.SyncError("restore post-put get failed")

            def put_excludes(self, entries):
                return entries

        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text('[{"host":"github.com","description":"managed:github:static:host"}]\n')
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=FailingGetClient()), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "restore post-put get failed"):
                syncer.run(["--restore", str(restore_file), "--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before-restore.json"
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_restore_apply_mismatch_writes_after_backup_and_prints_restore_command(self):
        class MismatchClient:
            account_id = "account"
            policy_id = None

            def __init__(self):
                self.calls = 0

            def get_excludes(self):
                self.calls += 1
                if self.calls == 1:
                    return [{"host": "before.example.com"}]
                return [{"host": "different.example.com"}]

            def put_excludes(self, entries):
                return entries

        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text('[{"host":"restore.example.com"}]\n')
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=MismatchClient()), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaisesRegex(syncer.SyncError, "restore verification failed"):
                syncer.run(["--restore", str(restore_file), "--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before-restore.json"
            after_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-after-restore.json"
            self.assertTrue(after_path.exists())
            self.assertEqual(json.loads(after_path.read_text()), [{"host": "different.example.com"}])
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_restore_apply_after_backup_write_failure_prints_restore_command(self):
        class RestoredClient:
            account_id = "account"
            policy_id = None

            def __init__(self):
                self.calls = 0

            def get_excludes(self):
                self.calls += 1
                if self.calls == 1:
                    return [{"host": "before.example.com"}]
                return [{"host": "restore.example.com"}]

            def put_excludes(self, entries):
                return entries

        real_write_json_secure = syncer.write_json_secure

        def failing_after_write(path, value):
            if str(path).endswith("-after-restore.json"):
                raise OSError("disk full")
            return real_write_json_secure(path, value)

        with tempfile.TemporaryDirectory() as tmpdir:
            restore_file = pathlib.Path(tmpdir) / "restore.json"
            restore_file.write_text('[{"host":"restore.example.com"}]\n')
            stdout = io.StringIO()
            with unittest.mock.patch.object(syncer, "load_cloudflare_client", return_value=RestoredClient()), \
                unittest.mock.patch.object(syncer, "utc_timestamp", return_value="20260529T000000Z"), \
                unittest.mock.patch.object(syncer, "write_json_secure", side_effect=failing_after_write), \
                contextlib.redirect_stdout(stdout), \
                self.assertRaises(syncer.SyncError):
                syncer.run(["--restore", str(restore_file), "--apply", "--state-dir", tmpdir])

            before_path = pathlib.Path(tmpdir) / "backups" / "20260529T000000Z-before-restore.json"
            self.assertIn(
                f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply",
                stdout.getvalue(),
            )

    def test_cloudflare_http_error_redacts_token_from_response_body(self):
        token = "secret-token"
        error = urllib.error.HTTPError(
            url="https://example.test",
            code=400,
            msg="Bad Request",
            hdrs={},
            fp=io.BytesIO(b'{"error":"secret-token leaked"}'),
        )
        client = syncer.CloudflareClient(token, "account", None)

        with unittest.mock.patch.object(syncer.urllib.request, "urlopen", side_effect=error), \
            self.assertRaises(syncer.SyncError) as ctx:
            client.get_excludes()

        self.assertNotIn(token, str(ctx.exception))
        self.assertIn("[redacted]", str(ctx.exception))

    def test_cloudflare_transport_errors_redact_token(self):
        token = "secret-token"
        errors = [
            urllib.error.URLError(f"{token} in url error"),
            OSError(f"{token} in os error"),
        ]

        for error in errors:
            with self.subTest(error=type(error).__name__):
                client = syncer.CloudflareClient(token, "account", None)
                with unittest.mock.patch.object(syncer.urllib.request, "urlopen", side_effect=error), \
                    self.assertRaises(syncer.SyncError) as ctx:
                    client.get_excludes()

                self.assertNotIn(token, str(ctx.exception))
                self.assertIn("[redacted]", str(ctx.exception))

    def test_cloudflare_non_object_json_response_is_sync_error(self):
        class ListResponse(io.BytesIO):
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

        client = syncer.CloudflareClient("token", "account", None)

        with unittest.mock.patch.object(syncer.urllib.request, "urlopen", return_value=ListResponse(b"[]")):
            with self.assertRaisesRegex(syncer.SyncError, "response is not an object"):
                client.get_excludes()

    def test_malformed_json_response_is_reported_as_sync_error(self):
        class BadJsonResponse(io.BytesIO):
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

        with unittest.mock.patch.object(syncer.urllib.request, "urlopen", return_value=BadJsonResponse(b"{")):
            with self.assertRaisesRegex(syncer.SyncError, "invalid JSON"):
                syncer.fetch_json("https://example.test/source.json")

    def test_source_timeout_is_reported_as_sync_error(self):
        with unittest.mock.patch.object(
            syncer.urllib.request,
            "urlopen",
            side_effect=TimeoutError("timed out"),
        ):
            with self.assertRaisesRegex(syncer.SyncError, "source fetch failed for https://example.test/source.json"):
                syncer.fetch_json("https://example.test/source.json")


if __name__ == "__main__":
    unittest.main()
