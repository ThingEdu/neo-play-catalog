# NEO App Catalog

Human-readable directory of apps known to run on NEO devices, for installing
**outside** the NeoPlay store — setting up a device by hand, provisioning a
classroom set, or grabbing an app the current NeoPlay shelf doesn't carry yet.

NeoPlay's own catalog (the data the store app reads) lives in the Supabase
backend (`apps` + `app_versions` tables), not in this repo — see
`AGENTS.md` in the `neo-play` repo. This file replaces `catalog.json`, which
described the shelf back when it doubled as the store's data source.

## ThingEdu native apps

Each ships its own one-line installer per
[`docs/conventions/installation-script-convention.md`](docs/conventions/installation-script-convention.md).
No arguments installs the latest release; add `-s -- --uninstall` to remove.

| App | Summary | Install |
|---|---|---|
| NEO Code | IDE Python cho học sinh STEM và Robotics | `curl -fsSL https://raw.githubusercontent.com/ThingEdu/neo-code/main/scripts/install_on_neo.sh \| bash` |
| NEO Stop Motion | Phần mềm quay phim hoạt hình cho học sinh | `curl -fsSL https://raw.githubusercontent.com/ThingEdu/neo-stopmotion/main/scripts/install_on_neo.sh \| bash` |
| NeoArcade | Bộ game arcade vận động ThingBot trên NEO | `curl -fsSL https://raw.githubusercontent.com/ThingEdu/NeoArcade/main/scripts/install_on_neo.sh \| bash` |
| NeoAiSport | Game thể thao thị giác AI bằng camera trên NEO | `curl -fsSL https://raw.githubusercontent.com/ThingEdu/NeoAiSport/main/scripts/install_on_neo.sh \| bash` |

## Open-source apps (Flathub)

| App | Summary | Install |
|---|---|---|
| GCompris | Bộ trò chơi giáo dục cho trẻ 2-10 tuổi | `flatpak install -y flathub org.kde.gcompris` |
| Scratch | Lập trình kéo thả cho người mới bắt đầu | `flatpak install -y flathub edu.mit.Scratch` |
| Tux Paint | Vẽ tranh sáng tạo cho trẻ em | `flatpak install -y flathub org.tuxpaint.Tuxpaint` |
| Stellarium | Bầu trời sao 3D ngay trên máy NEO | `flatpak install -y flathub org.stellarium.Stellarium` |

For the default one-liner setup of a fresh NEO One, see
[`scripts/install_default.sh`](scripts/install_default.sh).
