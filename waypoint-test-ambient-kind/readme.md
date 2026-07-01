istio.io/use-waypoint: waypoint   (on pod/namespace)  → WHO uses the waypoint
istio.io/waypoint-for: all        (on Gateway)         → WHAT traffic type the waypoint accepts

So the actual behavior depends on the combination:

┌────────────────────────┬────────────────────────────┬───────────────────┬───────────────────┐
│ Pod label use-waypoint │ Gateway label waypoint-for │  Service traffic  │  Pod IP traffic   │
├────────────────────────┼────────────────────────────┼───────────────────┼───────────────────┤
│ set                    │ all                        │ through waypoint  │ through waypoint  │
├────────────────────────┼────────────────────────────┼───────────────────┼───────────────────┤
│ set                    │ service                    │ through waypoint  │ bypasses waypoint │
├────────────────────────┼────────────────────────────┼───────────────────┼───────────────────┤
│ set                    │ workload                   │ bypasses waypoint │ through waypoint  │
├────────────────────────┼────────────────────────────┼───────────────────┼───────────────────┤
│ set                    │ none                       │ bypasses waypoint │ bypasses waypoint │
└────────────────────────┴────────────────────────────┴───────────────────┴───────────────────┘




⏺ Bash(gh pr list --repo istio/istio --search "fix ingress+waypoint semantics in multi-network" --state all --limit 10 2>&1)
⎿  60162      fix ingress+waypoint semantics in multi-network stevenctl:ingress-use-waypoint-eastwest MERGED  2026-05-09T02:55:39Z
60180      [release-1.30] fix ingress+waypoint semantics in multi-network  istio-testing:cherry-pick-60162-to-release-1.30 MERGED  2026-05-11T13:00:25Z
60210      [release-1.29] fix ingress+waypoint semantics in multi-network (#60162) stevenctl:1.29-gw-src   MERGED  2026-05-13T08:36:49Z
… +2 lines (ctrl+o to expand)

Thought for 12s (ctrl+o to expand)

⏺ Bash(gh release list --repo istio/istio --limit 15 2>&1 | grep -E "1\.29|1\.30")
⎿  Istio 1.30.1       Latest  1.30.1  2026-06-04T21:49:36Z
Istio 1.29.4               1.29.4  2026-06-04T21:51:28Z
Istio 1.30.0               1.30.0  2026-05-18T19:05:52Z
… +6 lines (ctrl+o to expand)

⏺ Here's the complete picture:

The fix: PR #60162 — "fix ingress+waypoint semantics in multi-network" — is exactly your issue.

Before the fix, the east-west gateway always sent x-istio-source: waypoint header, causing it to skip L7/waypoint processing for cross-network traffic. The istio.io/ingress-use-waypoint label exists specifically
to control this but wasn't being consulted correctly.

Cherry-pick timeline:

┌──────────────┬────────┬──────────────┬─────────────────┐
│    Branch    │   PR   │    Merged    │   Released in   │
├──────────────┼────────┼──────────────┼─────────────────┤
│ master       │ #60162 │ May 11, 2026 │ —               │                                                                                                                                         
├──────────────┼────────┼──────────────┼─────────────────┤                                                                                                                               
│ release-1.30 │ #60180 │ May 11, 2026 │ 1.30.0 (May 18) │
├──────────────┼────────┼──────────────┼─────────────────┤
│ release-1.29 │ #60210 │ May 13, 2026 │ 1.29.3 (May 18) │
└──────────────┴────────┴──────────────┴─────────────────┘

You are on 1.29.2 — the fix landed in 1.29.3 and 1.30.0. Upgrading to either 1.29.3, 1.29.4, or 1.30.1 should resolve the SAN mismatch when using waypoints with multi-network ambient.


Now I have the complete picture. There are actually two separate PRs needed to fix this, and neither was cherry-picked to 1.29 or 1.30:

┌────────┬───────────────┬──────────────────────────────────────────────────────────────────────────┬───────────────────┐
│   PR   │     Repo      │                              What it fixes                               │ Cherry-picked to  │
├────────┼───────────────┼──────────────────────────────────────────────────────────────────────────┼───────────────────┤
│ #56844 │ istio/istio   │ istiod generating proper SplitHorizon WDS entries with waypoint identity │ release-1.27 only │
├────────┼───────────────┼──────────────────────────────────────────────────────────────────────────┼───────────────────┤
│ #1565  │ istio/ztunnel │ ztunnel routing to remote-network waypoints via double-HBONE             │ release-1.27 only │
└────────┴───────────────┴──────────────────────────────────────────────────────────────────────────┴───────────────────┘

Both were merged to master in July 2025 but only cherry-picked to release-1.27. They never made it into 1.28, 1.29, or 1.30.

This means:
- 1.30.1 (what you're running now) — still broken
- 1.29.x — still broken
- master (future 1.31) — fixed

The ztunnel PR description is also explicit about incompleteness: "Both of those can be handled by the controlplane, though we don't yet have a complete implementation."

Bottom line: multi-network ambient + waypoint is not fully supported in any current stable Istio release. The feature is gated behind AMBIENT_ENABLE_MULTI_NETWORK which is still experimental, and the waypoint
propagation across networks is only on master. You'd need to wait for Istio 1.31 or use a custom build from master.


https://github.com/istio/ztunnel/pull/1565/changes/396ad1bfb77689e921f138fa52cde856daff1b96



2026-06-08T08:52:53.326278Z	error	access	connection complete	src.addr=10.244.0.9:51948 src.workload="sleep-7bf44b8df8-rx25b" src.namespace="sample" src.identity="spiffe://cluster.local/ns/sample/sa/sleep" dst.addr=172.18.0.5:15008 dst.hbone_addr=helloworld.sample.svc.cluster.local:5000 dst.service="helloworld.sample.svc.cluster.local" dst.workload="NetworkGateway/network-b/172.18.0.5/0" dst.namespace="istio-system" dst.identity="spiffe://cluster.local/ns/istio-system/sa/istio-eastwestgateway" direction="outbound" bytes_sent=0 bytes_recv=0 duration="4ms" error="io error: invalid peer certificate: Other(OtherError(identity verification error: peer did not present the expected SAN (spiffe://cluster.local/ns/sample/sa/default), got spiffe://cluster.local/ns/sample/sa/waypoint))"



https://github.com/istio/istio/issues/60294

https://github.com/envoyproxy/envoy/pull/45267