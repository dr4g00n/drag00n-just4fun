#!/usr/bin/env python3
"""
地图导航引擎

读取 map_data/raw/ 下的原始数据构建图，支持：
  path <起点> <终点>  — BFS 最短路径
  walk <起点> <终点>  — 输出逐步移动指令
  npc <关键词>        — 查找 NPC 所在房间
  unvisited           — 列出未完全探索的房间（出口数 < 2）
  list                — 列出所有已知房间

数据来源（优先级）：
  1. map_data/raw/*.exits + *.npcs + edges.txt（tt++ 采集的原始数据）
  2. map_data/*.json（旧格式 fallback）
"""

import json
import os
import re
import sys
from collections import defaultdict, deque

ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')


def strip_ansi(text):
    return ANSI_RE.sub('', text)


def parse_exits(exits_str):
    exits_str = strip_ansi(exits_str)
    exits_str = re.sub(r'[。.和]', '', exits_str)
    exits = re.split(r"[、\s,]+", exits_str)
    return [e for e in exits if e]


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(SCRIPT_DIR, "raw")
EDGES_FILE = os.path.join(RAW_DIR, "edges.txt")
DATA_DIR = SCRIPT_DIR


def load_from_raw():
    """从 raw 目录读取 tt++ 采集的原始数据"""
    rooms = {}
    npcs = defaultdict(list)

    if not os.path.isdir(RAW_DIR):
        return rooms, npcs

    for fname in os.listdir(RAW_DIR):
        fpath = os.path.join(RAW_DIR, fname)

        if fname.endswith(".exits"):
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    line = f.readline().strip()
                if "|" in line:
                    parts = line.split("|", 1)
                    room_name = parts[0].strip()
                    exits_str = parts[1].strip()
                    exits = parse_exits(exits_str)
                    rooms[room_name] = {"exits": exits, "file": fpath}
            except Exception:
                pass

        elif fname.endswith(".npcs"):
            room_name = fname[:-5]
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line:
                            npcs[room_name].append(line)
            except Exception:
                pass

    return rooms, npcs


def load_from_json():
    """从 map_data/ 下的 JSON 文件读取（旧格式 fallback）"""
    rooms = {}
    npcs = defaultdict(list)

    for fname in os.listdir(DATA_DIR):
        if not fname.endswith(".json"):
            continue
        fpath = os.path.join(DATA_DIR, fname)
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            room_name = data.get("room", "")
            exits_str = data.get("exits", "")
            if isinstance(exits_str, list):
                exits = exits_str
            elif isinstance(exits_str, str):
                exits = parse_exits(exits_str)
            else:
                exits = []
            if room_name:
                rooms[room_name] = {"exits": exits, "file": fpath}
            for npc in data.get("npcs", []):
                npcs[room_name].append(npc)
        except Exception:
            pass

    return rooms, npcs


