#!/bin/sh
export DRACUT_SYSTEMD=1
if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh 2> /dev/null
fi
command -v getarg > /dev/null || . /lib/dracut-lib.sh

source_conf /etc/conf.d

make_trace_mem "hook mount" '1:shortmem' '2+:mem' '3+:slab'

getargs 'rd.break=mount' && emergency_shell -n mount "Break before mount"
# mount scripts actually try to mount the root filesystem, and may
# be sourced any number of times. As soon as one succeeds, no more are sourced.
i=0
while :; do
    if ismounted "$NEWROOT"; then
        usable_root "$NEWROOT" && break
        umount "$NEWROOT"
    fi
    for f in "$hookdir"/mount/*.sh; do
        # shellcheck disable=SC1090
        [ -f "$f" ] && . "$f"
        if ismounted "$NEWROOT"; then
            usable_root "$NEWROOT" && break
            warn "$NEWROOT has no proper rootfs layout, ignoring and removing offending mount hook"
            umount "$NEWROOT"
            rm -f -- "$f"
        fi
    done

    i=$((i + 1))
    [ $i -gt 20 ] && emergency_shell "Can't mount root filesystem"
done

export -p > /dracut-state.sh

exit 0
