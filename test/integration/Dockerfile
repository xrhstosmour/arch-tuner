FROM archlinux:base

# pacman's download sandbox needs syscalls the build step's own seccomp
# profile blocks under emulation, disable it for the duration of the build.
RUN sed -i 's/^#DisableSandboxSyscalls/DisableSandboxSyscalls/' /etc/pacman.conf

# A real systemd PID 1 and sudo, so helpers can be observed against an actual
# Arch userland instead of only parsed by shellcheck.
RUN pacman -Syu --noconfirm --needed \
        systemd sudo which findutils procps-ng git base-devel \
    && ln -sf /usr/lib/systemd/systemd /sbin/init

# A password-less sudo admin user, closer to the non-root operator this
# toolkit targets than running every helper as root outright.
RUN useradd -m -G wheel tester \
    && echo 'tester ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

WORKDIR /arch-tuner
COPY . .
RUN chown -R tester:tester /arch-tuner

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
