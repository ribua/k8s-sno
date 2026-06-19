#!/usr/bin/env python3
"""Enable libvirt boot menu on a domain XML dump."""

from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xml_path", help="Path to domain XML (from virsh dumpxml)")
    args = parser.parse_args()

    tree = ET.parse(args.xml_path)
    os_elem = tree.getroot().find("os")
    if os_elem is None:
        raise SystemExit("domain XML has no <os> element")

    bootmenu = os_elem.find("bootmenu")
    if bootmenu is None:
        bootmenu = ET.SubElement(os_elem, "bootmenu")
    bootmenu.set("enable", "yes")

    ET.indent(tree, space="  ")
    tree.write(args.xml_path, encoding="unicode", xml_declaration=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
