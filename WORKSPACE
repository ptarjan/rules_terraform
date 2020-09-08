workspace(name = "rules_terraform")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "com_google_protobuf",
    strip_prefix = "protobuf-master",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/master.zip"],
    sha256 = "8ee08d6dde8151a0eb6d5c7916667ad2d60c630f25addae07eda646d336321ce",
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

http_archive(
    name = "com_github_bazelbuild_buildtools",
    strip_prefix = "buildtools-master",
    url = "https://github.com/bazelbuild/buildtools/archive/master.zip",
)

load("@rules_terraform//terraform:terraform.bzl", "terraform_register_toolchains")

terraform_register_toolchains("0.13.2")
