#!/usr/bin/env bash

# Print an error message and exit with 1
unsupported_os() {
  echo "Detected OS ($1) is unsupported."
  echo "Please open an issue (PRs welcome ❤️) on:"
  echo "    https://github.com/karnotxyz/proof-generator/issues"
  echo ""
  echo "NOTE: you can still try installing dependencies manually"
  echo "If your OS differs from the detected one, you can look \
for the installation script for your OS in the install-scripts folder."
  exit 1
}

# Print the detected OS
print_os() {
  echo "Detected OS: $1"
}

# Print a message and run the script
run_script() {
  echo "Running $1..."
  . $1
}

install_cairo_vm() {
  git clone "https://github.com/lambdaclass/cairo-vm.git" "./dependencies/cairo-vm"
  cd ./dependencies/cairo-vm/ || exit
  ./install.sh
  cd - || exit
}

# Detect Linux distro
install_linux() {
  print_os "Linux"

  install_cairo_vm
  cd dependencies/cairo-vm || exit
  make deps
  cd - || exit
  echo "Cairo VM installed"

  # Install Stone Prover
  git clone https://github.com/starkware-libs/stone-prover.git ./dependencies/stone-prover
  cd dependencies/stone-prover || exit
  docker build --tag prover .
  container_id=$(docker create prover)
  docker cp -L ${container_id}:/bin/cpu_air_prover .
  docker cp -L ${container_id}:/bin/cpu_air_verifier .
  cd - || exit
  echo "Stone Prover installed"
}

install_macos() {
  print_os "MacOS"

  # Install Cairo VM
  install_cairo_vm
  cd dependencies/cairo-vm || exit
  make deps-macos
  cd - || exit
  echo "Cairo VM installed"

  # Install Stone Prover
  git clone https://github.com/baking-bad/stone-prover ./dependencies/stone-prover
  cd dependencies/stone-prover || exit
  ./install_deps.sh
  bazelisk build //...
  bazelisk test //...
  cp ./build/bazelbin/src/starkware/main/cpu/cpu_air_prover .
  cp ./build/bazelbin/src/starkware/main/cpu/cpu_air_verifier .
  cd - || exit
  echo "Stone Prover installed"
}

case "$OSTYPE" in
linux*) install_linux ;;
darwin*) install_macos ;;
msys* | cygwin*) unsupported_os "Windows" ;;
solaris*) unsupported_os "Solaris" ;;
bsd*) unsupported_os "BSD" ;;
*) unsupported_os "unknown: ${OSTYPE}" ;;
esac
