#!/usr/bin/env python3
"""Verify manifest, ZIP members, compiled CSS URLs, and target font trees."""

from __future__ import annotations

import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[2]
FONT_ROOT = ROOT / "resources" / "fonts"
MANIFEST_PATH = FONT_ROOT / "manifest.json"
TARGET_ROOT = ROOT / "src" / "latex-theme"
PLATFORMS = ("windows", "macos", "linux")
FONT_SUFFIXES = {".ttf", ".otf"}
FONT_SIGNATURES = {b"OTTO", b"\x00\x01\x00\x00", b"true", b"typ1"}
FACE_RE = re.compile(r"@font-face\s*\{(.*?)\}", re.DOTALL)
URL_RE = re.compile(r'url\(["\']?\./latex_fonts/([^"\')]+)')
LOCAL_RE = re.compile(r'local\(["\']([^"\']+)["\']\)')
FAMILY_RE = re.compile(r'font-family:\s*["\']([^"\']+)["\']\s*;')
WEIGHT_RE = re.compile(r"font-weight:\s*([^;]+)\s*;")
STYLE_RE = re.compile(r"font-style:\s*([^;]+)\s*;")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_font_output(value: str) -> bool:
    path = PurePosixPath(value)
    return (
        bool(value)
        and not path.is_absolute()
        and ".." not in path.parts
        and path.suffix.lower() in FONT_SUFFIXES
    )


