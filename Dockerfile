# Reproducible environment for the libsndfile fuzzing campaign.
#
#   docker build -t sndfile-fuzz .
#   docker run --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
#       -v "$PWD/results:/work/results" -e DURATION=600 \
#       sndfile-fuzz scripts/baseline.sh <run-name>
#
# The image clones libsndfile at the commit pinned in scripts/env.sh and holds
# both builds (build/fuzz and build/cov), so it does not depend on anything
# left on the host. Only results/ is shared with the host, through the mount.
#
# SYS_PTRACE and seccomp=unconfined are needed for LeakSanitizer (part of
# ASan), which otherwise aborts inside a container.
#
# Build with --build-arg EXTERNAL_LIBS=1 to link FLAC/Ogg/Vorbis/Opus/MPEG
# instead (output goes to build/fuzz-extlibs and build/cov-extlibs).
FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
		clang-21 llvm-21 libclang-rt-21-dev build-essential \
		autoconf autogen automake libtool pkg-config python3 git ca-certificates \
		libflac-dev libogg-dev libvorbis-dev libopus-dev libmpg123-dev libmp3lame-dev \
	&& rm -rf /var/lib/apt/lists/*

# Unversioned clang, llvm-cov and llvm-profdata, as the scripts expect.
ENV PATH=/usr/lib/llvm-21/bin:$PATH

ARG EXTERNAL_LIBS=0
ENV EXTERNAL_LIBS=$EXTERNAL_LIBS

WORKDIR /work
COPY scripts/ scripts/
RUN chmod +x scripts/*.sh scripts/*.py \
	&& scripts/build.sh fuzz \
	&& scripts/build.sh cov
