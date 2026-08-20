set shell := ["nu", "-c"]

alias help := default

default:
  @just --list -f {{justfile()}} -d {{invocation_directory()}}

lint:
  @echo '-------- [Linting] ---------'
  @let out = (statix check . | complete); if ($out.exit_code > 0) { let span = (metadata $out).span; error make {msg: "Linting failed", label: {text: $out.stdout, span: $span}} } else { print "Lint ok\n\n"; print $out.stdout }

dead:
  @echo '-------- [Check for dead code] ---------'
  @let out = (deadnix -f . | complete); if ($out.exit_code > 0) { let span = (metadata $out).span; error make {msg: "Dead code check failed", label: {text: $out.stdout, span: $span}} } else { print "No dead code\n\n"; print $out.stdout }

dscheck:
  @echo '-------- [Flake checker] ---------'
  @let out = (nix run github:DeterminateSystems/flake-checker | complete); if ($out.exit_code > 0) { let span = (metadata $out).span; error make {msg: "Flake checker failed", label: {text: $out.stdout, span: $span}} } else { print "Flake is good\n\n"; print $out.stdout }

check:
  @nix flake check --impure # impure because of devenv
