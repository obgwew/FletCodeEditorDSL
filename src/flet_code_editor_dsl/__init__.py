import json
from typing import Any, Iterable, Optional

import flet as ft


def rule(
    form: str,
    color: str,
    before: Optional[str] = None,
    after: Optional[str] = None,
    ignore_if: Optional[str] = None,
) -> dict[str, Any]:
    return {
        "type": "rule",
        "forms": [form],
        "color": color,
        "before": before,
        "after": after,
        "ignore_if": ignore_if,
    }


def group(
    forms: list[str],
    color: str,
    before: Optional[str] = None,
    after: Optional[str] = None,
    ignore_if: Optional[str] = None,
) -> dict[str, Any]:
    return {
        "type": "group",
        "forms": list(forms),
        "color": color,
        "before": before,
        "after": after,
        "ignore_if": ignore_if,
    }


def pair(
    open: str,
    close: str,
    color: Optional[str] = None,
    unmatched_color: str = "#FF0000",
) -> dict[str, Any]:
    return {
        "open": open,
        "close": close,
        "color": color,
        "unmatched_color": unmatched_color,
    }


def rules_json(rules: Iterable[dict[str, Any]]) -> str:
    return json.dumps(list(rules), ensure_ascii=False, separators=(",", ":"))


def pairs_json(pairs: Iterable[dict[str, Any]]) -> str:
    return json.dumps(list(pairs), ensure_ascii=False, separators=(",", ":"))


@ft.control("flet_code_editor_dsl")
class CodeEditor(ft.LayoutControl):
    value: str = ""
    rules: str = "[]"
    pairs: str = "[]"
    default_color: str = "#000000"
    strict: bool = False
    error_color: str = "#FF0000"
    background_color: Optional[ft.ColorValue] = None
    font_family: str = "monospace"
    font_size: float = 14.0
    on_change: Optional[ft.ControlEventHandler] = None


__all__ = ["CodeEditor", "rule", "group", "pair", "rules_json", "pairs_json"]