def load_edges():
    """从 edges.txt 读取边信息

    支持两种格式：
      源房间|方向|目标房间  （三段，有方向）
      源房间|目标房间       （两段，无方向）

    返回 (adjacency, directed_edges)
      adjacency: {房间: {邻居房间, ...}}
      directed_edges: {(源房间, 目标房间): 方向}
    """
    adjacency = defaultdict(set)
    directed_edges = {}
    if not os.path.isfile(EDGES_FILE):
        return adjacency, directed_edges
    try:
        with open(EDGES_FILE, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if "|" not in line:
                    continue
                parts = line.split("|")
                if len(parts) == 3:
                    a, direction, b = parts[0].strip(), parts[1].strip(), parts[2].strip()
                    if a and b:
                        adjacency[a].add(b)
                        adjacency[b].add(a)
                        if direction:
                            directed_edges[(a, b)] = direction
                elif len(parts) == 2:
                    a, b = parts[0].strip(), parts[1].strip()
                    if a and b:
                        adjacency[a].add(b)
                        adjacency[b].add(a)
    except Exception:
        pass
    return adjacency, directed_edges


def build_graph():
    """构建完整的图结构，合并所有数据源"""
    rooms, npcs = load_from_raw()
    json_rooms, json_npcs = load_from_json()

    for name, info in json_rooms.items():
        if name not in rooms:
            rooms[name] = info

    for name, npc_list in json_npcs.items():
        for npc in npc_list:
            if npc not in npcs[name]:
                npcs[name].append(npc)

    edge_adj, directed_edges = load_edges()

    graph = {}
    for name, info in rooms.items():
        exits = list(info.get("exits", []))
        neighbors = set()
        for exit_dir in exits:
            if exit_dir in edge_adj.get(name, set()):
                neighbors.add(exit_dir)
        graph[name] = {
            "exits": exits,
            "neighbors": neighbors,
            "npcs": list(npcs.get(name, [])),
        }

    for node in set(list(edge_adj.keys()) + [n for adj in edge_adj.values() for n in adj]):
        if node not in graph:
            graph[node] = {"exits": [], "neighbors": edge_adj.get(node, set()), "npcs": []}
        else:
            all_neighbors = graph[node]["neighbors"] | edge_adj.get(node, set())
            graph[node]["neighbors"] = all_neighbors

    for room_name in graph:
        graph[room_name]["directed_edges"] = {}

    for (src, dst), direction in directed_edges.items():
        if src in graph:
            graph[src]["directed_edges"][dst] = direction

    return graph


def bfs_path(graph, start, end):
    """BFS 最短路径，返回房间名列表或 None"""
    if start == end:
        return [start]
    if start not in graph or end not in graph:
        return None

    visited = {start}
    queue = deque([(start, [start])])
    while queue:
        node, path = queue.popleft()
        for neighbor in graph.get(node, {}).get("neighbors", set()):
            if neighbor not in visited:
                new_path = path + [neighbor]
                if neighbor == end:
                    return new_path
                visited.add(neighbor)
                queue.append((neighbor, new_path))
    return None


REVERSE_DIR = {
    "north": "south", "south": "north",
    "east": "west", "west": "east",
    "up": "down", "down": "up",
    "northeast": "southwest", "southwest": "northeast",
    "northwest": "southeast", "southeast": "northwest",
    "enter": "out", "out": "enter",
}


def path_to_directions(graph, path):
    """将房间路径转为方向序列"""
    if not path or len(path) < 2:
        return []
    directions = []
    for i in range(len(path) - 1):
        current = path[i]
        next_room = path[i + 1]
        d = graph.get(current, {}).get("directed_edges", {}).get(next_room)
        if d:
            directions.append(d)
            continue
        reverse_d = graph.get(next_room, {}).get("directed_edges", {}).get(current)
        if reverse_d:
            inferred = REVERSE_DIR.get(reverse_d)
            if inferred:
                directions.append(inferred)
                continue
        exits = graph.get(current, {}).get("exits", [])
        if len(exits) == 1:
            directions.append(exits[0])
        else:
            directions.append(f"?→{next_room}")
    return directions


def cmd_path(start, end):
    graph = build_graph()
    path = bfs_path(graph, start, end)
    if path is None:
        print("NO_PATH")
        sys.exit(1)
    print(" → ".join(path))
    directions = path_to_directions(graph, path)
    if directions:
        print("方向: " + " → ".join(directions))


def cmd_dirs(start, end):
    graph = build_graph()
    path = bfs_path(graph, start, end)
    if path is None:
        return
    directions = path_to_directions(graph, path)
    for d in directions:
        if not d.startswith("?"):
            print(d)


def cmd_walk(start, end):
    graph = build_graph()
    path = bfs_path(graph, start, end)
    if path is None:
        print("#showme <118>[地图] 无法到达目标")
        return
    directions = path_to_directions(graph, path)
    print(f"#showme <158>[地图] 共 {len(directions)} 步")
    for d in directions:
        if d.startswith("?"):
            print(f"#showme <138>[地图] 未知方向: {d}")
        else:
            print(f"m_go {d}")


def cmd_npc(keyword):
    graph = build_graph()
    found = []
    for room_name, info in graph.items():
        for npc in info.get("npcs", []):
            if keyword in npc:
                found.append((room_name, npc))
    if not found:
        print(f"未找到匹配 '{keyword}' 的 NPC")
        return
    for room_name, npc in found:
        print(f"  {npc}  ←  {room_name}")


def cmd_unvisited():
    graph = build_graph()
    dead_ends = []
    for name, info in sorted(graph.items()):
        exit_count = len(info.get("exits", []))
        if exit_count <= 1:
            dead_ends.append((name, exit_count))
    if not dead_ends:
        print("所有房间都已有多个出口")
        return
    for name, count in dead_ends:
        print(f"  {name} ({count} 个出口)")


def cmd_list():
    graph = build_graph()
    if not graph:
        print("暂无地图数据")
        return
    for name in sorted(graph.keys()):
        info = graph[name]
        exits = ", ".join(info.get("exits", []))
        npc_count = len(info.get("npcs", []))
        line = f"  {name}"
        if exits:
            line += f"  [{exits}]"
        if npc_count:
            line += f"  NPC:{npc_count}"
        print(line)
    print(f"共 {len(graph)} 个房间")


def main():
    if len(sys.argv) < 2:
        print("用法: map_navigator.py <command> [args...]")
        print("  path <起点> <终点>  BFS 最短路径")
        print("  walk <起点> <终点>  逐步移动指令")
        print("  npc <关键词>        查找 NPC")
        print("  unvisited           未完全探索的房间")
        print("  list                列出所有房间")
        sys.exit(1)

    command = sys.argv[1]

    if command == "path":
        if len(sys.argv) < 4:
            print("用法: map_navigator.py path <起点> <终点>")
            sys.exit(1)
        cmd_path(sys.argv[2], sys.argv[3])

    elif command == "dirs":
        if len(sys.argv) < 4:
            print("用法: map_navigator.py dirs <起点> <终点>")
            sys.exit(1)
        cmd_dirs(sys.argv[2], sys.argv[3])

    elif command == "walk":
        if len(sys.argv) < 4:
            print("用法: map_navigator.py walk <起点> <终点>")
            sys.exit(1)
        cmd_walk(sys.argv[2], sys.argv[3])

    elif command == "npc":
        if len(sys.argv) < 3:
            print("用法: map_navigator.py npc <关键词>")
            sys.exit(1)
        cmd_npc(sys.argv[2])

    elif command == "unvisited":
        cmd_unvisited()

    elif command == "list":
        cmd_list()

    else:
        print(f"未知命令: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
