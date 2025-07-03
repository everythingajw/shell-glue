#!/usr/bin/env python3

import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="find differences in directory contents on one level by name")
    parser.add_argument("left", type=Path, help="left (reference) directory")
    parser.add_argument("right", type=Path, help="right (difference) directory, compared against contents of left")
    parser.add_argument("-c", "--show-common", required=False, type=bool, action=argparse.BooleanOptionalAction,
                        default=False, dest="show_common", help="show files that are in both directories")
    args = parser.parse_args()

    try:
        left_content = set(f.name for f in Path(args.left).iterdir())
        right_content = set(f.name for f in Path(args.right).iterdir())
    except OSError as e:
        print(str(e))
        return 1

    # Files only in left dir (missing from right dir)
    for file in sorted(left_content - right_content):
        print(f"< {file}")

    # Files only in right dir (missing from left dir)
    for file in sorted(right_content - left_content):
        print(f"> {file}")

    if args.show_common:
        for file in sorted(left_content & right_content):
            print(f"= {file}")

    return 0


if __name__ == '__main__':
    try:
        exit(main())
    except KeyboardInterrupt:
        exit(1)
