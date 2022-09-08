### Vanilla upstream openJDK from source ###

#### Host requirements ####

x86_64 Linux with docker, user with UID 10001, a member of GID 10001 and docker groups, enough disk space in ```${HOME}``` to store openJDK source and build dir

[Windows host](win.txt) 

#### How-to run ####

##### Linux #####

Centos, Debian, Alpine or openSUSE container to build openJDK 11 or 17

openJDK 17 in openSUSE

```shell script
bash builder.bash opensuse 17
```

openJDK 8 in debian

```shell script
bash builder.bash debian 8
```

##### Windows #####

Clone, cd, run ```bash entrypoint8.bash```, ```bash entrypoint9plus.bash 11``` or ```bash entrypoint9plus.bash 17```

#### Troubleshooting ####

```
error: RPC failed; curl 56 GnuTLS recv error (-54): Error in the pull function.
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

On the host ```git config --global http.postBuffer 1048576000``` and ```git clone ...```

#### License ####

Perl "Artistic License"
