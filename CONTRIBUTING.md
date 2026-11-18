# Contributing

Open an issue or a focused pull request. Include the behavior contract, upstream
reference if relevant, native differences and transition tests. Do not add an app,
service, analytics SDK or styling dependency to the behavior core.

Run `swift test`, build the iOS catalog, and replay relevant interaction tests.
For visual or interaction changes inspect light/dark, Dynamic Type and narrow
layouts; document what was observed, including pending VoiceOver/device checks.
Use the actual adapter in the catalog, never a parallel demo implementation.

The project uses Apache-2.0. Contributions are provided under that license.
Report security issues privately through GitHub's private vulnerability reporting
when available; never post credentials or private app content in an issue.
