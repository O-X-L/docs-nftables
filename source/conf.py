from datetime import datetime

# pylint: disable=W0622

project = 'NFTables Docs'
copyright = ''
author = 'https://wiki.nftables.org/wiki-nftables/index.php/Special:Contributions'
extensions = ['sphinx_immaterial', 'myst_parser']
templates_path = ['_templates']
exclude_patterns = []
html_theme = 'sphinx_immaterial'
html_static_path = ['_static']
master_doc = 'index'
display_version = True
sticky_navigation = True
html_logo = '_static/img/icon.webp'
html_favicon = '_static/img/icon.webp'
source_suffix = {
    '.rst': 'restructuredtext',
}
html_theme_options = {
    "site_url": "https://nftables.docs.oxl.app",
    "repo_url": "https://git.netfilter.org/nftables/",
    "repo_name": "netfilter/nftables",
    "globaltoc_collapse": True,
    "features": [
        "navigation.expand",
        # "navigation.tabs",
        # "navigation.tabs.sticky",
        # "toc.integrate",
        "navigation.sections",
        # "navigation.instant",
        # "header.autohide",
        "navigation.top",
        "navigation.footer",
        # "navigation.tracking",
        # "search.highlight",
        "search.share",
        "search.suggest",
        "toc.follow",
        "toc.sticky",
        "content.tabs.link",
        "content.code.copy",
        "content.action.edit",
        "content.action.view",
        "content.tooltips",
        "announce.dismiss",
    ],
    "palette": [
        {
            "media": "(prefers-color-scheme: light)",
            "scheme": "default",
            "primary": "light-blue",
            "accent": "light-green",
            "toggle": {
                "icon": "material/lightbulb",
                "name": "Switch to dark-mode",
            },
        },
        {
            "media": "(prefers-color-scheme: dark)",
            "scheme": "slate",
            "primary": "deep-orange",
            "accent": "lime",
            "toggle": {
                "icon": "material/lightbulb-outline",
                "name": "Switch to light-mode",
            },
        },
    ],
    "version_dropdown": True,
    "version_info": [
        {
            "version": "https://www.netfilter.org/projects/nftables/index.html",
            "title": "NFTables Project",
            "aliases": [],
        },
        {
            "version": "https://git.kernel.org/cgit/linux/kernel/git/netfilter/nf-next.git",
            "title": "Repository linux-kernel",
            "aliases": [],
        },
        {
            "version": "https://git.netfilter.org/nftables/",
            "title": "Repository user-space utility",
            "aliases": [],
        },
    ],
    "social": [
        {
            "icon": "fontawesome/brands/github",
            "link": "https://github.com/O-X-L",
            "name": "OXL on GitHub",
        },
    ],
}
html_title = 'NFTables Docs'
html_short_title = 'Netfilter NFTables Documentation'
html_js_files = ['https://files.oxl.at/js/feedback.js']
html_css_files = ['css/main.css', 'https://files.oxl.at/css/feedback.css']