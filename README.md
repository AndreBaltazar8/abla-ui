# abla-ui

The parts of a component UI that don't depend on where it is drawn, written in
[Abla](../ablac): state with change tracking, and flex layout. It is shared by
[abla-one](../abla-one) (applications on Android, the web, desktop and e-paper) and
[abla-forge](../abla-web3d) (the game engine), which each bring their own tree, renderer and
input.

It imports only the Abla standard library: no renderer, no platform, no application code.
Text is measured through an interface the caller supplies, so one side can use width tables
and another real fonts.

Nothing is here yet beyond this description; the first pieces are being written.

## License

abla-ui is licensed under the [Mozilla Public License 2.0](LICENSE).
