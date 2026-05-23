# Security Policy

## Supported Versions

Security fixes are handled for the latest public release.

## Reporting a Vulnerability

Please report suspected vulnerabilities privately by email rather than opening a
public issue. Contact Ryan McConville at <ryan@ryanmcconville.com>.

Include:

- A concise description of the issue.
- Steps to reproduce.
- macOS version and hardware architecture.
- Whether the issue requires a crafted preset file or only normal app use.

Display Presets does not collect telemetry, run a network service, or accept
remote input. The main security-sensitive surfaces are local preset files,
process execution of the installed `displayplacer` binary, and macOS login-item
registration.
