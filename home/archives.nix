# archives.nix by poligle

{ config, pkgs, lib, ... }:
let
	# Luciole is the installed file manager; use it to open archives too.
	archiveTypes =
	[
		"application/zip"
		"application/x-zip-compressed"
		"application/x-tar"
		"application/x-compressed-tar"
		"application/x-bzip-compressed-tar"
		"application/x-xz-compressed-tar"
		"application/gzip"
		"application/x-gzip"
		"application/x-7z-compressed"
		"application/x-rar"
		"application/vnd.rar"
		"application/x-cpio"
		"application/x-iso9660-image"
		"application/x-cd-image"
		"application/x-archive"
		"application/java-archive"
		"application/x-java-archive"
	];
in
{
	xdg.mimeApps.defaultApplications =
		lib.genAttrs archiveTypes (_: "dev.noctalia.luciole.desktop");
}