def main() -> int:
    errors: list[str] = []
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"字体验证失败：无法读取 {MANIFEST_PATH}: {error}", file=sys.stderr)
        return 1

    if manifest.get("schemaVersion") != 3:
        errors.append("manifest schemaVersion 必须为 3")

    platform_faces: dict[
        str,
        dict[str, tuple[Path, str, set[str], set[tuple[str, str, str]]]],
    ] = {
        platform: {} for platform in PLATFORMS
    }
    all_active_outputs: set[str] = set()

    for package in manifest.get("packages", []):
        package_id = package.get("id", "<unknown>")
        archive = FONT_ROOT / package.get("archive", "")
        if not archive.is_file():
            errors.append(f"{package_id}: 缺少 ZIP {archive}")
            continue
        if sha256(archive) != package.get("sha256"):
            errors.append(f"{package_id}: ZIP SHA-256 不匹配")

        try:
            with zipfile.ZipFile(archive) as zipped:
                members = set(zipped.namelist())
                for face in package.get("faces", []):
                    member = face.get("member", "")
                    output = face.get("output", "")
                    detect = set(face.get("detect", []))
                    if member not in members:
                        errors.append(f"{package_id}: ZIP 缺少成员 {member}")
                        continue
                    if not safe_font_output(output):
                        errors.append(f"{package_id}: 不安全或非字体输出路径 {output}")
                        continue
                    if not detect:
                        errors.append(f"{package_id}: {output} 没有本机检测名称")
                    descriptors = {
                        (
                            str(face.get("family", "")),
                            str(face.get("weight", "")),
                            str(face.get("style", "")),
                        )
                    }
                    descriptors.update(
                        (
                            str(alias.get("family", "")),
                            str(alias.get("weight", "")),
                            str(alias.get("style", "")),
                        )
                        for alias in face.get("aliases", [])
                    )
                    if any(not all(descriptor) for descriptor in descriptors):
                        errors.append(f"{package_id}: {output} 的 family/weight/style 不完整")
                    data = zipped.read(member)
                    if len(data) < 4 or data[:4] not in FONT_SIGNATURES:
                        errors.append(f"{package_id}: {member} 不是有效的 TTF/OTF")
                    if output in all_active_outputs:
                        errors.append(f"重复字体输出路径：{output}")
                    all_active_outputs.add(output)
                    for platform in package.get("platforms", []):
                        if platform not in platform_faces:
                            errors.append(f"{package_id}: 未知平台 {platform}")
                            continue
                        platform_faces[platform][output] = (
                            archive,
                            member,
                            detect,
                            descriptors,
                        )
        except zipfile.BadZipFile:
            errors.append(f"{package_id}: 无效 ZIP {archive}")

    referenced_outputs: set[str] = set()
    for platform in PLATFORMS:
        package = TARGET_ROOT / f"{platform}-typora"
        target = package / "target"
        fonts = target / "latex_fonts"
        expected = platform_faces[platform]

        if not target.is_dir() or not fonts.is_dir():
            errors.append(f"{platform}: 请先构建 portable target")
            continue

        top_level = {path.name for path in target.iterdir()}
        expected_top_level = {"latex.css", "latex-dark.css", "latex_fonts"}
        if top_level != expected_top_level:
            errors.append(
                f"{platform}: target 顶层不正确，"
                f"缺少 {sorted(expected_top_level - top_level)}，"
                f"多出 {sorted(top_level - expected_top_level)}"
            )

        actual_files = {
            path.relative_to(fonts).as_posix(): path
            for path in fonts.rglob("*")
            if path.is_file()
        }
        if set(actual_files) != set(expected):
            errors.append(
                f"{platform}: latex_fonts 与 manifest 不一致，"
                f"缺少 {sorted(set(expected) - set(actual_files))}，"
                f"多出 {sorted(set(actual_files) - set(expected))}"
            )

        for output, path in actual_files.items():
            if path.suffix.lower() not in FONT_SUFFIXES:
                errors.append(f"{platform}: latex_fonts 包含非字体文件 {output}")
                continue
            if output not in expected:
                continue
            archive, member, _, _ = expected[output]
            with zipfile.ZipFile(archive) as zipped:
                if path.read_bytes() != zipped.read(member):
                    errors.append(f"{platform}: 提取内容与 ZIP 不一致 {output}")

        theme_urls: list[set[str]] = []
        for css_name in ("latex.css", "latex-dark.css"):
            css_path = target / css_name
            if not css_path.is_file():
                continue
            css = css_path.read_text(encoding="utf-8")
            urls = set(URL_RE.findall(css))
            theme_urls.append(urls)
            referenced_outputs.update(urls)
            if urls != set(expected):
                errors.append(
                    f"{platform}/{css_name}: CSS URL 与 manifest 不一致，"
                    f"缺少 {sorted(set(expected) - urls)}，"
                    f"多出 {sorted(urls - set(expected))}"
                )

            for block in FACE_RE.findall(css):
                matches = URL_RE.findall(block)
                if not matches:
                    continue
                output = matches[0]
                if output not in expected:
                    continue
                declared_locals = set(LOCAL_RE.findall(block))
                detect = expected[output][2]
                missing_detect = declared_locals - detect
                if missing_detect:
                    errors.append(
                        f"{platform}/{css_name}: {output} 的 local() 未写入 detect："
                        f"{sorted(missing_detect)}"
                    )

                family_match = FAMILY_RE.search(block)
                weight_match = WEIGHT_RE.search(block)
                style_match = STYLE_RE.search(block)
                if not family_match or not weight_match or not style_match:
                    errors.append(
                        f"{platform}/{css_name}: {output} 的 @font-face 描述不完整"
                    )
                    continue
                descriptor = (
                    family_match.group(1).strip(),
                    weight_match.group(1).strip(),
                    style_match.group(1).strip(),
                )
                if descriptor not in expected[output][3]:
                    errors.append(
                        f"{platform}/{css_name}: {output} 的 family/weight/style "
                        f"与 manifest 不一致：{descriptor}"
                    )

        if len(theme_urls) == 2 and theme_urls[0] != theme_urls[1]:
            errors.append(f"{platform}: 明暗主题字体 URL 不一致")

    unused_outputs = all_active_outputs - referenced_outputs
    if unused_outputs:
        errors.append(f"manifest 活动字体未被任何 CSS 引用：{sorted(unused_outputs)}")

    if errors:
        print("字体验证失败：", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    counts = ", ".join(
        f"{platform}={len(platform_faces[platform])}" for platform in PLATFORMS
    )
    print(f"字体验证通过：{counts}；CSS、manifest、ZIP 与 portable target 完全一致。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
