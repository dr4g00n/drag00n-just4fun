#!/usr/bin/env python3
"""
地图数据后处理

扫描 map_data/raw/ 下的原始数据，合并 edges.txt，
生成标准 JSON 地图文件到 map_data/ 目录。

用法:
  python3 map_save.py              # 处理所有 raw 数据
  python3 map_save.py --dry-run    # 只显示，不写文件

输出格式（每个房间一个 JSON 文件）:
{
    "room": "房间名",
    "exits": ["east", "south"],
    "edges": {"east": "邻居房间名", "south": "另一个房间"},
    "npcs": ["NPC名(ID)"]
}
"""

import json
import os
import re
import sys
from collections import defaultdict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(SCRIPT_DIR, "raw")
EDGES_FILE = os.path.join(RAW_DIR, "edges.txt")


def load_raw_exits():
    """读取 raw/*.exits 文件"""
    rooms = {}
    if not os.path.isdir(RAW_DIR):
        return rooms
    for fname in os.listdir(RAW_DIR):
        if not fname.endswith(".exits"):
            continue
        fpath = os.path.join(RAW_DIR, fname)
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                line = f.readline().strip()
            if "|" in line:
                parts = line.split("|", 1)
                room_name = parts[0].strip()
                exits_str = parts[1].strip()
                exits = re.split(r"[、\s,]+", exits_str)
                exits = [e for e in exits if e]
                rooms[room_name] = exits
        except Exception:
            pass
    return rooms


def load_raw_npcs():
    """读取 raw/*.npcs 文件"""
    npcs = defaultdict(list)
    if not os.path.isdir(RAW_DIR):
        return npcs
    for fname in os.listdir(RAW_DIR):
        if not fname.endswith(".npcs"):
            continue
        room_name = fname[:-5]
        fpath = os.path.join(RAW_DIR, fname)
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        npcs[room_name].append(line)
        except Exception:
            pass
    return npcs


def load_edges():
    """读取 edges.txt，返回 {(源, 目标): 方向}"""
    edges = {}
    if not os.path.isfile(EDGES_FILE):
        return edges
    with open(EDGES_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if "|" not in line:
                continue
            parts = line.split("|")
            if len(parts) == 3:
                src, direction, dst = parts[0].strip(), parts[1].strip(), parts[2].strip()
                if src and dst and direction:
                    edges[(src, dst)] = direction
    return edges


def build_room_map():
    """构建完整的房间数据"""
    rooms = load_raw_exits()
    npcs = load_raw_npcs()
    edges = load_edges()

    room_map = {}
    for room_name, exits in rooms.items():
        room_edges = {}
        for (src, dst), direction in edges.items():
            if src == room_name and direction in exits:
                room_edges[direction] = dst

        room_map[room_name] = {
            "room": room_name,
            "exits": exits,
            "edges": room_edges,
            "npcs": list(npcs.get(room_name, [])),
        }

    return room_map


def save_rooms(room_map, dry_run=False):
    """将房间数据保存为 JSON 文件"""
    saved = 0
    for room_name, data in sorted(room_map.items()):
        outpath = os.path.join(SCRIPT_DIR, f"{room_name}.json")
        if dry_run:
            print(f"  [dry-run] {room_name} → {outpath}")
            print(f"    exits: {data['exits']}")
            print(f"    edges: {data['edges']}")
            print(f"    npcs:  {data['npcs']}")
        else:
            with open(outpath, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"  已保存: {room_name}")
        saved += 1
    return saved


def main():
    dry_run = "--dry-run" in sys.argv

    room_map = build_room_map()

    if not room_map:
        print("raw 目录下没有可处理的数据")
        sys.exit(0)

    print(f"找到 {len(room_map)} 个房间")
    saved = save_rooms(room_map, dry_run=dry_run)
    print(f"共处理 {saved} 个房间")


if __name__ == "__main__":
    main()
