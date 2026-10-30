#!/usr/bin/env python3
"""从 assets/logo/mark_dark.svg 的路径数据采样粒子目标点。

输出 lib/ui/widgets/logo_points.dart（扁平 double 表，中心归一坐标）。
改 logo 后重跑：python tool/gen_logo_points.py
"""

import math
import re
from pathlib import Path

# 输出锚定在仓库根（脚本位于 tool/ 下），杜绝相对路径漂移。
OUT = Path(__file__).resolve().parent.parent / "lib" / "ui" / "widgets" / "logo_points.dart"

# mark_dark.svg 中 <g transform="translate(-110.5 -123)"> 内的两条 path（绝对坐标命令）。
PATHS = [
    "M197 974 L548 322 C557 305 568 296 590 296 H705 L874 631 C832 610 789 602 742 599 L665 409 L552 629 C477 659 414 700 359 755 C443 676 566 617 692 623 C768 619 840 637 891 664 L934 746 C851 697 767 685 688 690 C559 696 446 777 392 864 L354 943 C345 964 329 974 306 974 Z",
    "M755 701 C831 708 883 735 928 772 L1048 974 H899 C867 974 846 963 833 936 C813 887 780 781 755 701 Z",
]
TX, TY = -110.5, -123.0
VIEW = 1024.0
TOTAL_POINTS = 300
CUBIC_STEPS = 28

def tokenize(path):
    return re.findall(r"[MLHCZ]|-?\d+(?:\.\d+)?", path)

def flatten(path):
    """展平成折线点列（已应用 translate，未归一）。"""
    toks = tokenize(path)
    i, cmd, cur, start = 0, None, None, None
    pts = []

    def cubic(p0, p1, p2, p3):
        for s in range(1, CUBIC_STEPS + 1):
            t = s / CUBIC_STEPS
            u = 1 - t
            pts.append((
                u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
                u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1],
            ))

    while i < len(toks):
        t = toks[i]
        if t in "MLHCZ":
            cmd = t
            i += 1
            if cmd == "Z":
                if pts and start:
                    pts.append(start)
                continue
        if cmd == "M":
            x, y = float(toks[i]), float(toks[i + 1]); i += 2
            cur = (x, y); start = cur
            if not pts:
                pts.append(cur)
            cmd = "L"  # M 后隐式 L
        elif cmd == "L":
            x, y = float(toks[i]), float(toks[i + 1]); i += 2
            if cur is not None:
                if not pts or pts[-1] != cur:
                    pts.append(cur)
                pts.append((x, y))
            cur = (x, y)
        elif cmd == "H":
            x = float(toks[i]); i += 1
            if cur is not None:
                if not pts or pts[-1] != cur:
                    pts.append(cur)
                pts.append((x, cur[1]))
            cur = (x, cur[1])
        elif cmd == "C":
            vals = [float(v) for v in toks[i:i + 6]]; i += 6
            if cur is not None:
                if not pts or pts[-1] != cur:
                    pts.append(cur)
                cubic(cur, (vals[0], vals[1]), (vals[2], vals[3]), (vals[4], vals[5]))
            cur = (vals[4], vals[5])
    return pts

def arclength_sample(pts, n):
    segs = [math.dist(pts[k], pts[k + 1]) for k in range(len(pts) - 1)]
    total = sum(segs)
    out, acc, k = [], 0.0, 0
    for j in range(n):
        target = total * j / n
        while k < len(segs) - 1 and acc + segs[k] < target:
            acc += segs[k]; k += 1
        frac = (target - acc) / segs[k] if segs[k] > 0 else 0.0
        out.append((
            pts[k][0] + (pts[k + 1][0] - pts[k][0]) * frac,
            pts[k][1] + (pts[k + 1][1] - pts[k][1]) * frac,
        ))
    return out

def main():
    polys = [flatten(p) for p in PATHS]
    lens = [sum(math.dist(q[k], q[k + 1]) for k in range(len(q) - 1)) for q in polys]
    counts = [max(8, round(TOTAL_POINTS * L / sum(lens))) for L in lens]
    samples = []
    for poly, n in zip(polys, counts):
        samples.extend(arclength_sample(poly, n))
    # translate → 以 viewBox 中心 (512,512) 归一到 -0.5..0.5
    norm = [((x + TX - VIEW / 2) / VIEW, (y + TY - VIEW / 2) / VIEW) for x, y in samples]
    lines, line = [], []
    for x, y in norm:
        line += [round(x, 4), round(y, 4)]
        if len(line) == 8:
            lines.append(", ".join(f"{v:.4f}" for v in line)); line = []
    if line:
        lines.append(", ".join(f"{v:.4f}" for v in line))
    body = "\n".join(f"  {l}," for l in lines)
    dart = f"""// GENERATED FILE — 由 tool/gen_logo_points.py 从 assets/logo/mark_dark.svg
// 采样生成，勿手改。改 logo 后重跑生成脚本。
//
// {len(norm)} 个粒子目标点（扁平 x,y 序列），坐标以图形中心为原点、
// 以 1024 viewBox 归一（约 -0.42..0.42）。乘以目标边长即得屏幕坐标。
const List<double> kLogoParticlePoints = [
{body}
];
"""
    OUT.write_text(dart, encoding="utf-8", newline="\n")
    print(f"points: {len(norm)} (per path: {counts}) -> {OUT}")

if __name__ == "__main__":
    main()
