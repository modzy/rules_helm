"""
This BUILD file is auto-generated from toolchains/helm-3/BUILD.tpl
"""
package(default_visibility = ["//visibility:public"])

load("@com_github_modzy_rules_helm//toolchains/helm-3:toolchain.bzl", "helm_toolchain")

helm_toolchain(
    name = "helm_v3.6.2_darwin",
    tool = "@helm_v3.6.2_darwin//:helm",
    helm_version = "3.4.1",
    helm_xdg_data_home = "%{HOME}/Library",
    helm_xdg_config_home = "%{HOME}/Library/Preferences",
    helm_xdg_cache_home = "%{HOME}/Library/Caches",
    visibility = ["//visibility:public"],
)

helm_toolchain(
    name = "helm_v3.6.2_linux",
    tool = "@helm_v3.6.2_linux//:helm",
    helm_version = "3.4.1",
    helm_xdg_data_home = "%{HOME}/.local/share",
    helm_xdg_config_home = "%{HOME}/.config",
    helm_xdg_cache_home = "%{HOME}/.cache",
    visibility = ["//visibility:public"],
)
