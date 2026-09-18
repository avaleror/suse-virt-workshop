# Self-checks

One script per exercise that has concrete, checkable state (1-3). Exercises
4-7 print a pass with a pointer to what to look for in the UI instead —
adapted straight from [suse-virt-rodeo](https://github.com/avaleror/suse-virt-rodeo)'s
own Instruqt checks, where those chapters are deliberately left unscored
(everything they need is self-provisioned, and nothing later in the track
reads back state you create in them).

Run from the KVM/EC2 host, as whichever user ran `rodeo up`:

```bash
./checks/check-exercise-1.sh
```

Each script uses `~/.rodeo/harvester-kubeconfig` by default. Override with
`KUBECONFIG=/path/to/kubeconfig ./checks/check-exercise-N.sh` if yours lives
elsewhere.
