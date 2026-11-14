"""Swords and Sandals 2 Co-op Relay package."""

from .ss2_coop_relay import (
    DEFAULT_CLIENT_LOCAL_PORT,
    DEFAULT_HOST_LOCAL_PORT,
    DEFAULT_PEER_PORT,
    POLICY_REQUEST,
    POLICY_RESPONSE,
    RelayConfig,
    RelayRunner,
    TailscaleInfo,
    detect_tailscale_ipv4,
    parse_host_port,
)

__all__ = [
    "DEFAULT_CLIENT_LOCAL_PORT",
    "DEFAULT_HOST_LOCAL_PORT",
    "DEFAULT_PEER_PORT",
    "POLICY_REQUEST",
    "POLICY_RESPONSE",
    "RelayConfig",
    "RelayRunner",
    "TailscaleInfo",
    "detect_tailscale_ipv4",
    "parse_host_port",
]
