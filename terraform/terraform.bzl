toolchains = {
    "darwin_amd64": {
        "os": "darwin",
        "arch": "amd64",
        "exec_compatible_with": [
            "@platforms//os:osx",
            "@platforms//cpu:x86_64",
        ],
        "target_compatible_with": [
            "@platforms//os:osx",
            "@platforms//cpu:x86_64",
        ],
    },
    "linux_i386": {
        "os": "linux",
        "arch": "386",
        "exec_compatible_with": [
            "@platforms//os:linux",
            "@platforms//cpu:i386",
        ],
        "target_compatible_with": [
            "@platforms//os:linux",
            "@platforms//cpu:i386",
        ],
    },
    "linux_amd64": {
        "os": "linux",
        "arch": "amd64",
        "exec_compatible_with": [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        "target_compatible_with": [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    },
    "windows_amd64": {
        "os": "windows",
        "arch": "amd64",
        "exec_compatible_with": [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
        "target_compatible_with": [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    },
}

url_template = "https://releases.hashicorp.com/terraform/{version}/terraform_{version}_{os}_{arch}.zip"

TerraformInfo = provider(
    doc = "Information about how to invoke Terraform.",
    fields = ["sha", "url"],
)

def _terraform_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        barcinfo = TerraformInfo(
            sha256 = ctx.attr.sha256,
            url = ctx.attr.url,
        ),
    )
    return [toolchain_info]

terraform_toolchain = rule(
    implementation = _terraform_toolchain_impl,
    attrs = {
        "sha256": attr.string(),
        "url": attr.string(),
    },
)
def _format_url(version, os, arch):
    return url_template.format(version = version, os = os, arch = arch)


def declare_terraform_toolchains(version, sha256):
    for key, info in toolchains.items():
        url =_format_url(version, info["os"], info["arch"])
        name = "terraform_{}".format(key)
        toolchain_name = "{}_toolchain".format(name)

        terraform_toolchain(
            name = name,
            url = url,
            sha256 = sha256,
        )
        native.toolchain(
            name = toolchain_name,
            exec_compatible_with = info["exec_compatible_with"],
            target_compatible_with = info["target_compatible_with"],
            toolchain = name,
            toolchain_type = "@rules_terraform//:toolchain_type",
        )

def _detect_platform_arch(ctx):
    if ctx.os.name == "linux":
        platform = "linux"
        res = ctx.execute(["uname", "-m"])
        if res.return_code == 0:
            uname = res.stdout.strip()
            if uname not in ["x86_64", "i386"]:
                fail("Unable to determing processor architecture.")

            arch = "amd64" if uname == "x86_64" else "i386"
        else:
            fail("Unable to determing processor architecture.")
    elif ctx.os.name == "mac os x":
        platform, arch = "darwin", "amd64"
    elif ctx.os.name.startswith("windows"):
        platform, arch = "windows", "amd64"
    else:
        fail("Unsupported operating system: " + ctx.os.name)

    return platform, arch

def _terraform_build_file(ctx, platform, version):
    ctx.file("ROOT")
    ctx.template(
        "BUILD.bazel",
        Label("@rules_terraform//terraform:BUILD.terraform.bazel"),
        executable = False,
        substitutions = {
            "{name}": "terraform_executable",
            "{exe}": ".exe" if platform == "windows" else "",
            "{version}": version
        },
    )

def _remote_terraform(ctx, url, sha256):
    ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        type = "zip",
        output = "terraform"
    )

def _terraform_register_toolchains_impl(ctx):
    platform, arch = _detect_platform_arch(ctx)
    version = ctx.attr.version
    _terraform_build_file(ctx, platform, version)

    host = "{}_{}".format(platform, arch)
    info = toolchains[host]
    url = _format_url(version, info["os"], info["arch"])
    _remote_terraform(ctx, url, ctx.attr.sha256)

_terraform_register_toolchains = repository_rule(
    _terraform_register_toolchains_impl,
    attrs = {
        "version": attr.string(),
        "sha256": attr.string(),
    },
)

def terraform_register_toolchains(version, sha256):
    _terraform_register_toolchains(
        name = "register_terraform_toolchains",
        version = version,
        sha256 = sha256,
    )

def _terraform_plan(ctx):
    deps = depset(ctx.files.srcs)
    ctx.actions.run(
        executable = ctx.executable._exec,
        inputs = deps.to_list(),
        outputs = [ctx.outputs.out],
        mnemonic = "TerraformInitialize",
        arguments = [
            "plan",
            "-out={0}".format(ctx.outputs.out.path),
            deps.to_list()[0].dirname,
        ],
    )

terraform_plan = rule(
    implementation = _terraform_plan,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "_exec": attr.label(
            default = Label("@register_terraform_toolchains//:terraform_executable"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "%{name}.out"},
)

def _terraform_version(ctx):
    output = ctx.actions.declare_file("version.out")
    ctx.actions.run(
        executable = ctx.executable._exec,
        arguments = [
            "version",
        ],
        outputs = [output],
    )

terraform_version = rule(
        implementation = _terraform_version,
        attrs = {
            "_exec": attr.label(
                default = Label("@register_terraform_toolchains//:terraform_executable"),
                allow_files = True,
                executable = True,
                cfg = "host",
            ),
        },
 )
