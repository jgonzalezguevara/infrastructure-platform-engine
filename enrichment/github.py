#!/usr/bin/env python3

import json
import urllib.error
import urllib.request
from urllib.parse import urlparse


USER_AGENT = "Infrastructure-Platform-Engine/0.1"


def github_repository_from_url(url):
    if not url:
        return None

    parsed = urlparse(url)

    if parsed.netloc.lower() not in (
        "github.com",
        "www.github.com",
    ):
        return None

    parts = [
        p for p in parsed.path.split("/")
        if p
    ]

    if len(parts) < 2:
        return None

    owner = parts[0]
    repository = parts[1]

    if repository.endswith(".git"):
        repository = repository[:-4]

    return f"{owner}/{repository}"


def github_api(path):
    request = urllib.request.Request(
        f"https://api.github.com{path}",
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/vnd.github+json",
        },
    )

    try:
        with urllib.request.urlopen(
            request,
            timeout=20
        ) as response:

            return json.loads(
                response.read().decode("utf-8")
            )

    except (
        urllib.error.HTTPError,
        urllib.error.URLError,
        TimeoutError,
        json.JSONDecodeError,
    ):
        return None


def inspect_repository(source_url):
    repository = github_repository_from_url(
        source_url
    )

    if not repository:
        return None

    repo = github_api(
        f"/repos/{repository}"
    )

    if not repo:
        return None

    latest_release = github_api(
        f"/repos/{repository}/releases/latest"
    )

    result = {
        "repository": repository,
        "official_source": source_url,

        "repository_metadata": {
            "name": repo.get("name"),
            "full_name": repo.get("full_name"),
            "description": repo.get("description"),
            "homepage": repo.get("homepage"),
            "archived": repo.get("archived"),
            "disabled": repo.get("disabled"),
            "updated_at": repo.get("updated_at"),
            "pushed_at": repo.get("pushed_at"),
            "default_branch": repo.get(
                "default_branch"
            ),
        },

        "latest_release": None,
    }

    if latest_release:
        result["latest_release"] = {
            "tag": latest_release.get(
                "tag_name"
            ),
            "name": latest_release.get(
                "name"
            ),
            "published_at": latest_release.get(
                "published_at"
            ),
            "prerelease": latest_release.get(
                "prerelease"
            ),
            "draft": latest_release.get(
                "draft"
            ),
            "url": latest_release.get(
                "html_url"
            ),
        }

    return result
