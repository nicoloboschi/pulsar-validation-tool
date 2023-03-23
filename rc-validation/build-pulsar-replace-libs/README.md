# Replace Pulsar core libs from a specific commit


## Usage

```
PULSAR_DIR=~/mypulsardir ./build.sh <build_from_image> <git_tag_from> <git_tag_to>
```

Example:

```
PULSAR_DIR=~/mypulsardir ./build.sh datastax/lunastreaming-all:2.10_3.4 ls210_3.4 335ab8abd570437250195e9405856b274f8556f4
```

This command will:
- Build changed modules between 335ab8abd570437250195e9405856b274f8556f4 and ls210_3.4
- Starting from datastax/lunastreaming-all:2.10_3.4, replace changed libs (/pulsar/libs) and create a new docker image


Notes:
- Dependency upgrades are not detected
- Connectors, offloaders and other extra stuff are not detected
